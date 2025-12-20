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
import RxCocoa

@MainActor
final class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    var authStatus = PublishRelay<AuthStatus>()
    let api = LoginAPI()
    
    var serviceTerm = false
    var privacyTerm = false
    var marketingEnable = false
    var tempAccessToken = ""
    var tempRefreshToken = ""
    
    
    private init() {}
    
    func kakaoLogin() {
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk {oauthToken, error in
                if let error = error {
                    print("카카오 로그인 실패: \(error.localizedDescription)")
                    self.authStatus.accept(.unauthenticated)
                    return
                }
                
                guard let idToken = oauthToken?.idToken else {
                    print("ID Token을 가져오지 못했습니다")
                    self.authStatus.accept(.unauthenticated)
                    return
                }
                
                self.loginWithServer(idToken: idToken, provider: .kakao)
            }
        } else {
            UserApi.shared.loginWithKakaoAccount {oauthToken, error in
                if let error = error {
                    print("카카오계정 로그인 실패: \(error.localizedDescription)")
                    self.authStatus.accept(.unauthenticated)
                    return
                }
                
                guard let idToken = oauthToken?.idToken else {
                    print("ID Token을 가져오지 못했습니다")
                    self.authStatus.accept(.unauthenticated)
                    return
                }
                
                self.loginWithServer(idToken: idToken, provider: .kakao)
            }
        }
    }
    
    func appleLogin(auth: ASAuthorization) {
        guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
            print("로그인 인증 실패")
            self.authStatus.accept(.unauthenticated)
            return
        }
        
        guard let codeData = credential.authorizationCode, let code = String(data: codeData, encoding: .utf8) else {
            print("토큰 얻기 실패")
            self.authStatus.accept(.unauthenticated)
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
                    let tokenData = TokenRequest(accessToken: response.accessToken, refreshToken: response.refreshToken)
                    tempAccessToken = response.accessToken
                    tempRefreshToken = response.refreshToken
                    self.authStatus.accept(.needsOnboarding)
                } else {
                    KeychainManager.shared.save(accessToken: response.accessToken, refreshToken: response.refreshToken)
                    self.authStatus.accept(.authenticated)
                }
            } catch {
                print("결과 가져오기 실패: \(error.localizedDescription)")
                self.authStatus.accept(.unauthenticated)
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
    
    func saveUser(nickname: String) {
        Task {
            do {
                try await api.saveUser(nickname: nickname, marketingEnable: marketingEnable, token: tempAccessToken)
                KeychainManager.shared.save(accessToken: tempAccessToken, refreshToken: tempRefreshToken)
                self.authStatus.accept(.authenticated)
            } catch {
                print("유저 저장 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteKakaoUser() {
        Task {
            do {
                try await api.deleteKakaoUser()
                KeychainManager.shared.delete(key: "accessToken")
                KeychainManager.shared.delete(key: "refreshToken")
            } catch {
                print("카카오 회원탈퇴 실패: \(error.localizedDescription)")
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
            self.authStatus.accept(.unauthenticated)
            return
        }
        
        self.authStatus.accept(.unauthenticated)
    }
}
