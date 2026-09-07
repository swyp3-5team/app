//
//  Payment.swift
//  Cloverly
//
//  Created by 이인호 on 1/2/26.
//

import Foundation

enum Payment: String, Codable, CaseIterable {
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

    // 서버가 UNKNOWN 등 예기치 못한 값을 주면 디코딩을 실패시키지 않고 card로 폴백한다.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Payment(rawValue: raw) ?? .card
    }
}
