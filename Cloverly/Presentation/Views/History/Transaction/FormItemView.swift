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

    private let infoButton: UIButton = {
        let btn = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        btn.setImage(UIImage(systemName: "info.circle", withConfiguration: config), for: .normal)
        btn.tintColor = .gray4
        btn.isHidden = true
        return btn
    }()

    private lazy var titleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, infoButton])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.setContentHuggingPriority(.required, for: .horizontal)
        stack.setContentCompressionResistancePriority(.required, for: .horizontal)
        return stack
    }()

    let actionButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("추가", for: .normal)
        btn.setTitleColor(.blueConfirm, for: .normal)
        btn.titleLabel?.font = Typography.b5.uiFont
        btn.isHidden = true
        return btn
    }()

    var onAction: (() -> Void)?

    let contentView: UIView


    init(title: String, content: UIView, showActionBtn: Bool = false, tooltipText: String? = nil) {
        self.contentView = content
        super.init(frame: .zero)
        titleLabel.text = title

        if let tooltipText {
            infoButton.isHidden = false
            infoButton.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                TooltipView.show(from: self.infoButton, text: tooltipText)
            }, for: .touchUpInside)
        }

        if showActionBtn {
            actionButton.isHidden = false
            actionButton.addAction(UIAction { [weak self] _ in
                self?.onAction?()
            }, for: .touchUpInside)
        }

        configureUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateTitle(_ title: String) {
        titleLabel.text = title
    }

    private func configureUI() {
        addSubview(titleStack)
        addSubview(actionButton)
        addSubview(contentView)

        titleStack.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        actionButton.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(titleStack)
        }

        contentView.snp.makeConstraints {
            $0.leading.equalTo(titleStack.snp.trailing).offset(16)
            $0.trailing.equalTo(actionButton.isHidden ? snp.trailing : actionButton.snp.leading).offset(actionButton.isHidden ? 0 : -8)
            $0.top.bottom.equalToSuperview()
        }
    }
}
