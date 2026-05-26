//
//  TransactionRecord.swift
//  Cloverly
//
//  Created by 이인호 on 3/18/26.
//

import Foundation

struct TransactionRecord: nonisolated Codable {
    let name: String
    let amount: Int
    let date: String
    let emotion: Emotion
    let payment: Payment
    
}
