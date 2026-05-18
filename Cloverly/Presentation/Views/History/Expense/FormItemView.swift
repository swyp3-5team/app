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
        label.typography = .b5
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
    
    let contentView: UIView // 텍스트필드나 칩 뷰가 들어갈 자리
    
    init(title: String, content: UIView, showActionBtn: Bool = false, tooltipText: String? = nil) {
        self.contentView = content
        super.init(frame: .zero)
        self.titleLabel.text = title

        if let tooltipText {
            infoButton.isHidden = false
            infoButton.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                TooltipView.show(from: self.infoButton, text: tooltipText)
            }, for: .touchUpInside)
        }

        if showActionBtn {
            self.actionButton.isHidden = false
            self.actionButton.addAction(UIAction { [weak self] _ in
                self?.onAction?()
            }, for: .touchUpInside)
        }
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTitle(_ title: String) {
        titleLabel.text = title
    }

    func configureUI() {
        addSubview(titleStack)
        addSubview(actionButton)
        addSubview(contentView)

        titleStack.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
        }
        
        actionButton.snp.makeConstraints {
            $0.centerY.equalTo(titleStack)
            $0.trailing.equalToSuperview() // 오른쪽 끝 정렬
        }
        
        contentView.snp.makeConstraints {
            $0.top.equalTo(titleStack.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview() // 좌우 꽉 채우기
        }
    }
}
