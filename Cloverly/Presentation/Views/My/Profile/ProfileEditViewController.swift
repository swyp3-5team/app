//
//  ProfileEditViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/28/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit


class ProfileEditViewController: UIViewController {
    private let disposeBag = DisposeBag()
    
    private let profileImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "mypage profile 2")
        return imageView
    }()
    
    private lazy var nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.text = AuthViewModel.shared.currentUser.value?.nickName
        textField.placeholder = "10글자 이하의 닉네임"
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
    
    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Reset icon"), for: .normal)
        button.addAction(UIAction { [weak self] _ in
            self?.nicknameTextField.text = ""
            self?.nicknameTextField.sendActions(for: .editingChanged)
        }, for: .touchUpInside)
        return button
    }()
    
    private let confirmImage: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private let confirmLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardRegular, size: 12)
        label.isHidden = true
        return label
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("저장", for: .normal)
        button.setTitleColor(UIColor.gray, for: .normal)
        button.titleLabel?.font = .customFont(.pretendardSemiBold, size: 16)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        
        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            
            guard let nickname = self.nicknameTextField.text?.trimmingCharacters(in: .whitespaces),
                  !nickname.isEmpty else {
                print("닉네임을 입력해주세요!")
                return
            }
            // 프로필 업데이트
            Task {
                do {
                    try await AuthViewModel.shared.updateProfile(nickname: nickname)
                    self.navigationController?.popViewController(animated: true)
                } catch {
                    print("프로필 수정 실패: \(error)")
                }
            }
            
        }, for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func configureUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "프로필"
        
        view.addSubview(profileImage)
        view.addSubview(nicknameTextField)
        view.addSubview(resetButton)
        view.addSubview(confirmImage)
        view.addSubview(confirmLabel)
        view.addSubview(saveButton)
        
        profileImage.snp.makeConstraints {
            $0.top.equalToSuperview().offset(151)
            $0.centerX.equalToSuperview()
        }
        
        nicknameTextField.snp.makeConstraints {
            $0.top.equalTo(profileImage.snp.bottom).offset(40)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }
        
        resetButton.snp.makeConstraints {
            $0.trailing.equalTo(nicknameTextField).offset(-16)
            $0.centerY.equalTo(nicknameTextField.snp.centerY)
        }
        
        confirmImage.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(confirmLabel)
        }
        
        confirmLabel.snp.makeConstraints {
            $0.top.equalTo(nicknameTextField.snp.bottom).offset(4)
            $0.leading.equalTo(confirmImage.snp.trailing).offset(4)
        }
        
        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
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
                
                self.saveButton.setTitleColor(state.buttonTextColor, for: .normal)
                self.saveButton.backgroundColor = state.buttonBackgroundColor
                
                self.confirmImage.image = UIImage(named: "\(state.imageName)")
            })
            .disposed(by: disposeBag)
        
        validation
            .map { $0.isValid }
            .bind(to: saveButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    private func isNicknameValid(_ text: String) -> Bool {
        let regex = "^[가-힣ㄱ-ㅎㅏ-ㅣa-zA-Z0-9]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: text)
    }
}

extension ProfileEditViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton {
            return false
        }

        return true
    }
}

