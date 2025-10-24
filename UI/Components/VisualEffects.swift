//
//  VisualEffects.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import SwiftUI

// MARK: - Death Animation (simple fade out)
struct DeathAnimation: View {
    @Binding var isDying: Bool
    let tempo: BattleTempo
    @State private var opacity: CGFloat = 1
    
    private var duration: Double { tempo.duration(forNormalDuration: BattleTempo.deathFadeNormalDuration) }

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.red.opacity(0.8))
            .opacity(opacity)
            .allowsHitTesting(false)
            .onChange(of: isDying) { newValue in
                guard newValue else { return }
                withAnimation(.easeOut(duration: duration)) { 
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    opacity = 1
                    isDying = false
                }
            }
    }
}

