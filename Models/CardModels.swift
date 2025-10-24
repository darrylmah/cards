//
//  CardModels.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation

enum House: String, Codable, CaseIterable, Identifiable {
    case iron, range, stealth, arcana
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .iron: return "Iron"
        case .range: return "Range"
        case .stealth: return "Stealth"
        case .arcana: return "Arcana"
        }
    }
    var statBias: (hp: Int, atk: Int) {
        switch self {
        case .iron:   return (hp: 12, atk: 3)
        case .range:  return (hp: 7,  atk: 5)
        case .stealth:return (hp: 8,  atk: 4)
        case .arcana: return (hp: 7,  atk: 3)
        }
    }
}

enum Role: String, Codable, CaseIterable { case melee, healer, ranged, stealth, arcana }

struct Card: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let house: House
    let role: Role
    var hp: Int
    var maxHP: Int?
    var atk: Int
    var speed: Int
    var energy: Int        // deck-building cost, not consumed during battle
    var abilities: Ability = []
    var exhausted: Bool = false
    var isAlive: Bool { hp > 0 }

    init(
        id: UUID = UUID(),
        name: String,
        house: House,
        role: Role,
        hp: Int,
        maxHP: Int? = nil,
        atk: Int,
        speed: Int,
        energy: Int,
        abilities: Ability = [],
        exhausted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.house = house
        self.role = role
        self.hp = hp
        self.maxHP = maxHP ?? hp
        self.atk = atk
        self.speed = speed
        self.energy = energy
        self.abilities = abilities
        self.exhausted = exhausted
    }
}
