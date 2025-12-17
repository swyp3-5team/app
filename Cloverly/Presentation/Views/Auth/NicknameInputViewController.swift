//
//  NicknameInputViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/17/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

enum NicknameValidateState {
    case empty
    case valid
    case lengthExceeded
    case invalidChar
    
    var message: String {
        switch self {
        case .empty: return ""
        case .valid: return "사용 가능한 닉네임입니다."
        case .lengthExceeded: return "10글자 이내로 입력해주세요."
        case .invalidChar: return "특수문자는 입력할 수 없습니다."
        }
    }
    
    var color: UIColor {
        switch self {
        case .valid: return .systemGreen
        case .empty: return .clear
        default: return .red
        }
    }
    
    var buttonTextColor: UIColor {
        switch self {
        case .valid: return .white
        default: return .lightGray
        }
    }
    
    var buttonBackgroundColor: UIColor {
        switch self {
        case .valid: return .systemGreen
        default: return .gray
        }
    }
    
    var isValid: Bool {
        return self == .valid
    }
}

class NicknameInputViewController: UIViewController {
    private let disposeBag = DisposeBag()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "닉네임을 입력해주세요"
        label.textColor = .black
        label.font = .systemFont(ofSize: 24)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "원하는 닉네임을 자유롭게 입력해주세요"
        label.textColor = .gray
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "10글자 이하의 닉네임"
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 12
        textField.clipsToBounds = true
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private let confirmLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10)
        label.isHidden = true
        return label
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setTitle("다음", for: .normal)
        button.setTitleColor(UIColor.gray, for: .normal)
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        
        button.addAction(UIAction { [weak self] _ in
            print("click")
        }, for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func configureUI() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(nicknameTextField)
        view.addSubview(confirmLabel)
        view.addSubview(nextButton)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.equalToSuperview().offset(16)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(16)
        }
        
        nicknameTextField.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(36)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(50)
        }
        
        confirmLabel.snp.makeConstraints {
            $0.top.equalTo(nicknameTextField.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(16)
        }
        
        nextButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(50)
        }
    }
    
    private func bind() {
        let validation = nicknameTextField.rx.text.orEmpty
            .map { [weak self] text -> NicknameValidateState in
                guard let self = self else { return .empty }
                
                if text.isEmpty { return .empty }
                if text.count > 10 { return .lengthExceeded }
                if !self.isNicknameValid(text) { return .invalidChar }
                
                return .valid
            }
            .share(replay: 1)
        
        validation
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                
                self.confirmLabel.text = state.message
                self.confirmLabel.textColor = state.color
                self.confirmLabel.isHidden = state == .empty
                self.confirmLabel.layer.borderColor = state.color.cgColor
                
                self.nextButton.setTitleColor(state.buttonTextColor, for: .normal)
                self.nextButton.backgroundColor = state.buttonBackgroundColor
            })
            .disposed(by: disposeBag)
        
        validation
            .map { $0.isValid }
            .bind(to: nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    private func isNicknameValid(_ text: String) -> Bool {
        let regex = "^[가-힣ㄱ-ㅎㅏ-ㅣa-zA-Z0-9]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: text)
    }
}
