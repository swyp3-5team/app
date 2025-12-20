//
//  LoginRequest.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import Foundation

struct LoginRequest: nonisolated Encodable {
    let idToken: String
    let deviceId: String
}

struct AppleLoginRequest: nonisolated Encodable {
    let code: String
    let deviceId: String
}

struct SignUpRequest: nonisolated Encodable {
    var nickname: String
    let marketingEnable: Bool
}

struct TokenRequest {
    let accessToken: String
    let refreshToken: String
}
