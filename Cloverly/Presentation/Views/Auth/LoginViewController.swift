//
//  LoginViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import AuthenticationServices

class LoginViewController: UIViewController {
    private let viewModel = AuthViewModel.shared
    
    private lazy var kakaoLoginButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "KakaoLogin"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        
        button.addAction(UIAction { [weak self] _ in
            self?.viewModel.kakaoLogin()
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var appleLoginButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton()
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.addAction(UIAction { [weak self] _ in
            self?.didTapAppleLogin()
        }, for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    func configureUI() {
        view.addSubview(kakaoLoginButton)
        view.addSubview(appleLoginButton)
        
        kakaoLoginButton.translatesAutoresizingMaskIntoConstraints = false
        appleLoginButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            kakaoLoginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            kakaoLoginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            kakaoLoginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            kakaoLoginButton.heightAnchor.constraint(equalToConstant: 50),
            
            appleLoginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            appleLoginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            appleLoginButton.topAnchor.constraint(equalTo: kakaoLoginButton.bottomAnchor, constant: 16),
            appleLoginButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func didTapAppleLogin() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        self.view.window ?? UIWindow()
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        print("애플 로그인 실패: \(error.localizedDescription)")
        viewModel.authStatus = .unauthenticated
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        viewModel.appleLogin(auth: authorization)
    }
}

