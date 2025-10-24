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
        Button(action: { if isPlayerSide, card != nil { onTap() } }) {
            ZStack {
                if let c = card {
                    CardView(card: c, size: size)
                } else {
                    // Empty placeholder with consistent frame
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.secondary, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.ultraThinMaterial)
                        )
                        .frame(width: size.width, height: size.height)

                    Text("Empty")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .frame(minWidth: size.width, minHeight: size.height)
        // Highlight border
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isHighlighted ? .yellow : .clear, lineWidth: 3)
        )
        .disabled(card == nil)
    }
}

