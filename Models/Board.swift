//
//  Board.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation

/// Linear 8-slot front-to-back board. Index 0 is front line.
struct Board: Codable {
    static let maxSlots: Int = 8
    var slots: [Card?] = Array(repeating: nil, count: maxSlots)

    mutating func place(_ card: Card, at index: Int) -> Bool {
        guard (0..<Board.maxSlots).contains(index), slots[index] == nil else { return false }
        slots[index] = card
        return true
    }

    mutating func autoSlide() {
        let alive = slots.compactMap { $0 }.filter { $0.isAlive }
        var newSlots: [Card?] = Array(repeating: nil, count: Board.maxSlots)
        for (i, c) in alive.enumerated() where i < Board.maxSlots { newSlots[i] = c }
        slots = newSlots
    }

    var frontIndex: Int? { slots.firstIndex(where: { $0 != nil }) }
    var hasTauntFront: Bool {
        return slots.contains(where: { $0?.isAlive == true && $0!.abilities.contains(.taunt) })
    }
    var tauntIndices: [Int] {
        slots.enumerated().compactMap { i, c in
            (c?.isAlive == true && c!.abilities.contains(.taunt)) ? i : nil
        }
    }
    var aliveIndices: [Int] {
        slots.enumerated().compactMap { i, c in c?.isAlive == true ? i : nil }
    }
    mutating func updateCard(_ card: Card, at index: Int) {
        guard (0..<Board.maxSlots).contains(index) else { return }
        slots[index] = card
    }
}

extension Board {
    var firstEmptyIndex: Int? { slots.firstIndex(where: { $0 == nil }) }
    var isDefeated: Bool { slots.compactMap { $0 }.allSatisfy { $0.hp <= 0 } || slots.compactMap { $0 }.isEmpty }
    var totalSelectedEnergy: Int { slots.compactMap { $0?.energy }.reduce(0, +) }
}

struct Battlefield: Codable {
    var player = Board()
    var enemy  = Board()
    mutating func autoSlideAll() { player.autoSlide(); enemy.autoSlide() }
}
