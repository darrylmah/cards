//
//  CardDetailSheet.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import SwiftUI

struct CardDetailSheet: View, Identifiable {
    let id = UUID()
    let card: Card
    
    var body: some View {
        VStack(spacing: 16) {
            Text(card.name).font(.title2).bold()
            CardView(card: card, size: .init(width: 220, height: 300))
            VStack(alignment: .leading, spacing: 8) {
                Label("HP: \(card.hp)/\(card.maxHP ?? card.hp)", systemImage: "heart.fill")
                Label("ATK: \(card.atk)", systemImage: "flame.fill")
                Label("Speed: \(card.speed)", systemImage: "gauge")
                Label("Energy: \(card.energy)", systemImage: "bolt.fill")
                Text("House: \(card.house.displayName)")
                Text("Role: \(card.role.rawValue.capitalized)")
                if !card.abilities.isEmpty { Text("Abilities: \(card.abilities)") }
            }
            .font(.body)
            .padding()
            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}