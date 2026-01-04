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
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        return view
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
        contentView.addSubview(indicatorView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(percentageLabel)
        contentView.addSubview(priceLabel)
        
        indicatorView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.bottom.equalToSuperview().inset(15)
            $0.width.equalTo(4)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(indicatorView.snp.trailing).offset(16)
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
    
    func configure(color: UIColor, name: String, amount: Double, percent: Double, categoryId: Int) {
        let icon = ExpenseCategory(rawValue: categoryId)?.icon ?? "💸"
        titleLabel.text = "\(icon) \(name)"
        indicatorView.backgroundColor = color
        
        percentageLabel.text = String(format: "%.0f%%", percent) // 소수점 없이 (21%)
        priceLabel.text = "\(amount.withComma)원"
    }
}
