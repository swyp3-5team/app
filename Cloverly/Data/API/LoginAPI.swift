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
            "\(baseURL)/api/v1/user-profiles",
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
        guard let token = KeychainManager.shared.accessToken else { return }
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: token)
        ]
        
        _ = try await AF.request(
            "\(baseURL)/auth/kakao/unlink",
            method: .delete,
            headers: headers
        )
        .validate()
        .serializingData()
        .value
    }
    
    func deleteAppleUser() async throws {
        guard let token = KeychainManager.shared.accessToken else { return }
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: token)
        ]
        
        _ = try await AF.request(
            "\(baseURL)/auth/apple/unlink",
            method: .delete,
            headers: headers
        )
        .validate()
        .serializingData()
        .value
    }
    
//    func renewAccessToken() -> TokenResponse {
//
//    }
}
