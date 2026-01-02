//
//  Emotion.swift
//  Cloverly
//
//  Created by 이인호 on 1/2/26.
//

import Foundation

enum Emotion: String, Codable {
    case neutral = "NEUTRAL"
    case stress_releaf = "STRESS_RELIEF"
    case reward = "REWARD"
    case impulse = "IMPULSE"
    case regret = "REGRET"
    case satisfaction = "SATISFACTION"
    
    var displayName: String {
        switch self {
        case .neutral:
            "일상"
        case .stress_releaf:
            "스트레스 해소"
        case .reward:
            "보상 심리"
        case .impulse:
            "충동 구매"
        case .regret:
            "후회"
        case .satisfaction:
            "만족"
        }
    }
}
