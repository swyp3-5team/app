//
//  SelectionBoxView.swift
//  Cloverly
//
//  Created by 이인호 on 12/31/25.
//

import UIKit
import SnapKit

class SelectionBoxView: UIView {
    
    private let imojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel: UILabel = {
        let label = UILabel()
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
            self.titleLabel.font = .customFont(.pretendardSemiBold, size: 16)
            self.titleLabel.textColor = .gray1
            
            self.subtitleLabel.font = .customFont(.pretendardRegular, size: 14)
            self.subtitleLabel.textColor = .gray2
            
            self.checkImageView.image = UIImage(named: "Radio Buttons enabled")
        } else {
            // 꺼짐: 회색 테두리 + 빈 이미지
            self.layer.borderColor = UIColor.gray8.cgColor
            self.titleLabel.font = .customFont(.pretendardRegular, size: 16)
            self.titleLabel.textColor = .gray5
            
            self.subtitleLabel.font = .customFont(.pretendardRegular, size: 14)
            self.subtitleLabel.textColor = .gray6
            
            self.checkImageView.image = UIImage(named: "Radio Buttons disabled")
        }
    }
    
    func setContents(imoji: String, title: String, subtitle: String) {
        self.imojiLabel.text = imoji
        self.titleLabel.text = title
        self.subtitleLabel.text = subtitle
    }
}
