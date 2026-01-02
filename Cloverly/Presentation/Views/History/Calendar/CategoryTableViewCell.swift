//
//  CategoryTableViewCell.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import UIKit
import SnapKit

class CategoryTableViewCell: UITableViewCell {
    
    static let identifier = "CategoryTableViewCell"
    
    private let cellImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "Chevron right gray")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardMedium, size: 16)
        label.textColor = .gray1
        label.textAlignment = .center
        return label
    }()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardRegular, size: 14)
        label.textColor = .gray4
        label.textAlignment = .center
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardSemiBold, size: 18)
        label.textColor = .gray1
        label.textAlignment = .center
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureUI() {
        contentView.addSubview(cellImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(percentageLabel)
        contentView.addSubview(priceLabel)
        
        cellImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(cellImageView.snp.trailing).offset(16)
            $0.centerY.equalToSuperview()
        }
        
        percentageLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }
        
        priceLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
    }
    
    func configure(color: UIColor, name: String, amount: Double, percent: Double) {
        //            colorBarView.backgroundColor = color
        
        // 이모지 매핑 (간단하게 구현)
        let emoji = getEmoji(for: name)
        titleLabel.text = "\(emoji) \(name)"
        
        percentageLabel.text = String(format: "%.0f%%", percent) // 소수점 없이 (21%)
        priceLabel.text = "\(amount.withComma)원"
    }
    
    // 카테고리 이름에 따라 이모지 리턴하는 헬퍼 함수
    private func getEmoji(for name: String) -> String {
        if name.contains("식비") { return "🍚" }
        if name.contains("쇼핑") { return "🛍️" }
        if name.contains("카페") { return "🍰" }
        if name.contains("교통") { return "🚌" }
        if name.contains("생활용품") { return "🧹" }
        if name.contains("건강") { return "💪" }
        if name.contains("취미") { return "🧶" }
        return "💸" // 기본값
    }
    
}
