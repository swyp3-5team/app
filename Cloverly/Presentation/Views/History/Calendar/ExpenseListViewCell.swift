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
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardRegular, size: 14)
        label.textColor = .gray4
        label.textAlignment = .center
        return label
    }()
    
    private lazy var containerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.distribution = .fill
        return stack
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
        contentView.addSubview(containerStackView)
        contentView.addSubview(priceLabel)
        
        indicatorView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.bottom.equalToSuperview().inset(15)
            $0.width.equalTo(4)
        }
        
        containerStackView.snp.makeConstraints {
            $0.leading.equalTo(indicatorView.snp.trailing).offset(16)
            $0.top.bottom.equalToSuperview().inset(7)
        }
        
        priceLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(containerStackView)
        }
    }
    
    func configure(with transaction: Transaction) {
        titleLabel.text = transaction.place?.isEmpty == false ? transaction.place : "미입력"
        subtitleLabel.text = "\(transaction.emotion.displayName) · \(transaction.transactionInfoList.max { $0.amount < $1.amount }?.categoryName ?? "내역 없음")"
        indicatorView.backgroundColor = transaction.transactionInfoList
            .max { $0.amount < $1.amount }
            .map { ExpenseCategory.from(id: $0.categoryId).color }
        priceLabel.text = "-\(transaction.totalAmount.withComma)원"
    }
}
