//
//  TermsAgreementViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/18/25.
//

import UIKit
import SnapKit

class TermsAgreementViewController: UIViewController {
    
    private let allTermCheckControl = AllTermCheckControl(title: "약관 전체동의")
    private let serviceTermControl = TermCheckControl(title: "서비스 이용약관 동의 (필수)")
    private let privacyTermControl = TermCheckControl(title: "개인정보 수집 및 이용 동의 (필수)")
    private let marketingTermControl = TermCheckControl(title: "마케팅 정보 수신 동의 (선택)")
    
    private lazy var subTermControls = [serviceTermControl, privacyTermControl, marketingTermControl]
    private lazy var mandatoryControls = [serviceTermControl, privacyTermControl]
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "클로버리를 시작하려면\n이용약관에 동의해주세요"
        label.textColor = .gray1
        label.font = .customFont(.pretendardSemiBold, size: 22)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var termsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: subTermControls)
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = .gray8
        return view
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("다음", for: .normal)
        button.setTitleColor(.gray6, for: .normal)
        button.titleLabel?.font = .customFont(.pretendardSemiBold, size: 16)
        button.backgroundColor = .gray8
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.isEnabled = false
        
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            
            let vc = NicknameInputViewController()
            navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }
    
    private func bind() {
        allTermCheckControl.addAction(UIAction { [weak self] _ in
            self?.didTapAllTermCheck()
        }, for: .valueChanged)
        
        subTermControls.forEach { control in
            control.addAction(UIAction { [weak self] _ in
                self?.didTapIndividualTerm()
            }, for: .valueChanged)
        }
    }
    
    private func didTapAllTermCheck() {
        let isAllSelected = allTermCheckControl.isSelected
        
        subTermControls.forEach { $0.isSelected = isAllSelected }
        
        updateNextButtonState()
    }
    
    private func didTapIndividualTerm() {
        let isAllSelected = subTermControls.allSatisfy { $0.isSelected }
        allTermCheckControl.isSelected = isAllSelected
        
        updateNextButtonState()
    }
    
    private func updateNextButtonState() {
        let isMandatoryMet = mandatoryControls.allSatisfy { $0.isSelected }
        
        if isMandatoryMet {
            nextButton.isEnabled = true
            nextButton.backgroundColor = .green5
            nextButton.setTitleColor(.gray10, for: .normal)
        } else {
            // 비활성화 상태
            nextButton.isEnabled = false
            nextButton.backgroundColor = .gray8
            nextButton.setTitleColor(.gray6, for: .normal)
        }
    }
    
    private func configureUI() {
        view.addSubview(titleLabel)
        view.addSubview(allTermCheckControl)
        view.addSubview(divider)
        view.addSubview(termsStackView)
        view.addSubview(nextButton)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(127)
            $0.leading.equalToSuperview().offset(16)
        }
        
        allTermCheckControl.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(82)
            $0.leading.equalToSuperview().offset(16)
        }
        
        divider.snp.makeConstraints {
            $0.top.equalTo(allTermCheckControl.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }
        
        termsStackView.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }

        nextButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(50)
        }
    }
}
