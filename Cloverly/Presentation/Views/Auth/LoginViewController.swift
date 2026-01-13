//
//  LoginViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import AuthenticationServices
import RxSwift
import RxCocoa
import SnapKit

class LoginViewController: UIViewController {
    private let viewModel = AuthViewModel.shared
    private let disposeBag = DisposeBag()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 감정도, 지출도"
        label.font = .customFont(.pretendardSemiBold, size: 22)
        label.textColor = .gray1
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "클로버리와 함께 정리해요"
        label.font = .customFont(.pretendardRegular, size: 16)
        label.textColor = .gray3
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "login image"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var kakaoLoginButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Btn_Kakao_Login"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addAction(UIAction { [weak self] _ in
            self?.viewModel.kakaoLogin()
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var appleLoginButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Btn_Apple_Login"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addAction(UIAction { [weak self] _ in
            self?.didTapAppleLogin()
        }, for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }
    
    func bind() {
        viewModel.authStatus
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                
                switch status {
                case .needsOnboarding:
                    let vc = TermsAgreementViewController()
                    navigationController?.pushViewController(vc, animated: true)
                case .authenticated:
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let sceneDelegate = windowScene.delegate as? SceneDelegate {
                        sceneDelegate.checkAndUpdateRootViewController()
                    }
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    func configureUI() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(imageView)
        view.addSubview(kakaoLoginButton)
        view.addSubview(appleLoginButton)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(125)
            $0.leading.equalToSuperview().offset(16)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.equalTo(titleLabel)
        }
        
        imageView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(79)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        kakaoLoginButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(56)
            $0.bottom.equalTo(appleLoginButton.snp.top).offset(-8)
        }
        
        appleLoginButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(56)
            $0.bottom.equalToSuperview().offset(-34)
        }
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
        viewModel.authStatus.accept(.unauthenticated)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        viewModel.appleLogin(auth: authorization)
    }
}

