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
    let messages = BehaviorRelay<[Message]>(value: [])
    let isSheetPresent = BehaviorRelay<Bool>(value: false)
    let selectedIndex = BehaviorRelay<Int>(value: 0)
    let api = ChatAPI()
    var chatResponse = BehaviorRelay<ChatResponse?>(value: nil)
    let isLoading = BehaviorRelay<Bool>(value: false)
    
    func sendChat(message: String? = nil, image: UIImage? = nil) {
        Task {
            let mode = ChatMode(index: selectedIndex.value)
            
            if mode == .receipt {
                isLoading.accept(true)
                
                defer {
                    isLoading.accept(false)
                }
                
                do {
                    let mode = ChatMode(index: selectedIndex.value)
                    let response = try await api.sendChat(message: message, mode: mode, image: image)
                    self.chatResponse.accept(response)
                    self.isSheetPresent.accept(true)
                    print(response)
                } catch {
                    print("채팅 전송 실패: \(error.localizedDescription)")
                }
            } else {
                do {
                    let mode = ChatMode(index: selectedIndex.value)
                    let response = try await api.sendChat(message: message, mode: mode, image: image)
                    
                    let message = Message(kind: .text("\(response.message)"), chatType: .receive)
                    var currentMessages = messages.value
                    currentMessages.append(message)
                    messages.accept(currentMessages)
                    
                    print(response)
                } catch {
                    print("채팅 전송 실패: \(error.localizedDescription)")
                }
            }
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
        var currentMessages = messages.value
        currentMessages.append(message)
        messages.accept(currentMessages)
    }
}
