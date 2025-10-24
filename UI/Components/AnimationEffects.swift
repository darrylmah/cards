//
//  AnimationEffects.swift
//  cards
//
//  Created by Darryl Mah on 09/27/25.
//

import SwiftUI

// MARK: - Slot frame preference (to animate cross-board attacks)
struct SlotID: Hashable {
    let isPlayerSide: Bool
    let index: Int
}

struct SlotFramesKey: PreferenceKey {
    static var defaultValue: [SlotID: Anchor<CGRect>] = [:]
    static func reduce(value: inout [SlotID: Anchor<CGRect>], nextValue: () -> [SlotID: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Animation State Manager
class BattleAnimationState: ObservableObject {
    @Published var attackPulse: Bool = false
    @Published var healPulse: Bool = false
    @Published var flyT: CGFloat = 0
    @Published var showFly: Bool = false
    @Published var shatterPulse: Bool = false
    @Published var shatterEnemyIndex: Int? = nil
    @Published var shatterPlayerIndex: Int? = nil
    
    func reset() {
        attackPulse = false
        healPulse = false
        flyT = 0
        showFly = false
        shatterPulse = false
        shatterEnemyIndex = nil
        shatterPlayerIndex = nil
    }
    
    func startAttackAnimation() {
        showFly = true
        flyT = 0
    }
    
    func startImpactAnimation() {
        attackPulse = true
    }
    
    func startHealAnimation() {
        healPulse = true
    }
    
    func startShatterAnimation(enemyIndex: Int? = nil, playerIndex: Int? = nil) {
        shatterEnemyIndex = enemyIndex
        shatterPlayerIndex = playerIndex
        shatterPulse = true
    }
}

// MARK: - Shake Effect
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        guard amount != 0 else { return ProjectionTransform(.identity) }
        let translation = amount * sin(animatableData * .pi * shakesPerUnit * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
