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
}

enum ChatType: CaseIterable {
    case receive
    case send
}

struct Message {
    let kind: MessageKind
    let chatType: ChatType
    let date: Date

    init(kind: MessageKind, chatType: ChatType, date: Date = Date()) {
        self.kind = kind
        self.chatType = chatType
        self.date = date
    }
}
