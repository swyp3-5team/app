//
//  FormItemView.swift
//  Cloverly
//
//  Created by 이인호 on 12/21/25.
//

import UIKit
import SnapKit

class FormItemView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardSemiBold, size: 14)
        label.textColor = .gray2
        return label
    }()
    
    let actionButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("추가", for: .normal)
        btn.setTitleColor(.blueConfirm, for: .normal)
        btn.titleLabel?.font = .customFont(.pretendardSemiBold, size: 14)
        btn.isHidden = true
        return btn
    }()
    
    var onAction: (() -> Void)?
    
    let contentView: UIView // 텍스트필드나 칩 뷰가 들어갈 자리
    
    init(title: String, content: UIView, showActionBtn: Bool = false) {
        self.contentView = content
        super.init(frame: .zero)
        self.titleLabel.text = title
        
        // 버튼 설정
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
    
    func configureUI() {
        addSubview(titleLabel)
        addSubview(actionButton)
        addSubview(contentView)
        
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview() // 상단, 좌측 고정
        }
        
        actionButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview() // 오른쪽 끝 정렬
        }
        
        contentView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview() // 좌우 꽉 채우기
        }
    }
}
