//
//  HomeView.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import SwiftUI

struct HomeView: View {
    let collectionCount: Int
    var onOpenCollection: () -> Void
    var onInitiate: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Arcane Arena").font(.largeTitle).bold()
            Text("Welcome back! Build your formation, then auto-battle.")
                .font(.subheadline).foregroundStyle(.secondary)

            HStack(spacing: 24) {
                VStack { Text("Wins").font(.caption); Text("0").bold() }
                VStack { Text("Losses").font(.caption); Text("0").bold() }
                Button(action: onOpenCollection) {
                    VStack { Text("Collection").font(.caption); Text("\(collectionCount) cards").bold() }
                }.buttonStyle(.plain)
            }

            Button("Initiate Battle") { onInitiate() }
                .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
    }
}
