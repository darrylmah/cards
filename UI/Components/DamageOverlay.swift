//
//  DamageOverlay.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import SwiftUI

struct DamageOverlay: View {
    let text: String
    let isHeal: Bool
    let cardSize: CGSize
    let isVisible: Bool
    let durationScale: Double
    
    @State private var floatT: CGFloat = 0

    private var fontSize: CGFloat { max(CGFloat(16), min(cardSize.width * CGFloat(0.22), CGFloat(28))) }
    // Travel nearly to the card edge from center
    private var floatDistance: CGFloat { max(CGFloat(10), cardSize.height * CGFloat(0.48)) }

    // Breaking damage/heal badges into it's own view to help type-checker
    @ViewBuilder
    private var badge: some View {
        // Triangle bump factor 0→1→0
        let tri: CGFloat = 1 - abs(1 - 2 * floatT)
        let bump: CGFloat = 0.04 * tri
        // Damage drifts downward, heal drifts upward
        let yOffset: CGFloat = (isHeal ? -1 : 1) * floatDistance * floatT
        let badgeFont = Font.system(size: fontSize, weight: .heavy, design: .rounded)

        Text(text)
            .font(badgeFont)
            .foregroundColor(isHeal ? Color.green : Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    Circle()
                        .fill(Color(isHeal ? .green : .red).opacity(0.25))
                        .scaleEffect(1.25)
                    Capsule().fill(.ultraThinMaterial)
                }
            )
            .overlay(
                Capsule()
                    .strokeBorder(isHeal ? Color.green.opacity(0.85) : Color.red.opacity(0.95), lineWidth: 2)
            )
            .shadow(radius: 6)
            .frame(width: cardSize.width, height: cardSize.height, alignment: .center)
            .offset(y: yOffset)
            .scaleEffect(CGFloat(1) + bump)
            .opacity(CGFloat(1) - CGFloat(0.85) * floatT)
            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            .allowsHitTesting(false)
    }

    var body: some View {
        ZStack {
            if isVisible { badge }
        }
        .onChange(of: isVisible) { newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.6 * durationScale)) {
                    floatT = 1
                }
            } else {
                floatT = 0
            }
        }
        .onAppear {
            if isVisible {
                withAnimation(.easeOut(duration: 0.6 * durationScale)) {
                    floatT = 1
                }
            }
        }
    }
}
