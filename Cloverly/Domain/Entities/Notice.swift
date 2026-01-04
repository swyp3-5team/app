//
//  Notice.swift
//  Cloverly
//
//  Created by 이인호 on 1/4/26.
//

import Foundation

struct Notice: nonisolated Codable {
    let id: Int
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
}
