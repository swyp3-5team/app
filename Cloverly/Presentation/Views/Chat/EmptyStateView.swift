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
        label.text = "가계부를 입력해 주세요!"
        label.textColor = .gray1
        label.typography = .h2
        label.textAlignment = .center
        return label
    }()

    let descriptionLabel: AppLabel = {
        let label = AppLabel()
        label.text = "언제, 어디서, 무엇을, 얼마를 썼는지\n그때의 기분까지 편하게 말해 주세요💭"
        label.textColor = .gray3
        label.typography = .b5
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    let exampleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "ex) 오늘 백화점에서 옷 사는데\n5만 원 썼어 충동구매해버렸네 ㅠ_ㅠ"
        label.textColor = .gray5
        label.typography = .b8
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // 예시 문구를 감싸는 둥근 회색 박스
    let exampleBox: UIView = {
        let v = UIView()
        v.backgroundColor = .gray9
        v.layer.cornerRadius = 16
        v.isHidden = true
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        exampleBox.addSubview(exampleLabel)
        exampleLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        addSubview(stackView)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addArrangedSubview(exampleBox)
        stackView.setCustomSpacing(4, after: messageLabel)
        stackView.setCustomSpacing(16, after: descriptionLabel)

        stackView.snp.makeConstraints {   
            $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(24)
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(20)
            $0.trailing.lessThanOrEqualToSuperview().offset(-20)
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}
