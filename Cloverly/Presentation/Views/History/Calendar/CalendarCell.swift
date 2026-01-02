//
//  CalendarCell.swift
//  Cloverly
//
//  Created by 이인호 on 12/31/25.
//

import UIKit
import SnapKit
import FSCalendar

class CalendarCell: FSCalendarCell {
    static let identifier = "CalendarCell"
    
    private let expenseLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardRegular, size: 10)
        label.textColor = .gray4
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func configureAppearance() {
        super.configureAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        expenseLabel.text = nil
    }
    
    private func configureUI() {
        contentView.addSubview(expenseLabel)
        
        expenseLabel.snp.remakeConstraints {
            $0.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            $0.centerX.equalToSuperview()
        }
    }
    
    func configure(with expense: String) {
        expenseLabel.text = expense
    }
}
