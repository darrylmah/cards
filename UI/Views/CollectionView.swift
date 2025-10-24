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
            let hPad: CGFloat = 16
            let spacing: CGFloat = 8
            let cols = [GridItem(.flexible(), spacing: spacing),
                        GridItem(.flexible(), spacing: spacing),
                        GridItem(.flexible(), spacing: spacing)]
            let cardW = (geo.size.width - hPad*2 - spacing*2) / 3
            let cardH = cardW * 1.27

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
