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
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "지출 내역을 입력해주세요!"
        label.textColor = .gray1
        label.font = .customFont(.pretendardSemiBold, size: 22)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(stackView)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(messageLabel)
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(47)
            $0.centerX.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
