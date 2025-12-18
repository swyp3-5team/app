//
//  AuthViewModel.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import Foundation
import KakaoSDKUser
import KakaoSDKAuth
import Combine
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    var authStatus: AuthStatus = .unauthenticated
    let api = LoginAPI()
    
    var serviceTerm = false
    var privacyTerm = false
    var marketingTerm = false
    var nickname = ""
    
    private init() {}
    
    func kakaoLogin() {
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk {oauthToken, error in
                if let error = error {
                    print("카카오 로그인 실패: \(error.localizedDescription)")
                    self.authStatus = .unauthenticated
                    return
                }
                
                guard let idToken = oauthToken?.idToken else {
                    print("ID Token을 가져오지 못했습니다")
                    self.authStatus = .unauthenticated
                    return
                }
                
                self.loginWithServer(idToken: idToken, provider: .kakao)
            }
        } else {
            UserApi.shared.loginWithKakaoAccount {oauthToken, error in
                if let error = error {
                    print("카카오계정 로그인 실패: \(error.localizedDescription)")
                    self.authStatus = .unauthenticated
                    return
                }
                
                guard let idToken = oauthToken?.idToken else {
                    print("ID Token을 가져오지 못했습니다")
                    self.authStatus = .unauthenticated
                    return
                }
                
                self.loginWithServer(idToken: idToken, provider: .kakao)
            }
        }
    }
    
    func appleLogin(auth: ASAuthorization) {
        guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
            print("로그인 인증 실패")
            authStatus = .unauthenticated
            return
        }
        
        guard let codeData = credential.authorizationCode, let code = String(data: codeData, encoding: .utf8) else {
            print("토큰 얻기 실패")
            authStatus = .unauthenticated
            return
        }
        
        loginWithServer(idToken: code, provider: .apple)
    }

    private func loginWithServer(idToken: String, provider: AuthProvider) {
        Task {
            do {
                let response = try await api.socialLogin(idToken: idToken, provider: provider)
                
                print("응답결과: \(response)")
                
                if response.newUser {
                    authStatus = .needsOnboarding
                } else {
                    if let accessToken = response.accessToken, let refreshToken = response.refreshToken {
                        KeychainManager.shared.save(accessToken: accessToken, refreshToken: refreshToken)
                        authStatus = .authenticated
                    } else {
                        authStatus = .unauthenticated
                    }
                }
            } catch {
                print("결과 가져오기 실패: \(error.localizedDescription)")
                authStatus = .unauthenticated
            }
        }
    }
    
    func kakaoLogout() {
        UserApi.shared.logout { error in
            if let error = error {
                print("로그아웃 실패: \(error.localizedDescription)")
            } else {
                print("로그아웃 성공")
            }
        }
    }
    
    func kakaoUnlink() {
        UserApi.shared.unlink { error in
            if let error = error {
                print("탈퇴 실패: \(error.localizedDescription)")
            } else {
                print("탈퇴 성공")
            }
        }
    }
    
    private func getUserInfo() {
        UserApi.shared.me { user, error in
            if let error = error {
                print("유저 정보 가져오기 실패: \(error.localizedDescription)")
                return
            }
            
            guard let user = user, let userId = user.id else { return }
            
            let kakaoId = String(userId)
            let email = user.kakaoAccount?.email
        }
    }
    
    func checkLoginStatus() {
        guard let accessToken = KeychainManager.shared.read(key: "accessToken") else {
            authStatus = .unauthenticated
            return
        }
        
        authStatus = .authenticated
    }
}
