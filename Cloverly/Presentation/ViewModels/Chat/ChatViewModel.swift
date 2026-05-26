//
//  ChatViewModel.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAnalytics

struct MessageSection {
    let dateString: String
    let messages: [Message]
}

final class ChatViewModel {
    let ledgerMessages = BehaviorRelay<[Message]>(value: [])
    let chatMessages = BehaviorRelay<[Message]>(value: [])
    let historyMessages = BehaviorRelay<[Message]>(value: [])

    var currentSections: [MessageSection] {
        let mode = ChatMode(index: selectedIndex.value)
        let messages = mode == .receipt ? ledgerMessages.value : historyMessages.value + chatMessages.value
        return groupByDate(messages)
    }

    var currentSectionsStream: Observable<[MessageSection]> {
        return Observable.combineLatest(selectedIndex, ledgerMessages, chatMessages, historyMessages)
            .map { [weak self] index, ledger, chat, history -> [MessageSection] in
                guard let self = self else { return [] }
                let mode = ChatMode(index: index)
                let messages = mode == .receipt ? ledger : history + chat
                return self.groupByDate(messages)
            }
    }

    private func groupByDate(_ messages: [Message]) -> [MessageSection] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")

        var groups: [(Date, [Message])] = []
        for message in messages {
            if let idx = groups.firstIndex(where: { calendar.isDate($0.0, inSameDayAs: message.date) }) {
                groups[idx].1.append(message)
            } else {
                groups.append((calendar.startOfDay(for: message.date), [message]))
            }
        }
        return groups.map { MessageSection(dateString: formatter.string(from: $0.0), messages: $0.1) }
    }
    
    let isSheetPresent = BehaviorRelay<Bool>(value: false)
    let selectedIndex = BehaviorRelay<Int>(value: 0)
    let api = ChatAPI()
    var chatResponse = BehaviorRelay<ChatResponse?>(value: nil)
    let isLoading = BehaviorRelay<Bool>(value: false)
    
    func sendChat(message: String? = nil, image: UIImage? = nil) {
        let mode = ChatMode(index: selectedIndex.value)
        
        if let msg = message {
            let textMessage = Message(kind: .text(msg), chatType: .send)
            appendMessage(textMessage, mode: mode)
        }
        
        if let img = image {
            let photoMessage = Message(kind: .photo(img), chatType: .send)
            appendMessage(photoMessage, mode: mode)
        }
        
        Task {
            if mode == .receipt {
                isLoading.accept(true)
                
                defer {
                    isLoading.accept(false)
                }
                
                do {
                    let response = try await api.sendChat(message: message, mode: mode, image: image)
                    self.chatResponse.accept(response)
                    self.isSheetPresent.accept(true)
                } catch {
                    print("채팅 전송 실패: \(error.localizedDescription)")
                }
            } else {
                do {
                    let response = try await api.sendChat(message: message, mode: mode, image: image)
                    
                    let message = Message(kind: .text("\(response.message)"), chatType: .receive)
                    var currentMessages = chatMessages.value
                    currentMessages.append(message)
                    chatMessages.accept(currentMessages)
                    
                } catch {
                    print("채팅 전송 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func appendMessage(_ message: Message, mode: ChatMode) {
        if mode == .receipt {
            var list = ledgerMessages.value
            list.append(message)
            ledgerMessages.accept(list)
        } else {
            var list = chatMessages.value
            list.append(message)
            chatMessages.accept(list)
        }
    }
    
    func saveTransaction() async throws {
        guard let info = chatResponse.value?.transactionInfo else {
            throw NSError(domain: "DataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "저장할 데이터가 없습니다."])
        }
        
        let requestBody = TransactionRequest(
            place: info.place,
            transactionDate: info.transactionDate,
            payment: info.payment,
            paymentMemo: info.paymentMemo,
            emotion: info.emotion,
            transactions: info.transactions.map { item in
                TransactionDTO(
                    name: item.name,
                    amount: item.amount,
                    categoryName: item.categoryName
                )
            }
        )
        
        try await api.saveTransaction(requestBody: requestBody)
        
        Analytics.logEvent("transaction_saved", parameters: [
            "source": "chat"
        ])
        
        let message = Message(kind: .text("\(chatResponse.value?.message ?? "저장 완료")"), chatType: .receive)
        var currentMessages = ledgerMessages.value
        currentMessages.append(message)
        ledgerMessages.accept(currentMessages)
    }
    
    func getChatHistory(size: Int) async throws {
        let history = try await api.getChatHistory(page: 0, size: size)
        let filtered = history.filter { !($0.chatContent.contains("결제함") && $0.chatContent.contains("소비")) }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"

        var messages = filtered.map { item -> Message in
            let chatType: ChatType = item.chatType == .assistant ? .receive : .send
            let date = dateFormatter.date(from: item.createdAt) ?? Date()
            return Message(kind: .text(item.chatContent), chatType: chatType, date: date)
        }
        
        messages = messages.sorted { $0.date < $1.date }
        
        historyMessages.accept(messages)
    }
}
