//
//  Abilities.swift
//  cards
//
//  Created by Darryl Mah on 10/9/25.
//

import Foundation

struct Ability: OptionSet, Codable {
    let rawValue: Int

    // Core abilities (existing)
    static let taunt        = Ability(rawValue: 1 << 0)
    static let healSmall    = Ability(rawValue: 1 << 1)
    static let resurrect    = Ability(rawValue: 1 << 2)
    static let stealthAtk   = Ability(rawValue: 1 << 3)

    // New abilities for battle logic
    static let frontlineRanged = Ability(rawValue: 1 << 4)
    static let splashDamage    = Ability(rawValue: 1 << 5)
    static let lifesteal       = Ability(rawValue: 1 << 6)

    // You can also define categories here later:
    static let offensive: [Ability] = [.stealthAtk, .frontlineRanged, .splashDamage, .lifesteal]
    static let support: [Ability]   = [.healSmall, .resurrect]
}
