//
//  ChatViewModel.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import Foundation
import RxSwift
import RxCocoa

final class ChatViewModel {
    let messages = BehaviorRelay<[Message]>(value: Mock.getMockMessages())
}
