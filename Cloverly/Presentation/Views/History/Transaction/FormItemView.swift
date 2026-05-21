//
//  FormItemView.swift
//  Cloverly
//
//  Created by 이인호 on 12/21/25.
//

import UIKit
import SnapKit

class FormItemView: UIView {
    private let titleLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray2
        label.typography = .b2
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    let contentView: UIView

    init(title: String, content: UIView) {
        self.contentView = content
        super.init(frame: .zero)
        titleLabel.text = title
        configureUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateTitle(_ title: String) {
        titleLabel.text = title
    }

    private func configureUI() {
        addSubview(titleLabel)
        addSubview(contentView)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(16)
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
    }
}
