//
//  User.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import Foundation

enum AuthStatus {
    case unauthenticated
    case needsOnboarding
    case authenticated
}

enum AuthProvider: Codable {
    case kakao
    case apple
}

struct User: Codable, Hashable, Identifiable {
    let id: String
    let email: String
    var nickname: String
    let providerUserId: String
    let provider: AuthProvider
}
