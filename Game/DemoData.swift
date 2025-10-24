//
//  DemoData.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation

struct DemoDataManager {
    /// Creates demo cards for the player team
    static func createPlayerDemoCards() -> [Card] {
        return [
            Card(name: "Iron Vanguard", house: .iron, role: .melee, hp: House.iron.statBias.hp, atk: House.iron.statBias.atk, speed: 3, energy: 4, abilities: [.taunt]),
            Card(name: "Field Medic",  house: .iron, role: .healer, hp: 6, atk: 2, speed: 2, energy: 3, abilities: [.healSmall]),
            Card(name: "Sharpshot",    house: .range, role: .ranged, hp: House.range.statBias.hp, atk: House.range.statBias.atk, speed: 4, energy: 5),
            Card(name: "Shadowblade",  house: .stealth, role: .stealth, hp: House.stealth.statBias.hp, atk: House.stealth.statBias.atk, speed: 5, energy: 4, abilities: [.stealthAtk])
        ]
    }
    
    /// Creates demo cards for the enemy team
    static func createEnemyDemoCards() -> [Card] {
        return [
            Card(name: "Bulwark",      house: .iron, role: .melee,    hp: 12, atk: 3, speed: 2, energy: 6, abilities: [.taunt]),
            Card(name: "Soul Weaver",  house: .arcana, role: .arcana, hp: 7, atk: 3, speed: 3, energy: 4, abilities: [.resurrect]),
            Card(name: "Backstabber",  house: .stealth, role: .stealth, hp: 8, atk: 4, speed: 5, energy: 8, abilities: [.stealthAtk])
        ]
    }
    
    /// Seeds a game state with demo data
    static func seedDemoGame(_ game: GameState) {
        let playerCards = createPlayerDemoCards()
        let enemyCards = createEnemyDemoCards()
        
        // Place player cards
        for (index, card) in playerCards.enumerated() {
            _ = game.field.player.place(card, at: index)
        }
        
        // Place enemy cards
        for (index, card) in enemyCards.enumerated() {
            _ = game.field.enemy.place(card, at: index)
        }
        
        game.startTurn()
    }
}
