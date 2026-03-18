//
//  Typography.swift
//  Cloverly
//
//  Created by 이인호 on 3/18/26.
//

import UIKit

enum Typography {

    // MARK: - Headline
    case h1, h2, h3
    
    // MARK: - Title
    case t1

    // MARK: - Body
    case b1, b2, b3, b4, b5, b6, b7, b8

    // MARK: - Label
    case l1, l2, l3

    // MARK: - Font
    var uiFont: UIFont {
        switch self {
        case .h1: return .customFont(.pretendardSemiBold, size: 24)
        case .h2: return .customFont(.pretendardSemiBold, size: 22)
        case .h3: return .customFont(.pretendardMedium, size: 22)
            
        case .t1: return .customFont(.pretendardSemiBold, size: 18)

        case .b1: return .customFont(.pretendardSemiBold, size: 16)
        case .b2: return .customFont(.pretendardMedium, size: 16)
        case .b3: return .customFont(.pretendardRegular, size: 16)
        case .b4: return .customFont(.pretendardRegular, size: 15)
        case .b5: return .customFont(.pretendardSemiBold, size: 14)
        case .b6: return .customFont(.pretendardMedium, size: 14)
        case .b7: return .customFont(.pretendardRegular, size: 14)
        case .b8: return .customFont(.pretendardMedium, size: 13)

        case .l1: return .customFont(.pretendardRegular, size: 13)
        case .l2: return .customFont(.pretendardSemiBold, size: 12)
        case .l3: return .customFont(.pretendardRegular, size: 12)
        }
    }

    // MARK: - Line Spacing
    var lineSpacing: CGFloat {
        switch self {
        case .h1: return 9.6
        case .h2, .h3: return 8.8
        case .t1: return 7.2
        case .b1, .b2, .b3: return 6.4
        case .b4: return 6.0
        case .b5, .b6, .b7: return 5.6
        case .b8, .l1: return 5.2
        case .l2, .l3: return 4.8
        }
    }

    // MARK: - Letter Spacing
    var letterSpacing: CGFloat {
        switch self {
        default:
            return 0
        }
    }

    // MARK: - AttributedString
    func attributedString(_ text: String, color: UIColor = .label) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing

        return NSAttributedString(string: text, attributes: [
            .font: uiFont,
            .kern: letterSpacing,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ])
    }
}

// MARK: - UIButton+Typography

extension UIButton {
    func setTypography(_ style: Typography, title: String, color: UIColor, for state: UIControl.State = .normal) {
        setAttributedTitle(style.attributedString(title, color: color), for: state)
    }
}

// MARK: - AppLabel

class AppLabel: UILabel {
    var typography: Typography? {
        didSet { applyTypography() }
    }

    override var text: String? {
        didSet { applyTypography() }
    }

    override var textColor: UIColor! {
        didSet { applyTypography() }
    }

    private func applyTypography() {
        guard let style = typography else { return }
        attributedText = style.attributedString(text ?? "", color: textColor)
    }
}

// MARK: - AppTextView

class AppTextView: UITextView {
    var typography: Typography? {
        didSet { applyTypography() }
    }

    override var text: String! {
        didSet { applyTypography() }
    }

    override var textColor: UIColor? {
        didSet { applyTypography() }
    }

    private func applyTypography() {
        guard let style = typography else { return }
        attributedText = style.attributedString(text ?? "", color: textColor ?? .label)
    }
}
