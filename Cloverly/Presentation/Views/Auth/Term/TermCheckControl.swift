//
//  TermCheckControl.swift
//  Cloverly
//
//  Created by 이인호 on 12/18/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class TermCheckControl: UIControl {
    // MARK: - UI Components
    private let checkImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "check_disabled")
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardRegular, size: 14)
        label.textColor = .gray3
        return label
    }()
    
    // MARK: - Init
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupLayout()
        
        // 터치 이벤트 연결 (UIControl의 핵심)
        self.addTarget(self, action: #selector(didTapControl), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupLayout() {
        addSubview(checkImageView)
        addSubview(titleLabel)
        
        checkImageView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(checkImageView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Interaction & State
    @objc private func didTapControl() {
        isSelected.toggle()
        sendActions(for: .valueChanged)
    }
    
    override var isSelected: Bool {
        didSet {
            updateState()
        }
    }
    
    private func updateState() {
        if isSelected {
            checkImageView.image = UIImage(named: "check_enabled")
        } else {
            checkImageView.image = UIImage(named: "check_disabled")
        }
    }

}
