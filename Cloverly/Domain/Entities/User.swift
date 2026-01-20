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

enum AuthProvider: String, Codable {
    case kakao = "KAKAO"
    case apple = "APPLE"
}

struct User: nonisolated Codable, Hashable, Identifiable {
    let profileId: Int
    let nickName: String
    let marketingEnable: Bool
    let userEmail: String
    let provider: AuthProvider
    
    var id: Int { profileId }
}
