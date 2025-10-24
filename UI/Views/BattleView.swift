//
//  BattleView.swift
//  cards
//
//  Created by Darryl Mah on 09/27/25.
//

import SwiftUI


struct BattleView: View {
    @ObservedObject var game: GameState
    var onReplay: () -> Void
    var onHome: () -> Void
    var onNewGame: () -> Void

    var body: some View {
        GeometryReader { geo in
            let size = BattleLayout.computeCardSize(containerWidth: geo.size.width)
            BattleBoardsView(
                game: game,
                cardSize: size,
                onReplay: onReplay,
                onHome: onHome,
                onNewGame: onNewGame
            )
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }
}

struct BattleBoardsView: View {
    @ObservedObject var game: GameState
    @State private var shatterNonce = 0
    let cardSize: CGSize
    let onReplay: () -> Void
    let onHome: () -> Void
    let onNewGame: () -> Void

    @StateObject private var animationState = BattleAnimationState()

    private func dur(_ normal: Double) -> Double {
        game.tempo.duration(forNormalDuration: normal)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Spacer(minLength: 10) // top breathing room below Dynamic Island

            // Enemy board first
            let atk = game.lastAttack
            let heal = game.lastHeal

            let enemyHitText: String? = {
                guard let a = atk, a.attackerIsPlayer else { return nil }
                let dmg = game.field.player.slots[a.attackerIndex]?.atk ?? 0
                return "-\(dmg)"
            }()
            BoardView(
                title: "Enemy",
                board: game.field.enemy,
                isPlayerSide: false,
                highlight: [],
                attackingIndex: (atk?.attackerIsPlayer == false ? atk?.attackerIndex : nil),
                attackDirection: 0,
                hitIndex: (atk?.attackerIsPlayer == true ? atk?.targetIndex : nil),
                hitText: enemyHitText,
                attackPulse: animationState.attackPulse,
                shakePulse: animationState.attackPulse,
                healIndex: (heal?.healerIsPlayer == false ? heal?.targetIndex : nil),
                healText: (heal?.healerIsPlayer == false ? heal.map { "+\($0.amount)" } : nil),
                healPulse: animationState.healPulse,
                hideIndexDuringFlight: (animationState.showFly && (atk?.attackerIsPlayer == false) ? atk?.attackerIndex : nil),
                shatterIndex: animationState.shatterEnemyIndex,
                shatterPulse: animationState.shatterPulse,
                shatterNonce: shatterNonce,
                onSelect: { _ in },
                cardSize: cardSize,
                tempo: game.tempo
            )

            Divider().padding(.vertical, 4)

            // Controls between boards
            BattleControls(game: game)

            // Player board
            let playerHitText: String? = {
                guard let a = atk, a.attackerIsPlayer == false else { return nil }
                let dmg = game.field.enemy.slots[a.attackerIndex]?.atk ?? 0
                return "-\(dmg)"
            }()
            BoardView(
                title: "Player",
                board: game.field.player,
                isPlayerSide: true,
                highlight: (game.currentActor.map { [$0.index] } ?? []),
                attackingIndex: (atk?.attackerIsPlayer == true ? atk?.attackerIndex : nil),
                attackDirection: 0,
                hitIndex: (atk?.attackerIsPlayer == false ? atk?.targetIndex : nil),
                hitText: playerHitText,
                attackPulse: animationState.attackPulse,
                shakePulse: animationState.attackPulse,
                healIndex: (heal?.healerIsPlayer == true ? heal?.targetIndex : nil),
                healText: (heal?.healerIsPlayer == true ? heal.map { "+\($0.amount)" } : nil),
                healPulse: animationState.healPulse,
                hideIndexDuringFlight: (animationState.showFly && (atk?.attackerIsPlayer == true) ? atk?.attackerIndex : nil),
                shatterIndex: animationState.shatterPlayerIndex,
                shatterPulse: animationState.shatterPulse,
                shatterNonce: shatterNonce,
                onSelect: { _ in },
                cardSize: cardSize,
                tempo: game.tempo
            )

            Spacer(minLength: 8)
            let finished = game.field.enemy.isDefeated || game.field.player.isDefeated
            if finished {
                BattleEndControls(onReplay: onReplay, onHome: onHome)
            } else {
                // Show pause/skip controls at bottom when game is active
                HStack(spacing: 8) {
                    Button("Skip") { 
                        game.skipToEnd() 
                    }
                    .buttonStyle(.bordered)
                    
                    if game.isPaused {
                        // When paused, show step controls
                        Button("Resume") { 
                            game.resume() 
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Step →") { 
                            game.stepForward() 
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Step ←") { 
                            game.stepBackward() 
                        }
                        .buttonStyle(.bordered)
                    } else {
                        // When running, show pause button
                        Button("Pause") { 
                            game.pauseAfterCurrent() 
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer(minLength: 12) // bottom breathing room above Home bar
        }
        .padding()
        .padding(.top, 10)
        .padding(.bottom, 10)
        .onChange(of: game.lastAttack?.nonce) {
            guard let a = game.lastAttack else { return }
            
            // Start animation
            animationState.startAttackAnimation()
            
            if game.fastForward {
                // Skip animation, commit immediately
                game.commitPendingEffect()
                animationState.startImpactAnimation()
                if a.didKill {
                    if a.attackerIsPlayer {
                        animationState.startShatterAnimation(enemyIndex: a.targetIndex)
                    } else {
                        animationState.startShatterAnimation(playerIndex: a.targetIndex)
                    }
                    shatterNonce &+= 1
                }
                // Reset quickly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animationState.attackPulse = false
                    animationState.shatterPulse = false
                    animationState.shatterEnemyIndex = nil
                    animationState.shatterPlayerIndex = nil
                }
            } else {
                // Normal animation sequence
                let animationDuration = game.gameStep.getAnimationDuration()
                withAnimation(.easeInOut(duration: animationDuration)) { animationState.flyT = 1 }
                
                // Commit at impact
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                    game.commitPendingEffect()
                    animationState.startImpactAnimation()
                    
                    if a.didKill {
                        if a.attackerIsPlayer {
                            animationState.startShatterAnimation(enemyIndex: a.targetIndex)
                        } else {
                            animationState.startShatterAnimation(playerIndex: a.targetIndex)
                        }
                        shatterNonce &+= 1
                    }
                    
                    // Return flight
                    withAnimation(.easeInOut(duration: animationDuration)) { animationState.flyT = 0 }
                    
                    // Clean up AFTER return flight completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        animationState.showFly = false
                        animationState.attackPulse = false
                        animationState.shatterPulse = false
                        animationState.shatterEnemyIndex = nil
                        animationState.shatterPlayerIndex = nil
                        // Now advance to next actor after animation completes
                        game.advanceActorOrEndRound()
                    }
                }
            }
        }
        .onChange(of: game.lastHeal?.nonce) {
            animationState.startHealAnimation()
            
            if game.fastForward {
                // Skip animation, commit immediately
                game.commitPendingEffect()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animationState.healPulse = false
                }
            } else {
                // Normal heal animation
                let healDuration = dur(BattleTempo.healNormalDuration)
                withAnimation(.easeInOut(duration: healDuration)) { animationState.startHealAnimation() }
                DispatchQueue.main.asyncAfter(deadline: .now() + healDuration) {
                    game.commitPendingEffect()
                    DispatchQueue.main.asyncAfter(deadline: .now() + healDuration) {
                        animationState.healPulse = false
                    }
                }
            }
        }
        .overlayPreferenceValue(SlotFramesKey.self) { anchors in
            GeometryReader { proxy in
                if let a = game.lastAttack,
                   let startA = anchors[SlotID(isPlayerSide: a.attackerIsPlayer, index: a.attackerIndex)],
                   let endA = anchors[SlotID(isPlayerSide: !a.attackerIsPlayer, index: a.targetIndex)] {

                    let startRect = proxy[startA]
                    let endRect = proxy[endA]
                    let cx = startRect.midX + (endRect.midX - startRect.midX) * animationState.flyT
                    let cy = startRect.midY + (endRect.midY - startRect.midY) * animationState.flyT

                    // Resolve the attacking card for visuals
                    let attackerCard: Card? = {
                        if a.attackerIsPlayer {
                            return game.field.player.slots[a.attackerIndex]
                        } else {
                            return game.field.enemy.slots[a.attackerIndex]
                        }
                    }()

                    ZStack {
                        if animationState.showFly, let card = attackerCard {
                            // scale bump peaking mid-flight
                            let bump = 0.06
                            let tri = 1 - abs(1 - 2*animationState.flyT) // 0→1→0
                            CardView(card: card, size: cardSize)
                                .scaleEffect(1 + bump * tri)
                                .position(x: cx, y: cy)
                                .allowsHitTesting(false)
                        }
                        // Impact flash on defender slot
                        if animationState.attackPulse {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.22))
                                .frame(width: endRect.width, height: endRect.height)
                                .position(x: endRect.midX, y: endRect.midY)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
        }
        .overlay {
            if game.preRollActive {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    Text(game.preRollText)
                        .font(.title2).bold()
                        .padding(.horizontal, 18)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity)
                }
                .allowsHitTesting(true) // block user input during pre-roll
            }
        }
    }
}
