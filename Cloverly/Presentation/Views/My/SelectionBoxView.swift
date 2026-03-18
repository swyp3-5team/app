//
//  SelectionBoxView.swift
//  Cloverly
//
//  Created by 이인호 on 12/31/25.
//

import UIKit
import SnapKit

class SelectionBoxView: UIView {
    
    private let imojiLabel = AppLabel()
    private let titleLabel = AppLabel()
    private let subtitleLabel: AppLabel = {
        let label = AppLabel()
        label.numberOfLines = 0
        return label
    }()
    
    private let checkImageView = UIImageView()
    
    var isSelectedBox: Bool = false {
        didSet {
            configureUI()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func configureUI() {
        self.layer.cornerRadius = 12
        self.layer.borderWidth = 1
        
        addSubview(imojiLabel)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(checkImageView)
        
        imojiLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalTo(imojiLabel.snp.trailing).offset(6)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.bottom.equalToSuperview().offset(-20)
        }
        
        checkImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
        }
        
        if isSelectedBox {
            // 선택됨: 초록색 테두리 + 채워진 이미지
            self.layer.borderColor = UIColor.green5.cgColor
            self.titleLabel.textColor = .gray1
            self.titleLabel.typography = .b1

            self.subtitleLabel.textColor = .gray2
            self.subtitleLabel.typography = .b7

            self.checkImageView.image = UIImage(named: "Radio Buttons enabled")
        } else {
            // 꺼짐: 회색 테두리 + 빈 이미지
            self.layer.borderColor = UIColor.gray8.cgColor
            self.titleLabel.textColor = .gray5
            self.titleLabel.typography = .b3

            self.subtitleLabel.textColor = .gray6
            self.subtitleLabel.typography = .b7

            self.checkImageView.image = UIImage(named: "Radio Buttons disabled")
        }
    }
    
    func setContents(imoji: String, title: String, subtitle: String) {
        self.imojiLabel.text = imoji
        self.titleLabel.text = title
        self.subtitleLabel.text = subtitle
    }
}
