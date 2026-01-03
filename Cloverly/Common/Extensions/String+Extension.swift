//
//  String+Extension.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit

extension String {
    func getEstimatedFrame(with font: UIFont) -> CGRect {
        let size = CGSize(width: UIScreen.main.bounds.width * 2/3, height: 1000)
        let optionss = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let estimatedFrame = NSString(string: self).boundingRect(with: size, options: optionss, attributes: [.font: font], context: nil)
        return estimatedFrame
    }
    
    var toDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 포맷 확인 필수
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.date(from: self)
    }
}
