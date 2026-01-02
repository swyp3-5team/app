//
//  ChatMode.swift
//  Cloverly
//
//  Created by 이인호 on 1/2/26.
//

import Foundation

enum ChatMode: String, Encodable {
    case receipt = "RECEIPT"
    case chat = "CHAT"
    
    init(index: Int) {
        self = (index == 0) ? .receipt : .chat
    }
}
