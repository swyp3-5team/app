//
//  EmotionCell.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import UIKit
import SnapKit

class EmotionCell: UICollectionViewCell {
    
    // 이미지
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    // 텍스트 (일상, 만족 등)
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardRegular, size: 14)
        label.textColor = .gray2
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // ✨ 핵심: 선택 여부에 따라 디자인 자동 변경
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        
        // 둥근 테두리 박스
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.gray8.cgColor
        contentView.backgroundColor = .white
        
        imageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.centerX.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(5)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-10)
        }
    }
    
    private func updateAppearance() {
        if isSelected {
            // ✅ 선택됨: 초록색 테두리 + 검은 글씨
            contentView.layer.borderColor = UIColor.green5.cgColor
            titleLabel.textColor = .gray1
            titleLabel.font = .customFont(.pretendardSemiBold, size: 14)
        } else {
            // ⬜️ 해제됨: 회색 테두리 + 회색 글씨
            contentView.layer.borderColor = UIColor.gray8.cgColor
            titleLabel.textColor = .gray2
            titleLabel.font = .customFont(.pretendardRegular, size: 14)
        }
    }
    
    func configure(emotion: Emotion) {
        titleLabel.text = emotion.displayName
        imageView.image = UIImage(named: emotion.imageName)
    }
}
