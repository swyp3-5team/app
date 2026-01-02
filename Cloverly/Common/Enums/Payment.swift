//
//  Payment.swift
//  Cloverly
//
//  Created by 이인호 on 1/2/26.
//

import Foundation

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
