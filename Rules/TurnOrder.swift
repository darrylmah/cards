//
//  TurnOrder.swift
//  cards
//
//  Created by Darryl Mah on 10/7/25.
//

import Foundation

protocol TurnOrder {
    /// Order a single board's indices (back-compat; still used in tests if needed)
    func order(indices: [Int], in board: Board, seed: UInt64?) -> [Int]

    /// Order all alive actors across BOTH sides, returning (isPlayerSide, slotIndex)
    func combinedOrder(player: Board, enemy: Board, seed: UInt64?) -> [(isPlayer: Bool, index: Int)]
}

/// Speed desc → Energy desc → deterministic coin flip → index asc
struct DefaultTurnOrder: TurnOrder {
    func order(indices: [Int],
               in board: Board,
               seed: UInt64?) -> [Int] {
        // deterministic tiebreaker; if you want seeded, fold the seed in here
        var tiebreak: [Int:Int] = [:]
        for i in indices {
            if let c = board.slots[i] {
                tiebreak[i] = abs(c.id.uuidString.hashValue) & 0xFFFF
            }
        }
        return indices.sorted { a, b in
            guard let ca = board.slots[a], let cb = board.slots[b] else { return a < b }
            if ca.speed != cb.speed { return ca.speed > cb.speed }
            if ca.energy != cb.energy { return ca.energy > cb.energy }
            let ta = tiebreak[a] ?? 0, tb = tiebreak[b] ?? 0
            if ta != tb { return ta > tb }
            return a < b
        }
    }

    func combinedOrder(player: Board, enemy: Board, seed: UInt64?) -> [(isPlayer: Bool, index: Int)] {
        struct Entry { let isPlayer: Bool; let index: Int; let speed: Int; let energy: Int; let tie: Int }
        var entries: [Entry] = []

        func tieFor(_ c: Card, seed: UInt64?) -> Int {
            if let s = seed {
                let h = c.id.uuidString.hashValue
                let combined = s ^ UInt64(bitPattern: Int64(h))
                return Int(truncatingIfNeeded: combined & 0xFFFF)
            } else {
                return abs(c.id.uuidString.hashValue) & 0xFFFF
            }
        }

        for i in 0..<Board.maxSlots {
            if let c = player.slots[i], c.isAlive { entries.append(.init(isPlayer: true, index: i, speed: c.speed, energy: c.energy, tie: tieFor(c, seed: seed))) }
            if let c = enemy.slots[i],  c.isAlive { entries.append(.init(isPlayer: false, index: i, speed: c.speed, energy: c.energy, tie: tieFor(c, seed: seed))) }
        }

        let sorted = entries.sorted { a, b in
            if a.speed != b.speed { return a.speed > b.speed }
            if a.energy != b.energy { return a.energy > b.energy }
            if a.tie != b.tie { return a.tie > b.tie }
            // stable final fallback: player first, then lower slot index
            if a.isPlayer != b.isPlayer { return a.isPlayer && !b.isPlayer }
            return a.index < b.index
        }
        return sorted.map { ($0.isPlayer, $0.index) }
    }
}
