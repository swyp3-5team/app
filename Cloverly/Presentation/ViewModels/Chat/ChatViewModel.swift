//
//  ChatViewModel.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import RxSwift
import RxCocoa

final class ChatViewModel {
    let messages = BehaviorRelay<[Message]>(value: [])
    let isSheetPresent = BehaviorRelay<Bool>(value: false)
    let selectedIndex = BehaviorRelay<Int>(value: 0)
    let api = ChatAPI()
    
    func sendChat(message: String? = nil, image: UIImage? = nil) {
        Task {
            do {
                let mode = ChatMode(index: selectedIndex.value)
                let response = try await api.sendChat(message: message, mode: mode, image: image)
                
                print(response)
            } catch {
                print("채팅 전송 실패: \(error.localizedDescription)")
            }
        }
    }
}
