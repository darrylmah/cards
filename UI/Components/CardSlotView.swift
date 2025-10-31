//
//  CardSlotView.swift
//  cards
//
//  Created by Darryl Mah on 10/15/25.
//
// a slot wrapper (button tap, highlight ring, #index badge, empty-state frame)

import SwiftUI

struct CardSlotView: View {
    let card: Card?
    let index: Int
    let isHighlighted: Bool
    let isPlayerSide: Bool
    let onTap: () -> Void
    let size: CGSize

    var body: some View {
        ZStack {
            if let c = card {
                CardView(card: c, size: size)
            } else {
                // Empty placeholder with consistent frame
                RoundedRectangle(cornerRadius: BattleLayout.cardCornerRadius)
                    .strokeBorder(.secondary, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: BattleLayout.cardCornerRadius)
                            .fill(.ultraThinMaterial)
                    )
                    .frame(width: size.width, height: size.height)

                Text("Empty")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(RoundedRectangle(cornerRadius: BattleLayout.cardCornerRadius))
        .onTapGesture {
            if isPlayerSide, card != nil { onTap() }
        }
        // Highlight border
        .overlay(
            RoundedRectangle(cornerRadius: BattleLayout.cardCornerRadius)
                .strokeBorder(isHighlighted ? .yellow : .clear, lineWidth: BattleLayout.cardHighlightLineWidth)
        )
    }
}

