//
//  Message.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit

enum MessageKind {
    case text(String)
    case photo(UIImage)
    case loading
}

enum ChatType: CaseIterable {
    case receive
    case send
}

struct Message {
    let id: UUID
    let kind: MessageKind
    let chatType: ChatType
    let date: Date

    init(id: UUID = UUID(), kind: MessageKind, chatType: ChatType, date: Date = Date()) {
        self.id = id
        self.kind = kind
        self.chatType = chatType
        self.date = date
    }
}
