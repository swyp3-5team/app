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
        }
    }
    
    func saveTransaction() async throws {
        guard let info = chatResponse.value?.transactionInfo else {
            throw NSError(domain: "DataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "저장할 데이터가 없습니다."])
        }
        
        // 2. RequestBody 생성 (VM이 담당)
        let requestBody = TransactionRequest(
            place: info.place,
            transactionDate: info.transactionDate,
            payment: info.payment,
            paymentMemo: info.paymentMemo,
            emotion: info.emotion,
            type: info.type,
            transactions: info.transactions.map { item in
                Transaction(
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
        
//        Task {
//            do {
//                try await api.saveTransaction(requestBody: requestBody)
//            } catch {
//                print("거래내역 저장 실패: \(error.localizedDescription)")
//            }
//        }
    }
}
