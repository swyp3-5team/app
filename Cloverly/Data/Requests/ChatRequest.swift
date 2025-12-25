//
//  ChatRequest.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import Foundation

enum ChatMode: String, Encodable {
    case receipt = "RECEIPT"
    case chat = "CHAT"
    
    init(index: Int) {
        self = (index == 0) ? .receipt : .chat
    }
}

struct ChatRequest: nonisolated Encodable{
    let message: String?
    let mode: String
}
