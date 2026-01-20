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
    let noticeAPI = NoticeAPI()
    let selectedIndex = BehaviorRelay<Int>(value: 0)
    let notices = BehaviorRelay<[Notice]>(value: [])
    
    func getNotices() {
        Task {
            do {
                let response = try await noticeAPI.getNoticies()
                notices.accept(response.notices)
            } catch {
                print("공지사항 조회 에러: \(error.localizedDescription)")
            }
        }
    }
}
