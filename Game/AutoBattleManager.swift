//
//  AutoBattleManager.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation

class AutoBattleManager: ObservableObject {
    @Published var isAutoBattling: Bool = false
    @Published var isPaused: Bool = false
    
    private var pauseRequested: Bool = false
    private weak var gameState: GameState?
    
    init(gameState: GameState) {
        self.gameState = gameState
    }
    
    func startAutoBattle() {
        guard let game = gameState else { return }
        guard !isAutoBattling else { return }
        
        isPaused = false
        pauseRequested = false
        isAutoBattling = true
        
        if game.log.isEmpty {
            game.startTurn()
        }
        
        Task { await runAutoBattleLoop() }
    }
    
    func pauseAfterCurrent() {
        pauseRequested = true
    }
    
    func resume() {
        guard let game = gameState else { return }
        guard isPaused else { return }
        
        isPaused = false
        if !isAutoBattling && !checkBattleEnd() {
            isAutoBattling = true
            Task { await runAutoBattleLoop() }
        }
    }
    
    func stepForward() {
        guard let game = gameState else { return }
        guard isPaused else { return }
        
        Task { @MainActor in
            self.autoActOnce()
        }
    }
    
    func stepBackward() {
        // For now, this is a placeholder - implementing undo would be complex
        // We could potentially store game state snapshots, but that's beyond current scope
    }
    
    private func checkBattleEnd() -> Bool {
        guard let game = gameState else { return true }
        return game.field.enemy.isDefeated || game.field.player.isDefeated
    }
    
    private func pickAutoTarget(for ref: GameState.ActorRef) -> Int? {
        guard let game = gameState else { return nil }
        let atk = ref.isPlayer ? game.field.player : game.field.enemy
        guard let attacker = atk.slots[ref.index], attacker.isAlive else { return nil }
        
        let ctx = TargetingContext(
            attacker: attacker,
            attackerIndex: ref.index,
            attackerSideIsPlayer: ref.isPlayer,
            battlefield: game.field
        )
        let targets = ctx.validTargets()
        return targets.sorted().first
    }
    
    func autoActOnce() {
        guard let game = gameState else { return }
        
        if game.field.enemy.isDefeated || game.field.player.isDefeated {
            isAutoBattling = false
            if game.field.enemy.isDefeated && game.field.player.isDefeated {
                game.logEvent("Both sides fell. Draw.")
            }
            else if game.field.enemy.isDefeated {
                game.logEvent("Enemy defeated. You win!")
            }
            else {
                game.logEvent("Your team is defeated.")
            }
            return
        }
        
        if game.currentActor == nil {
            game.startTurn()
        }
        
        guard let ref = game.currentActor else { return }
        
        // Get attacker card
        let atkSide = ref.isPlayer ? game.field.player : game.field.enemy
        guard let attacker = atkSide.slots[ref.index], attacker.isAlive else {
            game.advanceActorOrEndRound()
            return
        }

        // Don't start another action if there is a pending effect waiting to commit at impact
        if game.hasPendingEffect { return }

        // --- Healer logic ---
        if attacker.role == .healer {
            // Create a TargetingContext to find friendly heal targets
            let ctx = TargetingContext(
                attacker: attacker,
                attackerIndex: ref.index,
                attackerSideIsPlayer: ref.isPlayer,
                battlefield: game.field
            )

            if let healIndex = ctx.pickHealTargetIndex() {
                // Delegate to GameState so event + pending effect are consistent with animations
                game.heal(healerIndex: ref.index, targetIndex: healIndex)
                return
            } else {
                game.logEvent("\(attacker.name) has no ally to heal")
                game.advanceActorOrEndRound()
                return
            }
        }
        // --- End healer logic ---

        // Otherwise, act normally (attack)
        if let t = pickAutoTarget(for: ref) {
            // Delegate to GameState; it will publish event and commit at impact
            game.attack(attackerIndex: ref.index, targetIndex: t)
            return
        } else {
            var side = ref.isPlayer ? game.field.player : game.field.enemy
            if var c = side.slots[ref.index] {
                c.exhausted = true
                c.energy = 0
                side.slots[ref.index] = c
                if ref.isPlayer { game.field.player = side } else { game.field.enemy = side }
            }
            game.advanceActorOrEndRound()
        }
    }
    
    private func runAutoBattleLoop() async {
        guard let game = gameState else { return }
        
        while isAutoBattling && !checkBattleEnd() {
            await MainActor.run { self.autoActOnce() }
            
            if pauseRequested {
                pauseRequested = false
                isAutoBattling = false
                isPaused = true
                break
            }
            
            // Simple: just wait for any pending effect to complete
            while game.hasPendingEffect {
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            }
            
            if !game.fastForward {
                try? await Task.sleep(nanoseconds: game.tempo.tickNanoseconds)
            }
        }
        
        await MainActor.run {
            if !isPaused {
                self.isAutoBattling = false
                game.fastForward = false
            }
        }
    }
}
