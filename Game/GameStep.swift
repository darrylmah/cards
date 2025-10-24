import Foundation
import SwiftUI

// MARK: - Game Step Management
class GameStep: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var totalSteps: Int = 0
    @Published var isReplayMode: Bool = false
    @Published var speed: BattleSpeed = .normal
    
    private var gameState: GameState?
    private var stepHistory: [GameStepData] = []
    
    init(gameState: GameState? = nil) {
        self.gameState = gameState
    }
    
    // MARK: - Step Management
    
    func setGameState(_ gameState: GameState) {
        self.gameState = gameState
    }
    
    func recordStep(_ stepData: GameStepData) {
        stepHistory.append(stepData)
        totalSteps = stepHistory.count
    }
    
    func stepForward() {
        guard let gameState = gameState else { return }
        
        if isReplayMode {
            // In replay mode, step through recorded history
            if currentStep < totalSteps - 1 {
                currentStep += 1
                applyStep(stepHistory[currentStep])
            }
        } else {
            // In live mode, execute next action through GameState
            gameState.executeStepForward()
        }
    }
    
    func stepBackward() {
        guard let gameState = gameState else { return }
        
        if isReplayMode {
            // In replay mode, step back through recorded history
            if currentStep > 0 {
                currentStep -= 1
                applyStep(stepHistory[currentStep])
            }
        } else {
            // In live mode, step back through GameState
            gameState.executeStepBackward()
        }
    }
    
    func goToStep(_ index: Int) {
        guard index >= 0 && index < totalSteps else { return }
        currentStep = index
        applyStep(stepHistory[currentStep])
    }
    
    func goToBeginning() {
        currentStep = 0
        if !stepHistory.isEmpty {
            applyStep(stepHistory[currentStep])
        }
    }
    
    func goToEnd() {
        currentStep = max(0, totalSteps - 1)
        if !stepHistory.isEmpty {
            applyStep(stepHistory[currentStep])
        }
    }
    
    // MARK: - Replay Management
    
    func startReplay() {
        isReplayMode = true
        currentStep = 0
    }
    
    func stopReplay() {
        isReplayMode = false
    }
    
    func startRecording() {
        stepHistory.removeAll()
        currentStep = 0
        totalSteps = 0
    }
    
    // MARK: - Speed Management
    
    func setSpeed(_ newSpeed: BattleSpeed) {
        speed = newSpeed
        // Don't call gameState?.setSpeed() here to avoid circular calls
    }
    
    private var tempo: BattleTempo {
        if let state = gameState {
            return state.tempo
        }
        return speed.tempo
    }
    
    func duration(forNormalDuration normalDuration: Double) -> Double {
        tempo.duration(forNormalDuration: normalDuration)
    }
    
    func getAnimationDuration() -> Double {
        duration(forNormalDuration: BattleTempo.attackNormalDuration)
    }
    
    // MARK: - Private Methods
    
    private func applyStep(_ stepData: GameStepData) {
        guard let gameState = gameState else { return }
        
        // Apply the step data to restore game state
        // This would need to be implemented based on what data we store
        // For now, this is a placeholder
    }
}

// MARK: - Game Step Data
struct GameStepData {
    let stepIndex: Int
    let actionType: StepActionType
    let gameStateSnapshot: GameStateSnapshot
    let timestamp: Date
    
    enum StepActionType {
        case attack(attackerIsPlayer: Bool, attackerIndex: Int, targetIndex: Int, damage: Int, didKill: Bool)
        case heal(healerIsPlayer: Bool, healerIndex: Int, targetIndex: Int, amount: Int)
        case turnStart
        case turnEnd
    }
}

// MARK: - Game State Snapshot
struct GameStateSnapshot {
    let playerBoard: Board
    let enemyBoard: Board
    let isPlayerTurn: Bool
    let actorPtr: Int
    let log: [String]
    
    init(from gameState: GameState) {
        self.playerBoard = gameState.field.player
        self.enemyBoard = gameState.field.enemy
        self.isPlayerTurn = gameState.isPlayerTurn
        self.actorPtr = gameState.actorPtr
        self.log = gameState.log
    }
}
