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
    private let titleLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray2
        label.typography = .b7
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
        contentView.addSubview(titleLabel)
        contentView.addSubview(imageView)
        
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 0
        contentView.backgroundColor = .gray9
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.centerX.equalToSuperview()
        }
        
        imageView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(5)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(71)
            $0.height.equalTo(58)
        }
    }
    
    private func updateAppearance() {
        if isSelected {
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = UIColor.green5.cgColor
            contentView.backgroundColor = .white
            titleLabel.textColor = .gray1
            titleLabel.typography = .b5
            if let imageName = imageView.accessibilityIdentifier {
                imageView.image = UIImage(named: imageName)
            }
        } else {
            contentView.layer.borderWidth = 0
            contentView.backgroundColor = .gray9
            titleLabel.textColor = .gray2
            titleLabel.typography = .b7
            if let imageName = imageView.accessibilityIdentifier {
                imageView.image = UIImage(named: imageName + " Blur")
            }
        }
    }

    func configure(emotion: Emotion) {
        titleLabel.text = emotion.displayName
        imageView.accessibilityIdentifier = emotion.imageName
        imageView.image = UIImage(named: isSelected ? emotion.imageName : emotion.imageName + " Blur")
    }
}
