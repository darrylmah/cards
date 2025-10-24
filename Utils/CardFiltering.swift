//
//  CardFiltering.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation

struct CardFiltering {
    enum SortKey: String, CaseIterable { 
        case energyAsc, energyDesc, atkDesc, hpDesc, speedDesc 
    }
    
    static func filterAndSort(
        cards: [Card],
        searchText: String,
        selectedRole: Role?,
        selectedHouse: House?,
        sortKey: SortKey
    ) -> [Card] {
        var filteredCards = cards
        
        // Filter by search text
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filteredCards = filteredCards.filter { card in
                card.name.lowercased().contains(query) ||
                card.house.displayName.lowercased().contains(query) ||
                card.role.rawValue.lowercased().contains(query)
            }
        }
        
        // Filter by role
        if let role = selectedRole {
            filteredCards = filteredCards.filter { $0.role == role }
        }
        
        // Filter by house
        if let house = selectedHouse {
            filteredCards = filteredCards.filter { $0.house == house }
        }
        
        // Sort
        switch sortKey {
        case .energyAsc:  filteredCards.sort { $0.energy < $1.energy }
        case .energyDesc: filteredCards.sort { $0.energy > $1.energy }
        case .atkDesc:    filteredCards.sort { $0.atk > $1.atk }
        case .hpDesc:     filteredCards.sort { $0.hp > $1.hp }
        case .speedDesc:  filteredCards.sort { $0.speed > $1.speed }
        }
        
        return filteredCards
    }
}
