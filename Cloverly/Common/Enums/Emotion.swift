//
//  Emotion.swift
//  Cloverly
//
//  Created by 이인호 on 1/2/26.
//

import Foundation

enum Emotion: String, Codable, CaseIterable {
    case neutral = "NEUTRAL"
    case stress_relief = "STRESS_RELIEF"
    case reward = "REWARD"
    case impulse = "IMPULSE"
    case regret = "REGRET"
    case satisfaction = "SATISFACTION"
    
    var displayName: String {
        switch self {
        case .neutral:
            "일상"
        case .stress_relief:
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
    
    var imageName: String {
        switch self {
        case .neutral:
            "Emoji Normal"
        case .stress_relief:
            "Emoji Stress Relief"
        case .reward:
            "Emoji Self Reward"
        case .impulse:
            "Emoji Impulse Buying"
        case .regret:
            "Emoji Regret"
        case .satisfaction:
            "Emoji Satisfaction"
        }
    }
}
