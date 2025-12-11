//
//  TokenResponse.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import Foundation

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
