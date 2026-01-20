//
//  UIFont+Extension.swift
//  Cloverly
//
//  Created by 이인호 on 12/18/25.
//

import UIKit

enum CustomFont {
    case pretendardBlack
    case pretendardBold
    case pretendardExtraBold
    case pretendardExtraLight
    case pretendardLight
    case pretendardMedium
    case pretendardRegular
    case pretendardSemiBold
    case pretendardThin
    
    var fontName: String {
        switch self {
        case .pretendardBlack:      return "Pretendard-Black"
        case .pretendardBold:       return "Pretendard-Bold"
        case .pretendardExtraBold:  return "Pretendard-ExtraBold"
        case .pretendardExtraLight: return "Pretendard-ExtraLight"
        case .pretendardLight:      return "Pretendard-Light"
        case .pretendardMedium:     return "Pretendard-Medium"
        case .pretendardRegular:    return "Pretendard-Regular"
        case .pretendardSemiBold:   return "Pretendard-SemiBold"
        case .pretendardThin:       return "Pretendard-Thin"
        }
    }
}

extension UIFont {
    static func customFont(_ font: CustomFont, size: CGFloat) -> UIFont {
        guard let font = UIFont(name: font.fontName, size: size) else {
            return .systemFont(ofSize: size)
        }
        return font
    }
}
