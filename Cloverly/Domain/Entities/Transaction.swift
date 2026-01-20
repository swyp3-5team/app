//
//  Transaction.swift
//  Cloverly
//
//  Created by 이인호 on 1/2/26.
//

import Foundation

struct Transaction: nonisolated Codable {
    let trGroupId: Int
    var transactionDate: String
    var totalAmount: Int
    var place: String?
    var paymentMemo: String?
    var payment: Payment
    var emotion: Emotion
    var transactionInfoList: [TransactionInfo] // 내부 리스트
}

struct TransactionInfo: nonisolated Codable {
    let transactionId: Int?
    var name: String
    var amount: Int
    var categoryId: Int
    var categoryName: String
    var type: String?
}
