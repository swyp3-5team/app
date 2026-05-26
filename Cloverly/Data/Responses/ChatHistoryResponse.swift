//
//  ChatHistoryResponse.swift
//  Cloverly
//
//  Created by 이인호 on 4/24/26.
//

import Foundation

enum ChatHistoryType: String, Codable, CaseIterable {
    case assistant = "ASSISTANT"
    case user = "USER"
}

struct ChatHistoryResponse: nonisolated Codable {
    let chattingId: Int
    let chatType: ChatHistoryType
    let chatContent: String
    let emotion: Emotion?
    let createdAt: String
}
