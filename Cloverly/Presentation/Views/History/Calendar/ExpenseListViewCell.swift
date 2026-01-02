//
//  ExpenseListViewCell.swift
//  Cloverly
//
//  Created by wayblemac02 on 1/2/26.
//

import UIKit
import SnapKit

class ExpenseListViewCell: UITableViewCell {
    
    static let identifier = "ExpenseListViewCell"
    
    private let cellImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "Chevron right gray")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardMedium, size: 16)
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardMedium, size: 16)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var containerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardMedium, size: 16)
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
        contentView.addSubview(containerStackView)
        contentView.addSubview(priceLabel)
        
        cellImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        
        containerStackView.snp.makeConstraints {
            $0.leading.equalTo(cellImageView.snp.trailing).offset(16)
            $0.centerY.equalToSuperview()
        }
        
        priceLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
    }
    
    func configure(with menu: MyPageMenu) {
        titleLabel.text = menu.rawValue
    }

}
