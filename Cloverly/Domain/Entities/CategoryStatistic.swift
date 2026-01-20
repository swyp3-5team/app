//
//  CategoryStatistic.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import Foundation

struct CategoryStatistic: nonisolated Codable {
    let categoryId: Int
    let categoryName: String
    let totalAmount: Double
}
