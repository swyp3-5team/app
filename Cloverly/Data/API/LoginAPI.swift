//
//  LoginAPI.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import Foundation
import Alamofire

final class LoginAPI {
    let baseURL: String
    
    init() {
        self.baseURL = Bundle.main.infoDictionary?["BASE_URL"] as? String ?? ""
    }
    
    func socialLogin(idToken: String, provider: AuthProvider) async throws -> LoginResponse {
        if provider == .kakao {
            return try await kakaoLogin(idToken: idToken)
        } else {
            return try await appleLogin(code: idToken)
        }
    }
    
    private func kakaoLogin(idToken: String) async throws -> LoginResponse {
        let requestBody = LoginRequest(idToken: idToken, deviceId: "iPhone")
        
        return try await AF.request(
                "\(baseURL)/auth/kakao/token",
                method: .post,
                parameters: requestBody,
                encoder: JSONParameterEncoder.default
            )
            .serializingDecodable(LoginResponse.self)
            .value
    }
    
    private func appleLogin(code: String) async throws -> LoginResponse {
        let requestBody = LoginRequest(idToken: code, deviceId: "iPhone")
        
        return try await AF.request(
                "\(baseURL)/auth/apple/callback",
                method: .post,
                parameters: requestBody,
                encoder: JSONParameterEncoder.default
            )
            .serializingDecodable(LoginResponse.self)
            .value
    }
    
    func saveUser(nickname: String, marketingEnable: Bool, token: String) async throws {
        let requestBody = SignUpRequest(nickname: nickname, marketingEnable: marketingEnable)
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: token)
        ]
        
        _ = try await AF.request(
            "\(baseURL)/auth/refresh",
            method: .post,
            parameters: requestBody,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate()
        .serializingData()
        .value
    }
    
    func deleteKakaoUser() async throws {
        _ = try await NetworkManager.shared.session.request(
            "\(baseURL)/auth/kakao/unlink",
            method: .delete
        )
        .validate()
        .serializingData()
        .value
    }
    
    func deleteAppleUser() async throws {
        _ = try await NetworkManager.shared.session.request(
            "\(baseURL)/auth/apple/unlink",
            method: .delete,
        )
        .validate()
        .serializingData()
        .value
    }
    
    func renewAccessToken() async throws -> Bool {
        guard let token = KeychainManager.shared.refreshToken else { return false }
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: token)
        ]
        
        let response = try await AF.request(
            "\(baseURL)/auth/refresh",
            method: .post,
            headers: headers
        )
        .validate()
        .serializingDecodable(TokenResponse.self)
        .value
        
        KeychainManager.shared.accessToken = response.accessToken
        
        if let newRefresh = response.refreshToken {
            KeychainManager.shared.refreshToken = newRefresh
        }
        
        return true
    }
}
