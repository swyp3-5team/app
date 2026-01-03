//
//  Date+Extension.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import Foundation

extension Date {
    // 서버 전송용 포맷 (yyyy-MM-dd)
    var toServerFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 포맷만 서버랑 맞추세요
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
}
