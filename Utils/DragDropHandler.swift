//
//  DragDropHandler.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation
import SwiftUI

struct DragDropHandler {
    static func handleDrop(
        cardId: UUID,
        to targetIndex: Int,
        pool: inout [Card],
        board: inout Board,
        energyCap: Int
    ) {
        // Check if card is from pool
        if let fromPool = pool.first(where: { $0.id == cardId }) {
            let currentEnergy = board.totalSelectedEnergy
            let existingEnergy = board.slots[targetIndex]?.energy ?? 0
            
            // Check energy constraints and duplicates
            if currentEnergy - existingEnergy + fromPool.energy > energyCap { return }
            if boardContainsCard(id: cardId, in: board) { return }
            
            // Place card on board without mutating the pool collection
            board.slots[targetIndex] = fromPool
            return
        }
        
        // Handle board-to-board moves
        if let srcIdx = indexOfCardInBoard(cardId, in: board), srcIdx != targetIndex {
            let moving = board.slots[srcIdx]
            let target = board.slots[targetIndex]
            board.slots[srcIdx] = target
            board.slots[targetIndex] = moving
        }
    }
    
    private static func indexOfCardInBoard(_ id: UUID, in board: Board) -> Int? {
        return board.slots.firstIndex { $0?.id == id }
    }
    
    private static func boardContainsCard(id: UUID, in board: Board) -> Bool {
        return board.slots.contains { $0?.id == id }
    }
}
