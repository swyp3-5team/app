//
//  TokenResponse.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import Foundation

struct TokenResponse: nonisolated Decodable {
    let accessToken: String
    let refreshToken: String?
}
