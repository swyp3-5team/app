//
//  LoginResponse.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import Foundation

struct LoginResponse: nonisolated Decodable {
    let userId: Int
    let provider: String
    let userName: String?
    let userEmail: String
    let accessToken: String
    let refreshToken: String
    let message: String
    let newUser: Bool
}
