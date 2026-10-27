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

    // MARK: - Onboarding (온보딩 타이틀 전용: Pretendard Bold 26, 행간 140%, 자간 0%)
    case onboardingTitle

    // MARK: - Title
    case t1

    // MARK: - Body
    case b1, b2, b3, b4, b5, b6, b7, b8, b9

    // MARK: - Label
    case l1, l2, l3

    // MARK: - Font
    var uiFont: UIFont {
        switch self {
        case .h1: return .customFont(.pretendardSemiBold, size: 24)
        case .h2: return .customFont(.pretendardSemiBold, size: 22)
        case .h3: return .customFont(.pretendardMedium, size: 22)

        case .onboardingTitle: return .customFont(.pretendardBold, size: 26)

        case .t1: return .customFont(.pretendardSemiBold, size: 18)

        case .b1: return .customFont(.pretendardSemiBold, size: 16)
        case .b2: return .customFont(.pretendardMedium, size: 16)
        case .b3: return .customFont(.pretendardRegular, size: 16)
        case .b4: return .customFont(.pretendardSemiBold, size: 15)
        case .b5: return .customFont(.pretendardMedium, size: 15)
        case .b6: return .customFont(.pretendardSemiBold, size: 14)
        case .b7: return .customFont(.pretendardMedium, size: 14)
        case .b8: return .customFont(.pretendardRegular, size: 14)
        case .b9: return .customFont(.pretendardMedium, size: 13)

        case .l1: return .customFont(.pretendardRegular, size: 13)
        case .l2: return .customFont(.pretendardSemiBold, size: 12)
        case .l3: return .customFont(.pretendardRegular, size: 12)
        }
    }

    // MARK: - Line Height
    // 디자인 스펙: 전 스타일 행간 140% (= 폰트 크기 × 1.4).
    // (기존엔 lineSpacing에 폰트크기×0.4를 넣었는데, lineSpacing은 폰트의 자연 행높이 "위에 더"
    //  얹는 값이라 실제로는 ~160%로 렌더링됐다. 아래 attributedString에서 min/maxLineHeight로 고정한다.)
    var lineHeightMultiple: CGFloat { 1.4 }

    // MARK: - Letter Spacing
    var letterSpacing: CGFloat {
        switch self {
        default:
            return 0
        }
    }

    // MARK: - AttributedString
    func attributedString(_ text: String, color: UIColor = .label) -> NSAttributedString {
        let font = uiFont
        // 140%를 lineSpacing(가산)이 아니라 행높이 자체로 고정 → 폰트 자연 행높이와 무관하게 정확히 140%
        let lineHeight = font.pointSize * lineHeightMultiple

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        return NSAttributedString(string: text, attributes: [
            .font: font,
            .kern: letterSpacing,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
            // min/maxLineHeight는 글리프를 라인 박스 하단에 붙이므로, 남는 여백만큼 올려 수직 중앙 정렬
            .baselineOffset: (lineHeight - font.lineHeight) / 4
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
        let alignment = textAlignment
        attributedText = style.attributedString(text ?? "", color: textColor)
        textAlignment = alignment
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
