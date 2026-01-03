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
        label.font = .systemFont(ofSize: 12, weight: .medium) // 폰트 사이즈 조절
        label.textColor = .gray
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
        contentView.layer.borderColor = UIColor.systemGray5.cgColor
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
            contentView.layer.borderColor = UIColor.systemGreen.cgColor // 색상 코드 #2CC069 등
            contentView.layer.borderWidth = 1.5
            titleLabel.textColor = .black
            titleLabel.font = .systemFont(ofSize: 12, weight: .bold)
        } else {
            // ⬜️ 해제됨: 회색 테두리 + 회색 글씨
            contentView.layer.borderColor = UIColor.systemGray5.cgColor
            contentView.layer.borderWidth = 1
            titleLabel.textColor = .gray
            titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        }
    }
    
    func configure(emotion: Emotion) {
        titleLabel.text = emotion.displayName
        imageView.image = UIImage(named: emotion.imageName)
    }
}
