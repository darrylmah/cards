//
//  CardView.swift
//  cards
//
//  Created by Darryl Mah on 10/15/25.
//
// how a card face looks (icons, text, colors).

import SwiftUI

struct CardView: View {
    let card: Card
    let size: CGSize

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(radius: 3)

            VStack(spacing: 6) {
                // Name
                Text(card.name)
                    .font(.caption).bold().lineLimit(1)

                // House + Role
                Text("\(card.house.displayName) • \(card.role.rawValue.capitalized)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Stats row
                HStack {
                    Label("\(card.atk)", systemImage: "flame.fill")
                    Label("\(max(card.hp, 0))", systemImage: "heart.fill")
                }
                .font(.caption2)
                .labelStyle(.titleAndIcon)

                HStack {
                    Label("\(card.speed)", systemImage: "gauge")
                    Label("\(card.energy)", systemImage: "bolt.horizontal")
                }
                .font(.caption2)
                .labelStyle(.titleAndIcon)

                // Ability tags
                if card.abilities.contains(.taunt) { Tag("Taunt") }
                if card.abilities.contains(.healSmall) { Tag("Heal") }
                if card.abilities.contains(.resurrect) { Tag("Rez") }
                if card.abilities.contains(.stealthAtk) { Tag("Stealth") }

                // Exhausted marker
                if card.exhausted {
                    Text("Exhausted")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 6)
        }
        .frame(width: size.width, height: size.height)
    }
}
