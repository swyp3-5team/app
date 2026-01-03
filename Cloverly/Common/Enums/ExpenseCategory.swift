//
//  ExpenseCategory.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import Foundation

// MARK: - 1. 지출 카테고리 (Expense)
enum ExpenseCategory: Int, CaseIterable, Codable {
    case food = 1           // 식비
    case cafe = 2           // 카페
    case delivery = 3       // 배달
    case alcohol = 4        // 술
    case transport = 5      // 교통
    case subscription = 6   // 구독
    case dailyNecessity = 7 // 생활용품
    case beauty = 8         // 미용
    case hobby = 9          // 취미
    case gathering = 10     // 모임
    case housing = 11       // 주거
    case health = 12        // 건강
    case selfDevelopment = 13 // 자기계발
    case pet = 14           // 반려동물
    case other = 15         // 기타
    
    // 디코딩 실패 시 안전하게 '기타'로 처리
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let id = try container.decode(Int.self)
        self = ExpenseCategory(rawValue: id) ?? .other
    }
    
    // 화면에 보여줄 이름
    var name: String {
        switch self {
        case .food: return "식비"
        case .cafe: return "카페"
        case .delivery: return "배달"
        case .alcohol: return "술"
        case .transport: return "교통"
        case .subscription: return "구독"
        case .dailyNecessity: return "생활용품"
        case .beauty: return "미용"
        case .hobby: return "취미"
        case .gathering: return "모임"
        case .housing: return "주거"
        case .health: return "건강"
        case .selfDevelopment: return "자기계발"
        case .pet: return "반려동물"
        case .other: return "기타"
        }
    }
    
    // 이미지에 맞는 이모지 매핑
    var icon: String {
        switch self {
        case .food: return "🍚"
        case .cafe: return "🍰"
        case .delivery: return "🛵"
        case .alcohol: return "🍷"
        case .transport: return "🚌"
        case .subscription: return "📱"
        case .dailyNecessity: return "🧹"
        case .beauty: return "💄"
        case .hobby: return "🧶"
        case .gathering: return "🥂"
        case .housing: return "🏠"
        case .health: return "💪"
        case .selfDevelopment: return "📚"
        case .pet: return "🐶"
        case .other: return "💭"
        }
    }
}
