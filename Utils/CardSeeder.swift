//
//  CardSeeder.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation

struct CardSeeder {
    /// Creates the initial pool of cards for team building
    static func createPool() -> [Card] {
        return [
            Card(name: "Iron Vanguard", house: .iron, role: .melee,   hp: 12, atk: 3, speed: 3, energy: 3, abilities: [.taunt]),
            Card(name: "Field Medic",  house: .iron, role: .healer, hp: 6,  atk: 2, speed: 2, energy: 2, abilities: [.healSmall]),
            Card(name: "Sharpshot",    house: .range, role: .ranged, hp: 7,  atk: 5, speed: 4, energy: 3),
            Card(name: "Shadowblade",  house: .stealth, role: .stealth, hp: 8, atk: 4, speed: 5, energy: 3, abilities: [.stealthAtk]),
            Card(name: "Soul Stitcher",house: .arcana, role: .arcana, hp: 7,  atk: 3, speed: 3, energy: 4, abilities: [.resurrect])
        ]
    }
    
    /// Creates the initial collection of cards
    static func createCollection() -> [Card] {
        return createPool() // Same cards for now
    }
}