//
//  BoardViews.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//
// arranges many slots + battle-only overlays/animations.


import SwiftUI


struct BoardView: View {
    let title: String
    let board: Board
    let isPlayerSide: Bool
    let highlight: [Int]
    let attackingIndex: Int?
    let attackDirection: CGFloat
    let hitIndex: Int?
    let hitText: String?
    let attackPulse: Bool
    let shakePulse: Bool
    let healIndex: Int?
    let healText: String?
    let healPulse: Bool
    let hideIndexDuringFlight: Int?
    let shatterIndex: Int?
    let shatterPulse: Bool
    let shatterNonce: Int
    let onSelect: (Int) -> Void
    let cardSize: CGSize
    let durationScale: Double


    @State private var shatterFlags: [Bool] = Array(repeating: false, count: Board.maxSlots)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title removed to maximize space
            let columns = Array(repeating: GridItem(.fixed(cardSize.width), spacing: 8, alignment: .center), count: 4)
            LazyVGrid(columns: columns, alignment: .center, spacing: 8) {
                ForEach(Array(0..<Board.maxSlots) as [Int], id: \.self) { (idx: Int) in
                    // For defending board (enemy), reverse the display order
                    let displayIndex = isPlayerSide ? idx : (Board.maxSlots - 1 - idx)
                    let card = board.slots[displayIndex]
                    let isDefender = (hitIndex == displayIndex)
                    let isHealed   = (healIndex == displayIndex)
                    let hideForFlight = (hideIndexDuringFlight == displayIndex)
                    let isShattered = (shatterIndex == displayIndex)

                    let shatterTrigger = Binding<Bool>(
                        get: { shatterFlags[displayIndex] },
                        set: { shatterFlags[displayIndex] = $0 }
                    )

                    ZStack(alignment: .center) {
                        CardSlotView(
                            card: card,
                            index: displayIndex,
                            isHighlighted: highlight.contains(idx),
                            isPlayerSide: isPlayerSide,
                            onTap: { onSelect(displayIndex) },
                            size: cardSize
                        )
                        .opacity(hideForFlight ? 0 : 1)
                        .modifier(
                            ShakeEffect(
                                amount: (isDefender && shakePulse && !reduceMotion) ? 8 : 0,
                                animatableData: (isDefender && shakePulse && !reduceMotion) ? 1 : 0
                            )
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .animation(.easeInOut(duration: 0.3 * durationScale), value: card)

                        DamageOverlay(
                            text: hitText ?? "-",
                            isHeal: false,
                            cardSize: cardSize,
                            isVisible: isDefender && shakePulse,
                            durationScale: durationScale
                        )

                        DamageOverlay(
                            text: healText ?? "+",
                            isHeal: true,
                            cardSize: cardSize,
                            isVisible: isHealed && healPulse,
                            durationScale: durationScale
                        )

                        if isShattered {
                            DeathAnimation(
                                isDying: shatterTrigger,
                                durationScale: durationScale
                            )
                            .frame(width: cardSize.width, height: cardSize.height)
                            .zIndex(2)
                            .allowsHitTesting(false)
                        }
                    }
                    .anchorPreference(key: SlotFramesKey.self, value: .bounds) { anchor in
                        [SlotID(isPlayerSide: isPlayerSide, index: displayIndex): anchor]
                    }
                    #if os(iOS)
                    .onChange(of: shatterNonce) { _ in
                        if isShattered && shatterPulse {
                            shatterFlags[idx] = true
                        }
                    }
                    #else
                    .onChange(of: shatterNonce, initial: false) { _, _ in
                        if isShattered && shatterPulse { shatterFlags[idx] = true}
                    }
                    #endif
                    #if os(iOS)
                    .onChange(of: shatterPulse) { newValue in
                        if newValue && isShattered {
                            shatterFlags[idx] = true
                        }
                    }
                    #else
                    .onChange(of: shatterPulse, initial: false) { _, newValue in
                        if newValue && isShattered {
                            shatterFlags[idx] = true
                        }
                    }
                    #endif
                }
            }
        }
    }
}
