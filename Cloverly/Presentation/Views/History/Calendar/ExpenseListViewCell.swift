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
    
    private let titleLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray1
        label.typography = .b2
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray4
        label.typography = .b7
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

    private let priceLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray1
        label.typography = .t1
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
        titleLabel.text = transaction.place?.nilIfNullOrEmpty ?? "미입력"
        subtitleLabel.text = "\(transaction.emotion.displayName) · \(transaction.transactionInfoList.max { $0.amount < $1.amount }?.categoryName ?? "내역 없음")"
        indicatorView.backgroundColor = transaction.transactionInfoList
            .max { $0.amount < $1.amount }
            .map { ExpenseCategory.from(id: $0.categoryId).color }
        let isIncome = transaction.transactionInfoList.first?.type == "INCOME"
        priceLabel.text = isIncome ? "\(transaction.totalAmount.withComma)원" : "-\(transaction.totalAmount.withComma)원"
    }

    func configure(with transaction: TransactionRecord, color: UIColor, isIncome: Bool = false) {
        titleLabel.text = transaction.name.nilIfNullOrEmpty ?? "미입력"
        subtitleLabel.text = "\(transaction.emotion.displayName) · \(transaction.payment.displayName)"
        indicatorView.backgroundColor = color
        let sign = isIncome ? "+" : "-"
        priceLabel.text = "\(sign)\(transaction.amount.withComma)원"
    }
}
