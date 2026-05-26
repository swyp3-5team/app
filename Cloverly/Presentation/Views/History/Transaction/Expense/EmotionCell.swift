//
//  EmotionCell.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import UIKit
import SnapKit

class EmotionCell: UICollectionViewCell {

    private var emotion: Emotion?

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

    // 말풍선 배경
    private let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = .green11
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    // 말풍선 꼬리
    private let polygonImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "Polygon"))
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        return view
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
        contentView.addSubview(bubbleView)
        contentView.addSubview(polygonImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(imageView)

        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 0
        contentView.backgroundColor = .gray9

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.centerX.equalToSuperview()
        }

        bubbleView.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.leading).offset(-12)
            $0.trailing.equalTo(titleLabel.snp.trailing).offset(12)
            $0.top.equalTo(titleLabel.snp.top).offset(-4)
            $0.bottom.equalTo(titleLabel.snp.bottom).offset(4)
        }

        polygonImageView.snp.makeConstraints {
            $0.top.equalTo(bubbleView.snp.bottom).offset(-2)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(10)
            $0.height.equalTo(6)
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
            if let emotion {
                titleLabel.text = "\(emotion.displayName)\(emotion.icon)"
            }
            bubbleView.isHidden = false
            polygonImageView.isHidden = false
            DispatchQueue.main.async {
                self.bubbleView.layer.cornerRadius = self.bubbleView.bounds.height / 2
            }
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
            if let emotion {
                titleLabel.text = emotion.displayName
            }
            bubbleView.isHidden = true
            polygonImageView.isHidden = true
            imageView.layer.shadowOpacity = 0
            if let imageName = imageView.accessibilityIdentifier {
                imageView.image = UIImage(named: imageName + " Blur")
            }
        }
    }

    func configure(emotion: Emotion) {
        self.emotion = emotion
        titleLabel.text = isSelected ? "\(emotion.displayName)\(emotion.icon)" : emotion.displayName
        imageView.accessibilityIdentifier = emotion.imageName
        imageView.image = UIImage(named: isSelected ? emotion.imageName : emotion.imageName + " Blur")

        let hPadding: CGFloat = emotion == .stress_relief ? 8 : 12
        bubbleView.snp.remakeConstraints {
            $0.leading.equalTo(titleLabel.snp.leading).offset(-hPadding)
            $0.trailing.equalTo(titleLabel.snp.trailing).offset(hPadding)
            $0.top.equalTo(titleLabel.snp.top).offset(-4)
            $0.bottom.equalTo(titleLabel.snp.bottom).offset(4)
        }
    }
}
