//
//  Targeting.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation

enum TargetingRule {
    case defaultFront
    case stealthBackOrSecond
    case tauntOverride
}

struct TargetingContext {
    let attacker: Card
    let attackerIndex: Int
    let attackerSideIsPlayer: Bool
    let battlefield: Battlefield

    func validTargets() -> [Int] {
        let defenderBoard = attackerSideIsPlayer ? battlefield.enemy : battlefield.player

        // Front-position rule: slot 0 always targets defender's slot 0
        // Exception: ranged units cannot attack from slot 0 unless granted by a specific ability (to be added)
        if attackerIndex == 0 {
            // TODO: When you add an ability like `.frontlineRanged`, allow it here instead of blocking.
            // Ranged can't attack from slot 0 unless granted the ability
            if attacker.role == .ranged && !attacker.abilities.contains(.frontlineRanged) {
                return []
            }
            if defenderBoard.slots.indices.contains(0), let c = defenderBoard.slots[0], c.isAlive {
                return [0]
            } else {
                return []
            }
        }

        
        // Non-Front Rules
        // Melee units cannot attack from non-front postions unless they have stealthAtk.
        
        if attacker.role == .melee && !attacker.abilities.contains(.stealthAtk) {
            return []
        }
        
        // Taunt override
        if defenderBoard.hasTauntFront { return defenderBoard.tauntIndices }

        // Stealth attacking from non-front: target the LAST alive enemy slot only
        if attacker.abilities.contains(.stealthAtk) {
            let alive = defenderBoard.aliveIndices
            guard let last = alive.last else { return [] }
            return [last]
        }
        
        // Default: target the front-most alive enemy
        if let front = defenderBoard.frontIndex { return [front] }
        return []
    }
}

// MARK: - Friendly heal targeting
extension TargetingContext {
    /// Returns ally indices that are valid heal recipients (alive and missing HP).
    func validHealTargets() -> [Int] {
        let allyBoard = attackerSideIsPlayer ? battlefield.player : battlefield.enemy
        return allyBoard.slots.enumerated()
            .compactMap { (i, c) in
                guard let c = c, c.isAlive else { return nil }
                let cap = c.maxHP ?? c.hp
                return c.hp < cap ? i : nil
            }
    }

    /// Pick the ally to heal. Default behavior: lowest HP ratio, then lowest absolute HP, then lowest index.
    func pickHealTargetIndex() -> Int? {
        let allyBoard = attackerSideIsPlayer ? battlefield.player : battlefield.enemy
        let candidates = validHealTargets()
        guard !candidates.isEmpty else { return nil }
        return candidates.min { lhs, rhs in
            let a = allyBoard.slots[lhs]!; let b = allyBoard.slots[rhs]!
            let aCap = a.maxHP ?? a.hp
            let bCap = b.maxHP ?? b.hp
            let aRatio = Double(a.hp) / Double(max(1, aCap))
            let bRatio = Double(b.hp) / Double(max(1, bCap))
            if aRatio != bRatio { return aRatio < bRatio }
            if a.hp != b.hp { return a.hp < b.hp }
            return lhs < rhs
        }
    }
}
