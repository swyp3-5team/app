//
//  MyViewModel.swift
//  Cloverly
//
//  Created by 이인호 on 12/31/25.
//

import Foundation
import RxSwift
import RxCocoa

final class MyViewModel {
    let selectedIndex = BehaviorRelay<Int>(value: 0)
}
