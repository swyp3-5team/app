//
//  TransactionRequest.swift
//  Cloverly
//
//  Created by 이인호 on 12/29/25.
//

import Foundation

struct TransactionRequest: nonisolated Codable {
    let transactionDate: String
    // 수입은 결제수단/감정이 없어 null로 전송될 수 있다.
    let payment: Payment?
    let paymentMemo: String?
    let emotion: Emotion?
    let transactions: [TransactionDTO]
}
