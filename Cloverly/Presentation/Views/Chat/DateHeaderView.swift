//
//  DateHeaderView.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit

class DateHeaderView: UICollectionReusableView {
    static let id = "DateHeaderView"
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray3
        label.font = .customFont(.pretendardRegular, size: 13)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(dateLabel)
        dateLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
