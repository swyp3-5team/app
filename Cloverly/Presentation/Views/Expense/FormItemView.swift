//
//  FormItemView.swift
//  Cloverly
//
//  Created by 이인호 on 12/21/25.
//

import UIKit
import SnapKit

class FormItemView: UIView {
    private let titleLabel = UILabel()
    let contentView: UIView // 텍스트필드나 칩 뷰가 들어갈 자리
    
    init(title: String, content: UIView) {
        self.contentView = content
        super.init(frame: .zero)
        self.titleLabel.text = title
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureUI() {
        addSubview(titleLabel)
        addSubview(contentView)
        
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview() // 상단, 좌측 고정
        }
        
        contentView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview() // 좌우 꽉 채우기
        }
    }
}
