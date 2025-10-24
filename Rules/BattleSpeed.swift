//
//  BattleSpeed.swift
//  cards
//
//  Created by Darryl Mah on 10/16/25.
//
// determines speed of battles
// tickMs - This controls how often the game loop advances — i.e., how long the system waits between automatic actions (attacks, heals, etc.) during auto-battle.
// animScale - This scales how fast or slow your on-screen animations play (movement, shake, flash, etc.).

import Foundation

enum BattleSpeed: String, CaseIterable, Identifiable {
    case slow
    case normal
    case fast
    
    var id: String { self.rawValue }
}

struct SpeedProfile {
    let tickMs: UInt64     // loop delay (GameState)
    let animScale: Double  // animation multiplier (BattleView)
}

extension BattleSpeed {
    var profile: SpeedProfile {
        switch self {
        case .slow:   return .init(tickMs: 2400, animScale: 6.4)
        case .normal: return .init(tickMs: 1200, animScale: 3.2)
        case .fast:   return .init(tickMs: 600,  animScale: 1.6)
        }
    }
}
