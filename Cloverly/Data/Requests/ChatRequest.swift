//
//  ChatRequest.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import Foundation

struct ChatRequest: nonisolated Codable{
    let message: String?
    let mode: String
}
