//
//  IncomeCategory.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import Foundation
import UIKit

// MARK: - 2. 수입 카테고리 (Income)
enum IncomeCategory: Int, CaseIterable, Codable {
    case salary = 16          // 월급
    case sideIncome = 18      // 부수입
    case allowance = 19       // 용돈
    case other = 24           // 기타
    
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

    var fullDisplay: String {
        return "\(icon) \(name)"
    }

    var color: UIColor {
        UIColor(named: String(describing: self)) ?? .clear
    }

    static func from(id: Int) -> IncomeCategory {
        return IncomeCategory(rawValue: id) ?? .other
    }
}

