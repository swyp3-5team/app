//
//  Double+Extension.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import Foundation

extension Double {
    var withComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
