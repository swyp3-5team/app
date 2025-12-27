//
//  ToastView.swift
//  Cloverly
//
//  Created by 이인호 on 12/27/25.
//

import UIKit
import SnapKit

class ToastView: UIView {

    var onActionTap: (() -> Void)?
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray10
        label.font = .customFont(.pretendardMedium, size: 16)
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.gray10, for: .normal) // 버튼 색상 (원하는 색으로 변경)
        button.titleLabel?.font = .customFont(.pretendardMedium, size: 16)
        
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        button.addAction(UIAction { [weak self] _ in
            self?.onActionTap?()
        }, for: .touchUpInside)
        
        return button
    }()
    
    init(message: String, buttonTitle: String) {
        super.init(frame: .zero)
        
        self.backgroundColor = .gray1.withAlphaComponent(0.6)
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        
        messageLabel.text = message
        actionButton.setTitle(buttonTitle, for: .normal)
        
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupLayout() {
        addSubview(messageLabel)
        addSubview(actionButton)
        
        messageLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(15)
            $0.leading.equalToSuperview().offset(16)
        }
        
        actionButton.snp.makeConstraints {
            $0.centerY.equalTo(messageLabel.snp.centerY)
            $0.trailing.equalToSuperview().offset(-16)
        }
    }
}
