//
//  AuthViewModel.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import Foundation
import KakaoSDKUser
import KakaoSDKAuth
import KakaoSDKCommon
import Combine
import AuthenticationServices
import RxSwift
import RxCocoa

@MainActor
final class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    var authStatus = PublishRelay<AuthStatus>()
    let errorRelay = PublishRelay<AppError>()
    let api = LoginAPI()

    let currentUser = BehaviorRelay<User?>(value: nil)
    
    var serviceTerm = false
    var privacyTerm = false
    var marketingEnable = false
    var tempAccessToken = ""
    var tempRefreshToken = ""
    
    
    private init() {}
    
    func kakaoLogin() {
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk { [weak self] oauthToken, error in
                self?.handleKakaoLoginResult(oauthToken: oauthToken, error: error)
            }
        } else {
            UserApi.shared.loginWithKakaoAccount { [weak self] oauthToken, error in
                self?.handleKakaoLoginResult(oauthToken: oauthToken, error: error)
            }
        }
    }

    private func handleKakaoLoginResult(oauthToken: OAuthToken?, error: Error?) {
        if let error = error {
            self.authStatus.accept(.unauthenticated)
            if !Self.isUserCancellation(error) {
                self.errorRelay.accept(.unknown)
            }
            return
        }

        guard let idToken = oauthToken?.idToken else {
            self.authStatus.accept(.unauthenticated)
            self.errorRelay.accept(.unknown)
            return
        }

        self.loginWithServer(idToken: idToken, provider: .kakao)
    }

    func appleLogin(auth: ASAuthorization) {
        guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
            self.authStatus.accept(.unauthenticated)
            self.errorRelay.accept(.unknown)
            return
        }

        guard let codeData = credential.authorizationCode, let code = String(data: codeData, encoding: .utf8) else {
            self.authStatus.accept(.unauthenticated)
            self.errorRelay.accept(.unknown)
            return
        }

        loginWithServer(idToken: code, provider: .apple)
    }

    static func isUserCancellation(_ error: Error) -> Bool {
        if let asError = error as? ASAuthorizationError {
            return asError.code == .canceled
        }
        if let sdkError = error as? SdkError,
           case .ClientFailed(let reason, _) = sdkError,
           reason == .Cancelled {
            return true
        }
        return false
    }

    private func loginWithServer(idToken: String, provider: AuthProvider) {
        Task {
            do {
                let response = try await api.socialLogin(idToken: idToken, provider: provider)

                if response.newUser {
                    tempAccessToken = response.accessToken
                    tempRefreshToken = response.refreshToken
                    self.authStatus.accept(.needsOnboarding)
                } else {
                    KeychainManager.shared.save(accessToken: response.accessToken, refreshToken: response.refreshToken)
                    self.authStatus.accept(.authenticated)
                }
            } catch {
                self.authStatus.accept(.unauthenticated)
                self.errorRelay.accept(AppError.from(error))
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
    
    func saveUser(nickname: String) async throws {
        try await api.saveUser(nickname: nickname, marketingEnable: marketingEnable, token: tempAccessToken)
        KeychainManager.shared.save(accessToken: tempAccessToken, refreshToken: tempRefreshToken)
        self.authStatus.accept(.authenticated)
    }
    
    func getProfile() {
        Task {
            do {
                let user = try await api.getProfile()
                currentUser.accept(user)
            } catch {
                print("프로필 조회 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func logout() {
        currentUser.accept(nil)
        KeychainManager.shared.delete(key: "accessToken")
        KeychainManager.shared.delete(key: "refreshToken")
    }
    
    func updateProfile(nickname: String) async throws {
        let user = try await api.updateProfile(nickname: nickname)
        currentUser.accept(user)
    }
    
    func deleteKakaoUser() async throws {
        try await api.deleteKakaoUser()
        KeychainManager.shared.delete(key: "accessToken")
        KeychainManager.shared.delete(key: "refreshToken")
    }
    
    func deleteAppleUser() async throws {
        try await api.deleteAppleUser()
        KeychainManager.shared.delete(key: "accessToken")
        KeychainManager.shared.delete(key: "refreshToken")
    }
    
    private func getUserInfo() {
        UserApi.shared.me { user, error in
            if let error = error {
                print("유저 정보 가져오기 실패: \(error.localizedDescription)")
                return
            }
            
            guard let user = user, user.id != nil else { return }
        }
    }
    
    func checkLoginStatus() {
        guard KeychainManager.shared.read(key: "accessToken") != nil else {
            self.authStatus.accept(.unauthenticated)
            return
        }
        
        self.authStatus.accept(.unauthenticated)
    }
}
