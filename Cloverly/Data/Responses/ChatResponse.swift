//
//  ChatResponse.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import Foundation

enum Emotion: String, Codable {
    case neutral = "NEUTRAL"
    case stress_releaf = "STRESS_RELIEF"
    case reward = "REWARD"
    case impulse = "IMPULSE"
    case regret = "REGRET"
    case satisfaction = "SATISFACTION"
    
    var displayName: String {
        switch self {
        case .neutral:
            "일상"
        case .stress_releaf:
            "스트레스 해소"
        case .reward:
            "보상 심리"
        case .impulse:
            "충동 구매"
        case .regret:
            "후회"
        case .satisfaction:
            "만족"
        }
    }
}

enum Payment: String, Codable {
    case card = "CARD"
    case cash = "CASH"
    
    var displayName: String {
        switch self {
        case .card:
            "카드"
        case .cash:
            "현금"
        }
    }
}

struct TransactionInfo: nonisolated Codable {
    let place: String?
    let transactionDate: String
    let payment: Payment
    let paymentMemo: String?
    let totalAmount: Int
    let emotion: Emotion
    let type: String
    let transactions: [Transaction]
}

struct Transaction: nonisolated Codable {
    let name: String
    let amount: Int
    let categoryName: String
}

struct ChatResponse: nonisolated Codable {
    let message: String
    let transactionInfo: TransactionInfo
}
