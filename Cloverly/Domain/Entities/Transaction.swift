//
//  Transaction.swift
//  Cloverly
//
//  Created by 이인호 on 1/2/26.
//

import Foundation

struct Transaction: nonisolated Decodable {
    let trGroupId: Int
    let transactionDate: String
    let totalAmount: Int
    let place: String
    let paymentMemo: String?
    let payment: Payment
    let emotion: Emotion
    let transactionInfoList: [TransactionInfo] // 내부 리스트
}

struct TransactionInfo: nonisolated Decodable {
    let transactionId: Int
    let name: String
    let amount: Int
    let categoryId: Int
    let categoryName: String
}
