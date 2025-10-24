//
//  GameState.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation
import Combine

final class GameState: ObservableObject {
    @Published var field = Battlefield()
    @Published var isPlayerTurn = true
    @Published var log: [String] = []
    @Published var matchSeed: UInt64?
    @Published var preRollActive: Bool = false
    @Published var preRollText: String = "Setting up the battlefield..."
    struct ActorRef { let isPlayer: Bool; let index: Int }
    @Published var actorQueue: [ActorRef] = []
    @Published var actorPtr: Int = 0
    @Published var speed: BattleSpeed = .normal
    @Published var fastForward: Bool = false
    @Published var lastAttack: AttackEvent? = nil
    @Published var lastHeal: HealEvent? = nil
    private var attackNonce: Int = 0
    private var healNonce: Int = 0
    
    // Pending effect to commit at animation impact time
    private struct PendingEffect {
        enum Kind { case attack, heal }
        let kind: Kind
        // attack
        let attackerIsPlayer: Bool?
        let newAtk: Board?
        let newDef: Board?
        // heal
        let healIsPlayer: Bool?
        let newBoard: Board?
    }
    private var pendingEffect: PendingEffect? = nil
    var hasPendingEffect: Bool { pendingEffect != nil }
    
    // Auto-battle management
    private var autoBattleManager: AutoBattleManager?
    
    // Step management
    @Published var gameStep: GameStep = GameStep()
    
    private let turnOrder: TurnOrder = DefaultTurnOrder()
    
    init() {
        self.autoBattleManager = AutoBattleManager(gameState: self)
        self.gameStep.setGameState(self)
    }

    var currentActor: ActorRef? {
        guard actorPtr < actorQueue.count else { return nil }
        return actorQueue[actorPtr]
    }
    
    var isAutoBattling: Bool {
        autoBattleManager?.isAutoBattling ?? false
    }
    
    var isPaused: Bool {
        autoBattleManager?.isPaused ?? false
    }
    
    // Speed - delegate to GameStep
    func setSpeed(_ s: BattleSpeed) {
        gameStep.setSpeed(s)
        speed = s
        fastForward = false
    }
    
    func skipToEnd() {
        // Stop any ongoing auto-battle
        autoBattleManager?.isAutoBattling = false
        autoBattleManager?.isPaused = false
        
        // Process all remaining actions instantly without animations
        Task { @MainActor in
            while !checkBattleEnd() {
                // Process one action directly without animation delays
                if let manager = autoBattleManager {
                    manager.autoActOnce()
                    // Commit effects directly without animation system
                    if hasPendingEffect {
                        commitPendingEffectDirectly()
                    }
                }
                // Very small delay to prevent UI blocking
                try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
            }
        }
    }
    
    // Direct commit without animation system for skip functionality
    @MainActor
    private func commitPendingEffectDirectly() {
        guard let pending = pendingEffect else { return }
        pendingEffect = nil
        switch pending.kind {
        case .attack:
            guard let attackerIsPlayer = pending.attackerIsPlayer,
                  let newAtk = pending.newAtk,
                  let newDef = pending.newDef else { return }
            if attackerIsPlayer {
                field.player = newAtk
                field.enemy = newDef
            } else {
                field.enemy = newAtk
                field.player = newDef
            }
            resolveDeathsAndSlide()
            advanceActorOrEndRound()
        case .heal:
            guard let isPlayer = pending.healIsPlayer, let newBoard = pending.newBoard else { return }
            if isPlayer { field.player = newBoard } else { field.enemy = newBoard }
            advanceActorOrEndRound()
        }
    }
    

    // Turn flow
    func startTurn() {
        // Reset exhaustion on both sides at the start of a round
        for side in [true, false] {
            var board = side ? field.player : field.enemy
            for idx in 0..<Board.maxSlots {
                if var c = board.slots[idx] {
                    c.exhausted = false
                    board.slots[idx] = c
                }
            }
            if side { field.player = board } else { field.enemy = board }
        }

        // Build a combined initiative across both teams
        let order = turnOrder.combinedOrder(player: field.player, enemy: field.enemy, seed: matchSeed)
        actorQueue = order.map { ActorRef(isPlayer: $0.isPlayer, index: $0.index) }
        actorPtr = 0
        if let first = currentActor { isPlayerTurn = first.isPlayer }
        logEvent("Round begins. Order: " + actorQueue.map { ref in (ref.isPlayer ? "P#" : "E#") + String(ref.index + 1) }.joined(separator: ", "))
    }

    func endTurn() {
        logEvent("Round ends.")
        if checkBattleEnd() { return }
        startTurn()
    }
    
    private func checkBattleEnd() -> Bool {
        return field.enemy.isDefeated || field.player.isDefeated
    }

