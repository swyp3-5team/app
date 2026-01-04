//
//  ChatResponse.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import Foundation

struct TransactionInfoDTO: nonisolated Codable {
    let place: String?
    let transactionDate: String
    let payment: Payment
    let paymentMemo: String?
    let totalAmount: Int
    let emotion: Emotion
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
}
