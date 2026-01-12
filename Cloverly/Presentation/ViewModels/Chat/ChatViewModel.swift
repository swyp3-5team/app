//
//  ChatViewModel.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import RxSwift
import RxCocoa

final class ChatViewModel {
    let ledgerMessages = BehaviorRelay<[Message]>(value: [])
    let chatMessages = BehaviorRelay<[Message]>(value: [])
    
    var currentMessages: [Message] {
        let mode = ChatMode(index: selectedIndex.value)
        switch mode {
        case .receipt:
            return ledgerMessages.value
        default:
            return chatMessages.value
        }
    }
    
    // View가 구독할 통합 스트림
    var currentMessagesStream: Observable<[Message]> {
        return Observable.combineLatest(
            selectedIndex,       // 1. 모드가 바뀌거나
            ledgerMessages,      // 2. 영수증 메시지가 바뀌거나
            chatMessages         // 3. 채팅 메시지가 바뀔 때마다 실행
        )
        .map { index, ledger, chat -> [Message] in
            // 현재 모드에 맞는 배열만 골라서 내보냄
            let mode = ChatMode(index: index)
            return mode == .receipt ? ledger : chat
        }
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
        
        let message = Message(kind: .text("\(chatResponse.value?.message ?? "저장 완료")"), chatType: .receive)
        var currentMessages = ledgerMessages.value
        currentMessages.append(message)
        ledgerMessages.accept(currentMessages)
    }
}
