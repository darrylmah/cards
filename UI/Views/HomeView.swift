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
            
            HStack(spacing: 12) {
                CurrencyBadge(icon: "💎", name: "Gems", amount: 240)
                CurrencyBadge(icon: "🪙", name: "Gold", amount: 1_250)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 24) {
                VStack { Text("Wins").font(.caption); Text("0").bold() }
                VStack { Text("Losses").font(.caption); Text("0").bold() }
                VStack { Text("Streak").font(.caption); Text("3").bold() }
            }

            Button("Initiate Battle") { onInitiate() }
                .buttonStyle(.borderedProminent)
            
            Spacer()
            
            VStack(spacing: 8) {
                Divider()
                HStack(spacing: 16) {
                    TabButton(title: "Shop", systemImage: "cart") {}
                    TabButton(title: "History", systemImage: "clock.arrow.circlepath") {}
                    Button(action: {}) {
                        Label("Home", systemImage: "house.fill")
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    TabButton(title: "Collection", systemImage: "rectangle.stack", subtitle: "\(collectionCount) cards") { onOpenCollection() }
                    TabButton(title: "Market", systemImage: "building.columns") {}
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
    }
}

private struct CurrencyBadge: View {
    let icon: String
    let name: String
    let amount: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.caption).foregroundStyle(.secondary)
                Text("\(amount)").font(.headline).bold()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct TabButton: View {
    let title: String
    let systemImage: String
    var subtitle: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title).font(.caption)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}
