//
//  TransactionRequest.swift
//  Cloverly
//
//  Created by 이인호 on 12/29/25.
//

import Foundation

struct TransactionRequest: nonisolated Codable {
    let place: String?
    let transactionDate: String
    let payment: Payment
    let paymentMemo: String?
    let emotion: Emotion
    let transactions: [TransactionDTO]
}
