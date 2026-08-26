//
//  ChatGuideView.swift
//  Cloverly
//
//  채팅(가계부 입력) 화면 우상단 ? 버튼을 누르면 뜨는 가이드 카드.
//  X 버튼으로 닫는다. 세부 패딩/위치는 사용 측(ChatViewController)에서 조정.
//

import UIKit
import SnapKit

final class ChatGuideView: UIView {
    var onClose: (() -> Void)?

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.borderColor = UIColor.gray8.cgColor
        v.layer.borderWidth = 1
        return v
    }()

    private lazy var closeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "xmark")
        config.baseForegroundColor = .gray5
        let button = UIButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in
            self?.onClose?()
        }, for: .touchUpInside)
        return button
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.alignment = .fill
        sv.spacing = 8
        return sv
    }()

    private let exampleLabel: UILabel = {
        let label = UILabel()
        label.text = "ex) 오늘 백화점에서 옷 사는데\n5만 원 썼어 충동구매해버렸네 ㅠ_ㅠ"
        label.textColor = .gray5
        label.font = Typography.b8.uiFont
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private lazy var exampleBox: UIView = {
        let v = UIView()
        v.backgroundColor = .gray9
        v.layer.cornerRadius = 12
        v.addSubview(exampleLabel)
        exampleLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(8)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        addSubview(cardView)
        cardView.addSubview(stackView)
        cardView.addSubview(closeButton)

        cardView.snp.makeConstraints { $0.edges.equalToSuperview() }

        closeButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.width.height.equalTo(16)
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }

        let section1Title = makeTitleLabel("1) 자유롭게 이야기해 주세요.")
        let section1Desc = makeDescLabel(
            full: "형식에 맞춰 입력하지 않아도 괜찮아요.\n평소 말하듯 입력하면 AI가 날짜, 장소, 금액,\n카테고리 등을 자동으로 정리해 기록해 드려요.",
            highlights: ["자동으로 정리해 기록해 드려요"]
        )

        let section2Title = makeTitleLabel("2) 소비할 때의 기분도 함께 입력해 보세요.")
        let section2Desc = makeDescLabel(
            full: "감정까지 기록하면 나의 소비 패턴을 더 잘 이해하고,\n충동소비나 기분 소비를 돌아보는 데 도움이 돼요.",
            highlights: ["나의 소비 패턴을 더 잘 이해"]
        )

        // exampleBox를 감싸 stack 폭은 채우되, box는 콘텐츠 크기로 leading 정렬
        let exampleRow = UIView()
        exampleRow.addSubview(exampleBox)
        exampleBox.snp.makeConstraints {
            $0.top.bottom.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
        }

        [section1Title, section1Desc, exampleRow, section2Title, section2Desc].forEach {
            stackView.addArrangedSubview($0)
        }
        stackView.setCustomSpacing(2, after: section1Title)
        stackView.setCustomSpacing(6, after: section1Desc)
        stackView.setCustomSpacing(16, after: exampleRow)
        stackView.setCustomSpacing(2, after: section2Title)
    }

    private func makeTitleLabel(_ text: String) -> AppLabel {
        let label = AppLabel()
        label.text = text
        label.textColor = .gray2
        label.typography = .b7
        label.numberOfLines = 0
        return label
    }

    private func makeDescLabel(full: String, highlights: [String]) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4

        let attr = NSMutableAttributedString(
            string: full,
            attributes: [
                .font: Typography.b8.uiFont,
                .foregroundColor: UIColor.gray3,
                .paragraphStyle: paragraph
            ]
        )

        for highlight in highlights {
            let range = (full as NSString).range(of: highlight)
            if range.location != NSNotFound {
                attr.addAttribute(.foregroundColor, value: UIColor.green4, range: range)
            }
        }

        label.attributedText = attr
        return label
    }
}
