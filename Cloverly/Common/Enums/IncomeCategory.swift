//
//  IncomeCategory.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import Foundation

// MARK: - 2. 수입 카테고리 (Income)
enum IncomeCategory: Int, CaseIterable, Codable {
    case salary = 16          // 월급
    case sideIncome = 18      // 부수입
    case allowance = 19       // 용돈
    case other = 23           // 기타
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let id = try container.decode(Int.self)
        self = IncomeCategory(rawValue: id) ?? .other
    }
    
    var name: String {
        switch self {
        case .salary: return "월급"
        case .sideIncome: return "부수입"
        case .allowance: return "용돈"
        case .other: return "기타"
        }
    }
    
    var icon: String {
        switch self {
        case .salary: return "💸"
        case .sideIncome: return "✨"
        case .allowance: return "💰"
        case .other: return "💭"
        }
    }
}