    // Actions
    func attack(attackerIndex: Int, targetIndex: Int) {
        // 1. Who is acting this tick?
        guard let ref = currentActor else { return }
        let attackerIsPlayer = ref.isPlayer
        guard ref.index == attackerIndex else { return }
        
        // 2. Pull the live boards for each side
        var atkBoard = attackerIsPlayer ? field.player : field.enemy
        var defBoard = attackerIsPlayer ? field.enemy : field.player
        
        // 3. Verify the attacker can act (alive, not exhausted)
        guard (0..<Board.maxSlots).contains(attackerIndex),
              var attacker = atkBoard.slots[attackerIndex],
              attacker.isAlive, attacker.exhausted == false else { return }

        // 4. Use Targeting.swift logic
        let ctx = TargetingContext(
            attacker: attacker,
            attackerIndex: attackerIndex,
            attackerSideIsPlayer: attackerIsPlayer,
            battlefield: field
        )

        // 5. Apply the effect via CombatSystem.swift
        let (newAtk, newDef, evt, line) = CombatSystem.performAttackWithTarget(
            attackerBoard: atkBoard,
            defenderBoard: defBoard,
            attackerIndex: attackerIndex,
            targetIndex: targetIndex,
            attackerIsPlayer: attackerIsPlayer
            )
        
        // 6. Publish UI animation event + log line
        if let evt = evt {
            attackNonce &+= 1
            let damage: Int = {
                if case let .hit(v) = evt.kind { return v } else { return 0 }
            }()
            let didKill: Bool = {
                if (0..<Board.maxSlots).contains(targetIndex), let defAfter = newDef.slots[targetIndex] { return !defAfter.isAlive } else { return false }
            }()
            lastAttack = AttackEvent(
                attackerIsPlayer: evt.attackerIsPlayer,
                attackerIndex: evt.attackerIndex,
                targetIndex: evt.targetIndex,
                amount: damage,
                didKill: didKill,
                nonce: attackNonce
            )
            
            // Record step for replay
            let stepData = GameStepData(
                stepIndex: gameStep.totalSteps,
                actionType: .attack(
                    attackerIsPlayer: evt.attackerIsPlayer,
                    attackerIndex: evt.attackerIndex,
                    targetIndex: evt.targetIndex,
                    damage: damage,
                    didKill: didKill
                ),
                gameStateSnapshot: GameStateSnapshot(from: self),
                timestamp: Date()
            )
            gameStep.recordStep(stepData)
            // Defer board commit to animation impact time
            pendingEffect = PendingEffect(
                kind: .attack,
                attackerIsPlayer: attackerIsPlayer,
                newAtk: newAtk,
                newDef: newDef,
                healIsPlayer: nil,
                newBoard: nil
            )
        } else {
            // No animation, apply immediately and advance
            if attackerIsPlayer {
                field.player = newAtk
                field.enemy = newDef
            } else {
                field.enemy = newAtk
                field.player = newDef
            }
            if let line = line { logEvent(line) }
            resolveDeathsAndSlide()
            advanceActorOrEndRound()
            return
        }
        if let line = line { logEvent(line) }
    }

    func heal(healerIndex: Int, targetIndex: Int, amount: Int = 0) {
        // 1. Queued actor as healer
        guard let ref = currentActor else { return }
        let isPlayer = ref.isPlayer
        guard ref.index == healerIndex else { return }

        // 2. Operate on the acting side's board only
        let board = isPlayer ? field.player : field.enemy
        let (newBoard, evt, line) = CombatSystem.performHeal(
            board: board,
            healerIndex: healerIndex,
            targetIndex: targetIndex,
            isPlayerSide: isPlayer
        )
        
        // 3. Publish UI animation event + log line
        if let evt = evt {
            healNonce &+= 1
            lastHeal = HealEvent(
                healerIsPlayer: evt.attackerIsPlayer,
                targetIndex: evt.targetIndex,
                amount: {
                    if case let .heal(amount) = evt.kind { return amount } else { return 0 }
                }(),
                nonce: healNonce
            )
            
            // Record step for replay
            let healAmount = {
                if case let .heal(amount) = evt.kind { return amount } else { return 0 }
            }()
            let stepData = GameStepData(
                stepIndex: gameStep.totalSteps,
                actionType: .heal(
                    healerIsPlayer: evt.attackerIsPlayer,
                    healerIndex: evt.attackerIndex,
                    targetIndex: evt.targetIndex,
                    amount: healAmount
                ),
                gameStateSnapshot: GameStateSnapshot(from: self),
                timestamp: Date()
            )
            gameStep.recordStep(stepData)
            // Defer commit to animation impact time
            pendingEffect = PendingEffect(
                kind: .heal,
                attackerIsPlayer: nil,
                newAtk: nil,
                newDef: nil,
                healIsPlayer: isPlayer,
                newBoard: newBoard
            )
        } else {
            // No animation needed, apply heal immediately
            if isPlayer { field.player = newBoard } else { field.enemy = newBoard }
            if let line = line { logEvent(line) }
            advanceActorOrEndRound()
            return
        }
        if let line = line { logEvent(line) }
    }

