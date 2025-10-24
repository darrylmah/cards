//
//  BattleControls.swift
//  cards
//
//  Created by Darryl Mah on 09/27/25.
//

import SwiftUI

struct BattleControls: View {
    @ObservedObject var game: GameState
    
    var body: some View {
        HStack(spacing: 8) {
            let speedBinding = Binding<BattleSpeed>(
                get: { game.speed }, 
                set: { game.setSpeed($0) }
            )
            
            Picker("Speed", selection: speedBinding) {
                Text("Slow").tag(BattleSpeed.slow)
                Text("Normal").tag(BattleSpeed.normal)
                Text("Fast").tag(BattleSpeed.fast)
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 4)
    }
}

struct BattleEndControls: View {
    let onReplay: () -> Void
    let onHome: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button("Replay") { onReplay() }
                .buttonStyle(.borderedProminent)
            Button("Home") { onHome() }
                .buttonStyle(.bordered)
        }
    }
}
