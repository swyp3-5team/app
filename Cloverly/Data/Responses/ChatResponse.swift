//
//  ChatResponse.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import Foundation

struct TransactionInfo: nonisolated Decodable {
    let transactionId: Int
    let name: String
    let amount: Int
    let categoryId: Int
    let categoryName: String
}

struct ChatResponse: nonisolated Decodable {
    let message: String
    let transactionInfo: TransactionInfo
}
