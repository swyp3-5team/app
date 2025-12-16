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
}

class Mock {
    static func getMockMessages() -> [Message] {
        let messages = ["Mr. and Mrs. Dursley, of number four, Privet Drive, were proud to say",
                        "that they were perfectly normal, thank you very much. They were the last",
                        "people you'd expect to be involved in anything strange or mysterious",
                        "because they just didn't hold with such nonsense.",
        "Mr. Dursley was the director of a firm called Grunnings",
                        "Mr. and Mrs. Dursley, of number four, Privet Drive, were proud to say",
                                        "that they were perfectly normal, thank you very much. They were the last",
                                        "people you'd expect to be involved in anything strange or mysterious",
                                        "because they just didn't hold with such nonsense.",
                        "Mr. Dursley was the director of a firm called Grunnings",
                        "Mr. and Mrs. Dursley, of number four, Privet Drive, were proud to say",
                                        "that they were perfectly normal, thank you very much. They were the last",
                                        "people you'd expect to be involved in anything strange or mysterious",
                                        "because they just didn't hold with such nonsense.",
                        "Mr. Dursley was the director of a firm called Grunnings"]
        return messages.map { Message(kind: .text($0), chatType: ChatType.allCases.randomElement()!) }
    }
}
