//
//  CombatSystem.swift
//  cards
//
//  Created by Darryl Mah on 10/9/25.
//

import Foundation

struct CombatEvent {
    enum Kind { case hit(damage: Int), heal(amount: Int), resurrect(name: String) }
    let kind: Kind
    let attackerIsPlayer: Bool
    let attackerIndex: Int
    let targetIndex: Int
}

struct CombatSystem {
    // Returns (updatedAttackerBoard, updatedDefenderBoard, event, logLine)
    static func performAttack(
        attackerBoard: Board,
        defenderBoard: Board,
        attackerIndex: Int,
        attackerIsPlayer: Bool
    ) -> (Board, Board, CombatEvent?, String?) {
        var atk = attackerBoard
        var def = defenderBoard

        guard (0..<Board.maxSlots).contains(attackerIndex),
              var attacker = atk.slots[attackerIndex],
              attacker.isAlive, attacker.exhausted == false, attacker.energy > 0 else {
            return (atk, def, nil, nil)
        }

        // Attacker must already have a chosen legal target (GameState uses Targeting to pick it).
        // So let’s not pick here — just apply. Caller should have validated.
        // This function only needs targetIndex; leave selection to GameState.
        fatalError("Use performAttackWithTarget if you want to apply to a known target.")
    }

    static func performAttackWithTarget(
        attackerBoard: Board,
        defenderBoard: Board,
        attackerIndex: Int,
        targetIndex: Int,
        attackerIsPlayer: Bool
    ) -> (Board, Board, CombatEvent?, String?) {
        var atk = attackerBoard
        var def = defenderBoard

        guard (0..<Board.maxSlots).contains(attackerIndex),
              var attacker = atk.slots[attackerIndex],
              attacker.isAlive, attacker.exhausted == false, attacker.energy > 0 else {
            return (atk, def, nil, nil)
        }
        guard (0..<Board.maxSlots).contains(targetIndex),
              var defender = def.slots[targetIndex],
              defender.isAlive else {
            return (atk, def, nil, nil)
        }

        defender.hp -= attacker.atk
        attacker.exhausted = true
        atk.slots[attackerIndex] = attacker
        def.slots[targetIndex]  = defender

        let evt = CombatEvent(kind: .hit(damage: attacker.atk),
                              attackerIsPlayer: attackerIsPlayer,
                              attackerIndex: attackerIndex,
                              targetIndex: targetIndex)
        let log = "\(attackerIsPlayer ? "[P]" : "[E]") \(attacker.name) hits \(attackerIsPlayer ? "[E]" : "[P]") \(defender.name) for \(attacker.atk)."
        return (atk, def, evt, log)
    }

    static func performHeal(
        board: Board,
        healerIndex: Int,
        targetIndex: Int,
        isPlayerSide: Bool
        ) -> (Board, CombatEvent?, String?) {
        var b = board
        guard (0..<Board.maxSlots).contains(healerIndex),
              var healer = b.slots[healerIndex],
              healer.isAlive, healer.exhausted == false,
              (healer.role == .healer || healer.abilities.contains(.healSmall)) else {
            return (b, nil, nil)
        }

        guard (0..<Board.maxSlots).contains(targetIndex),
              var ally = b.slots[targetIndex],
              ally.isAlive else { return (b, nil, nil) }

        let amount = max(1, healer.atk)
        let cap = ally.maxHP ?? ally.hp
        ally.hp = min(ally.hp + amount, cap)
        healer.exhausted = true
        b.slots[targetIndex] = ally
        b.slots[healerIndex] = healer

        let evt = CombatEvent(kind: .heal(amount: amount),
                              attackerIsPlayer: isPlayerSide,
                              attackerIndex: healerIndex,
                              targetIndex: targetIndex)
        let log = "\(isPlayerSide ? "[P]" : "[E]") \(healer.name) heals \(ally.name) +\(amount)."
        return (b, evt, log)
    }

    static func performResurrect(
        board: Board,
        casterIndex: Int,
        isPlayerSide: Bool
    ) -> (Board, CombatEvent?, String?) {
        var b = board
        guard (0..<Board.maxSlots).contains(casterIndex),
              var caster = b.slots[casterIndex],
              caster.isAlive, caster.exhausted == false,
              caster.abilities.contains(.resurrect) else { return (b, nil, nil) }

        var log: String?
        if let deadIndex = (0..<Board.maxSlots).first(where: { i in
            if let c = b.slots[i] { return c.hp <= 0 } else { return false }
        }) {
            if var dead = b.slots[deadIndex] {
                dead.hp = 1
                b.slots[deadIndex] = dead
                caster.exhausted = true
                log = "\(isPlayerSide ? "[P]" : "[E]") \(caster.name) resurrects \(dead.name) to 1 HP."
            }
        } else if let empty = (0..<Board.maxSlots).last(where: { b.slots[$0] == nil }) {
            let token = Card(name: "Arcane Shade", house: .arcana, role: .arcana, hp: 1, atk: 2, speed: 2, energy: 3)
            _ = b.place(token, at: empty)
            caster.exhausted = true
            log = "\(isPlayerSide ? "[P]" : "[E]") \(caster.name) summons an Arcane Shade."
        }
        b.slots[casterIndex] = caster
        let evt = CombatEvent(kind: .resurrect(name: "Arcane Shade"),
                              attackerIsPlayer: isPlayerSide,
                              attackerIndex: casterIndex,
                              targetIndex: -1)
        return (b, evt, log)
    }
}
