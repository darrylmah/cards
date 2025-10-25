//
//  CollectionView.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//
// shows your whole collection as a grid of CardView tiles (no slot chrome).

import SwiftUI

struct CollectionView: View {
    let cards: [Card]
    var onHome: () -> Void

    var body: some View {
        GeometryReader { geo in
            let hPad: CGFloat = BattleLayout.outerPadding
            let spacing: CGFloat = BattleLayout.gridSpacing
            let cols = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3)
            let cardColumns: CGFloat = 3
            let cardW = (geo.size.width - hPad * 2 - spacing * (cardColumns - 1)) / cardColumns
            let cardH = cardW * BattleLayout.cardAspectRatio

            VStack(spacing: 12) {
                HStack {
                    Button { onHome() } label: { Label("Home", systemImage: "house.fill") }
                        .buttonStyle(.bordered)
                    Spacer()
                }
                .padding(.horizontal, hPad)

                Text("Your Collection").font(.headline)

                ScrollView {
                    LazyVGrid(columns: cols, spacing: spacing) {
                        ForEach(cards) { card in
                            CardView(card: card, size: .init(width: cardW, height: cardH))
                        }
                    }
                    .padding(.horizontal, hPad)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.top, 8)
    }
}
