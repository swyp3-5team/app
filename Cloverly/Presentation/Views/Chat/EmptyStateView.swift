//
//  EmptyStateView.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit

class EmptyStateView: UIView {
    
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 24
        sv.alignment = .center
        return sv
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "character profile")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    let messageLabel: AppLabel = {
        let label = AppLabel()
        label.text = "가계부를 입력해주세요!"
        label.textColor = .gray1
        label.typography = .h2
        label.textAlignment = .center
        return label
    }()

    let exampleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "ex) 오늘 메가커피에서 아메리카노\n4,500원짜리 사먹었어"
        label.textColor = .gray6
        label.typography = .b7
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(stackView)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(exampleLabel)
        stackView.setCustomSpacing(8, after: messageLabel)

        stackView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(47)
            $0.centerX.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
