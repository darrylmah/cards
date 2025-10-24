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

struct BattleTempo {
    /// Baseline animation scale that represents the "normal" timing the game
    /// was authored against. Adjusting `BattleSpeed` values will stretch or
    /// shrink durations relative to this constant.
    static let baseAnimScale: Double = 3.2

    /// Canonical normal-speed durations that various subsystems consume.
    ///
    /// These values are kept here so that any timing tweak lives alongside
    /// the speed profile and automatically inherits user speed changes.
    static let attackNormalDuration: Double = 0.3
    static let healNormalDuration: Double = 0.18
    static let cardAnimationNormalDuration: Double = 0.3
    static let damageOverlayNormalDuration: Double = 0.6
    static let deathFadeNormalDuration: Double = 0.8

    let speed: BattleSpeed

    private var profile: SpeedProfile { speed.profile }

    /// Multiplier applied to any normal-speed duration to reach the current tempo.
    var animationScale: Double { profile.animScale / Self.baseAnimScale }

    /// Convenience for scaling a duration that was authored for normal speed.
    func duration(forNormalDuration normalDuration: Double) -> Double {
        normalDuration * animationScale
    }

    /// Delay between automatic actions while auto-battling, expressed in
    /// nanoseconds for use with `Task.sleep`.
    var tickNanoseconds: UInt64 {
        profile.tickMs * 1_000_000
    }
}

extension BattleSpeed {
    var profile: SpeedProfile {
        switch self {
        case .slow:   return .init(tickMs: 2400, animScale: 6.4)
        case .normal: return .init(tickMs: 1200, animScale: 3.2)
        case .fast:   return .init(tickMs: 600,  animScale: 1.6)
        }
    }
    var tempo: BattleTempo { BattleTempo(speed: self) }
}
