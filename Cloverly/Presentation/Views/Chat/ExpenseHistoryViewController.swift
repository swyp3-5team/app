//
//  ExpenseHistoryViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit

class ExpenseHistoryViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "아래와 같이 저장할까요?"
        label.font = .customFont(.pretendardSemiBold, size: 18)
        return label
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "상호명을 입력해주세요"
        textField.textColor = .gray1
        textField.font = .customFont(.pretendardRegular, size: 14)
        textField.layer.borderColor = UIColor.gray8.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    let amountTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "총 금액을 입력해주세요"
        textField.textColor = .gray1
        textField.font = .customFont(.pretendardRegular, size: 14)
        textField.layer.borderColor = UIColor.gray8.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    let paymentTextField: UITextField = {
        let textField = UITextField()
        textField.layer.borderColor = UIColor.gray8.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        return textField
    }()
    
    let memoTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "지출 내역을 입력해주세요"
        textField.textColor = .gray1
        textField.font = .customFont(.pretendardRegular, size: 14)
        textField.layer.borderColor = UIColor.gray8.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    let paymentMethodTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 40
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("저장", for: .normal)
        button.setTitleColor(.gray10, for: .normal)
        button.titleLabel?.font = .customFont(.pretendardSemiBold, size: 16)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = .green5
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    func configureUI() {
        navigationItem.title = "지출 내역"
        
        let nameSection = FormItemView(title: "상호명", content: nameTextField)
        let amountSection = FormItemView(title: "총 금액", content: amountTextField)
        let paymentDateSection = FormItemView(title: "결제일", content: paymentTextField)
        let emojiSection = FormItemView(title: "감정이모지", content: UIView())
        let memoSection = FormItemView(title: "지출내역", content: memoTextField)
        let paymentMethodSection = FormItemView(title: "결제수단", content: paymentMethodTextField)
        let categoryMethodSection = FormItemView(title: "카테고리", content: UIView())
        
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(nameSection)
        stackView.addArrangedSubview(amountSection)
        stackView.addArrangedSubview(paymentDateSection)
        stackView.addArrangedSubview(emojiSection)
        stackView.addArrangedSubview(memoSection)
        stackView.addArrangedSubview(paymentMethodSection)
        stackView.addArrangedSubview(categoryMethodSection)
        
        scrollView.addSubview(stackView)
        view.addSubview(scrollView)
        view.addSubview(saveButton)
        
        nameTextField.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        amountTextField.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        paymentTextField.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        memoTextField.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        paymentMethodTextField.snp.makeConstraints {
            $0.height.equalTo(48)
        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(saveButton.snp.top).offset(-10)
        }
        
        // (B) 스택뷰 제약조건 (✨ 여기가 핵심)
        stackView.snp.makeConstraints {
            // 1. 스크롤 영역 정의 (위/아래/양옆 꽉 채우기)
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            
            // 2. 가로 스크롤 방지 (너비는 화면 너비와 똑같이!)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(50)
        }
    }
}
