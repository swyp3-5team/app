//
//  Emotion.swift
//  Cloverly
//
//  Created by 이인호 on 1/2/26.
//

import Foundation

enum Emotion: String, Codable, CaseIterable {
    case neutral = "NEUTRAL"
    case satisfaction = "SATISFACTION"
    case reward = "REWARD"
    case stress_relief = "STRESS_RELIEF"
    case impulse = "IMPULSE"
    case regret = "REGRET"
    
    var displayName: String {
        switch self {
        case .neutral:
            "일상"
        case .satisfaction:
            "만족"
        case .reward:
            "보상 심리"
        case .stress_relief:
            "스트레스 해소"
        case .impulse:
            "충동 구매"
        case .regret:
            "후회"
        }
    }
    
    var imageName: String {
        switch self {
        case .neutral:
            "Emoji Normal"
        case .satisfaction:
            "Emoji Satisfaction"
        case .reward:
            "Emoji Self Reward"
        case .stress_relief:
            "Emoji Stress Relief"
        case .impulse:
            "Emoji Impulse Buying"
        case .regret:
            "Emoji Regret"
        }
    }
}
