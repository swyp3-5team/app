//
//  Transaction.swift
//  Cloverly
//
//  Created by 이인호 on 1/2/26.
//

import Foundation

struct Transaction: nonisolated Codable, Equatable {
    let trGroupId: Int
    var transactionDate: String
    var totalAmount: Int
    var paymentMemo: String?
    var payment: Payment
    var emotion: Emotion
    var transactionInfoList: [TransactionInfo] // 내부 리스트

    var displayName: String {
        switch transactionInfoList.count {
        case 0: return "미입력"
        case 1: return transactionInfoList[0].name.nilIfNullOrEmpty ?? "미입력"
        default: return "\(transactionInfoList[0].name) 외 \(transactionInfoList.count - 1)건"
        }
    }
}

struct TransactionInfo: nonisolated Codable, Equatable {
    let transactionId: Int?
    var name: String
    var amount: Int
    var categoryId: Int
    var categoryName: String
    var type: String?
}