    func resurrect(casterIndex: Int) {
        var board = isPlayerTurn ? field.player : field.enemy
        guard (0..<Board.maxSlots).contains(casterIndex),
              var caster = board.slots[casterIndex],
              caster.isAlive, caster.exhausted == false,
              caster.abilities.contains(.resurrect) else { return }

        if let deadIndex = (0..<Board.maxSlots).first(where: { i in
            if let c = board.slots[i] { return c.hp <= 0 } else { return false }
        }) {
            if var dead = board.slots[deadIndex] {
                dead.hp = 1
                board.slots[deadIndex] = dead
                caster.exhausted = true
                logEvent("\(sidePrefix(isPlayerTurn)) \(caster.name) resurrects \(dead.name) to 1 HP.")
            }
        } else if let empty = (0..<Board.maxSlots).last(where: { board.slots[$0] == nil }) {
            let token = Card(name: "Arcane Shade", house: .arcana, role: .arcana, hp: 1, atk: 2, speed: 2, energy: 3)
            _ = board.place(token, at: empty)
            caster.exhausted = true
            logEvent("\(sidePrefix(isPlayerTurn)) \(caster.name) summons an Arcane Shade.")
        }
        board.slots[casterIndex] = caster
        if isPlayerTurn { field.player = board } else { field.enemy = board }
    }

    func validTargetsFor(attackerIndex: Int) -> [Int] {
        guard let ref = currentActor else { return [] }
        let attackerIsPlayer = ref.isPlayer
        let atk = attackerIsPlayer ? field.player : field.enemy

        if attackerIndex == (Board.maxSlots - 1) {
            if let c = atk.slots[attackerIndex], !(c.role == .ranged || c.abilities.contains(.stealthAtk)) { return [] }
        }
        guard (0..<Board.maxSlots).contains(attackerIndex),
              let attacker = atk.slots[attackerIndex], attacker.isAlive, attacker.exhausted == false else { return [] }
        let ctx = TargetingContext(attacker: attacker, attackerIndex: attackerIndex, attackerSideIsPlayer: attackerIsPlayer, battlefield: field)
        return ctx.validTargets()
    }

    func advanceActorOrEndRound() {
        actorPtr &+= 1
        while actorPtr < actorQueue.count {
            let ref = actorQueue[actorPtr]
            let side = ref.isPlayer ? field.player : field.enemy
            if let c = side.slots[ref.index], c.isAlive, c.exhausted == false {
                isPlayerTurn = ref.isPlayer
                return
            }
            actorPtr &+= 1
        }
        endTurn()
    }

    private func resolveDeathsAndSlide() {
        for (i, maybe) in field.player.slots.enumerated() {
            if let c = maybe, c.hp <= 0 { logEvent("Player \(c.name) falls at slot \(i).") }
        }
        for (i, maybe) in field.enemy.slots.enumerated() {
            if let c = maybe, c.hp <= 0 { logEvent("Enemy \(c.name) falls at slot \(i).") }
        }
        field.autoSlideAll()
    }

    func logEvent(_ s: String) { log.append(s) }
    private func sidePrefix(_ isPlayer: Bool) -> String { isPlayer ? "[P]" : "[E]" }

    // Called by UI at the exact animation impact time to commit pending effects
    @MainActor
    func commitPendingEffect() {
        guard let pending = pendingEffect else { return }
        pendingEffect = nil
        switch pending.kind {
        case .attack:
            guard let attackerIsPlayer = pending.attackerIsPlayer,
                  let newAtk = pending.newAtk,
                  let newDef = pending.newDef else { return }
            if attackerIsPlayer {
                field.player = newAtk
                field.enemy = newDef
            } else {
                field.enemy = newAtk
                field.player = newDef
            }
            resolveDeathsAndSlide()
            // Don't advance actor here - let animation complete first
        case .heal:
            guard let isPlayer = pending.healIsPlayer, let newBoard = pending.newBoard else { return }
            if isPlayer { field.player = newBoard } else { field.enemy = newBoard }
            // Don't advance actor here - let animation complete first
        }
    }

    func hardReset() {
        autoBattleManager?.isAutoBattling = false
        field = Battlefield()
        isPlayerTurn = true
        log.removeAll()
        actorQueue.removeAll()
        actorPtr = 0
    }
    
    func setMatchSeed(_ seed: UInt64?) {
        self.matchSeed = seed
    }

    // Auto-battle
    func loadTeams(player: Board, enemy: Board) { field.player = player; field.enemy = enemy }

    func startAutoBattle() {
        // Show a short pre-roll to give the player context before the first action
        preRollText = "Setting up the battlefield..."
        preRollActive = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // ~2 seconds
            self?.preRollActive = false
            self?.autoBattleManager?.startAutoBattle()
        }
    }

    // Pause controls
    func pauseAfterCurrent() {
        autoBattleManager?.pauseAfterCurrent()
    }

    func resume() {
        autoBattleManager?.resume()
    }
    
    func stepForward() {
        gameStep.stepForward()
    }
    
    func stepBackward() {
        gameStep.stepBackward()
    }
    
    // Direct access to AutoBattleManager for GameStep
    func executeStepForward() {
        autoBattleManager?.stepForward()
    }
    
    func executeStepBackward() {
        autoBattleManager?.stepBackward()
    }
}

// MARK: - Demo seed
extension GameState {
    func seedDemo() {
        DemoDataManager.seedDemoGame(self)
    }
}
