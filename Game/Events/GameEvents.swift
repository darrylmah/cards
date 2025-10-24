//
//  GameEvents.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation

struct AttackEvent {
    let attackerIsPlayer: Bool
    let attackerIndex: Int
    let targetIndex: Int
    let amount: Int
    let didKill: Bool
    let nonce: Int
}

struct HealEvent {
    let healerIsPlayer: Bool
    let targetIndex: Int
    let amount: Int
    let nonce: Int
}
