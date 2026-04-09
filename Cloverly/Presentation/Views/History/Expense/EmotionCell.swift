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
        label.textColor = .gray5
        label.typography = .b6
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
            $0.top.equalToSuperview().offset(14)
            $0.centerX.equalToSuperview()
        }
        
        imageView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-6)
        }
    }
    
    private func updateAppearance() {
        if isSelected {
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = UIColor.green5.cgColor
            contentView.backgroundColor = .white
            titleLabel.textColor = .gray1
            titleLabel.typography = .b5
            imageView.layer.shadowColor = UIColor.black.cgColor
            imageView.layer.shadowOpacity = 0.15
            imageView.layer.shadowOffset = .zero
            imageView.layer.shadowRadius = 5
            if let imageName = imageView.accessibilityIdentifier {
                imageView.image = UIImage(named: imageName)
            }
        } else {
            contentView.layer.borderWidth = 0
            contentView.backgroundColor = .gray9
            titleLabel.textColor = .gray5
            titleLabel.typography = .b6
            imageView.layer.shadowOpacity = 0
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
