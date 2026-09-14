//
//  DateHeaderView.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit

class DateHeaderView: UICollectionReusableView {
    static let id = "DateHeaderView"
    
    let dateLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray3
        label.typography = .l1
        label.textAlignment = .center
        return label
    }()

    private let calendarIconView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "calendar icon"))
        view.contentMode = .scaleAspectFit
        view.setContentHuggingPriority(.required, for: .horizontal)
        return view
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [calendarIconView, dateLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4   // 아이콘 ↔ 텍스트 간격
        return stack
    }()

    // 상단 여백. 첫 헤더(맨 위)는 16, 이후 헤더는 이전 채팅과의 간격 30. (아래 24는 헤더 총 높이에서 확보)
    static let firstTopInset: CGFloat = 16
    static let defaultTopInset: CGFloat = 30

    private var topConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            topConstraint = $0.top.equalToSuperview().offset(Self.defaultTopInset).constraint
        }
    }

    func setTopInset(_ inset: CGFloat) {
        topConstraint?.update(offset: inset)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
