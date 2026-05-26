//
//  FilterCategoryCell.swift
//  Cloverly
//
//  Created by 이인호 on 1/4/26.
//

import UIKit
import SnapKit

class FilterCategoryCell: UICollectionViewCell {
    static let identifier = "FilterCategoryCell"
    
    private let label: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray1
        label.typography = .b7
        label.textAlignment = .center
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.bounds.height / 2
    }
    
    private func setupUI() {
        contentView.layer.borderWidth = 1
        contentView.backgroundColor = .white
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(label)
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(10)
            $0.leading.trailing.equalToSuperview().inset(16) // 좌우 여백
        }
        
        updateAppearance() // 초기 상태 설정
    }
    
    func configure(text: String) {
        label.text = text
    }
    
    private func updateAppearance() {
        if isSelected {
            contentView.layer.borderColor = UIColor.green5.cgColor
            label.typography = .b5
        } else {
            contentView.layer.borderColor = UIColor.gray8.cgColor
            label.typography = .b7
        }
    }
}

class SelfSizingCollectionView: UICollectionView {
    override var intrinsicContentSize: CGSize {
        return collectionViewLayout.collectionViewContentSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != intrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }
}

class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            
            layoutAttribute.frame.origin.x = leftMargin
            
            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }
        
        return attributes
    }
}
