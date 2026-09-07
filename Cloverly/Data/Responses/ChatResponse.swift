//
//  ChatResponse.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import Foundation

struct TransactionInfoDTO: nonisolated Codable {
    let transactionDate: String
    // 수입으로 인식되면 결제수단/감정이 null로 내려온다 (서버가 값을 안 채움).
    let payment: Payment?
    let paymentMemo: String?
    let totalAmount: Int
    let emotion: Emotion?
    let transactions: [TransactionDTO]
}

struct TransactionDTO: nonisolated Codable {
    let name: String
    let amount: Int
    let categoryName: String
}

struct ChatResponse: nonisolated Codable {
    let message: String
    let transactionInfo: TransactionInfoDTO?
    // 서버가 send 시점에 임시(pending) 저장하고 내려주는 식별자. 저장 확정 시 이 값을 실어 보낸다.
    let pendingId: String?
}
