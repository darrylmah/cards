//
//  MatchCoordinator.swift
//  cards
//
//  Created by Darryl Mah on 10/6/25.
//

import Foundation

/// Central coordinator for initializing matches across run modes.
final class MatchCoordinator {

    private let game: GameState

    init(game: GameState) {
        self.game = game
    }

    // Shared logic for getting match configuration based on environment
    func initiateBattle(runMode: RunMode,
                        setSeed: @escaping (UInt64?) -> Void,
                        setEnergyCap: @escaping (Int) -> Void,
                        setPhase: @escaping (AppPhase) -> Void) {

        switch runMode {
        case .production:
            Task {
                do {
                    let cfg = try await self.fetchMatchConfigProduction()
                    setSeed(cfg.seed)
                    self.game.setMatchSeed(cfg.seed)
                    if let cap = cfg.energyCap {
                        setEnergyCap(cap)
                    } else {
                        var rng = SplitMix64(seed: cfg.seed)
                        setEnergyCap(Int.random(in: 11...88, using: &rng))
                    }
                    setPhase(.build)
                } catch {
                    self.fallbackOffline(setSeed: setSeed, setEnergyCap: setEnergyCap, setPhase: setPhase)
                }
            }

        case .staging:
            Task {
                let cfg = await self.fetchMatchConfigStaging()
                setSeed(cfg.seed)
                self.game.setMatchSeed(cfg.seed)
                setEnergyCap(cfg.energyCap ?? 22)
                setPhase(.build)
            }

        case .offline:
            fallbackOffline(setSeed: setSeed, setEnergyCap: setEnergyCap, setPhase: setPhase)
        }
    }

    // MARK: - Private helpers
    private func fallbackOffline(setSeed: @escaping (UInt64?) -> Void,
                                 setEnergyCap: @escaping (Int) -> Void,
                                 setPhase: @escaping (AppPhase) -> Void) {
        let seed = UInt64.random(in: 0...UInt64.max)
        setSeed(seed)
        self.game.setMatchSeed(seed)
        var rng = SplitMix64(seed: seed)
        setEnergyCap(Int.random(in: 11...88, using: &rng))
        setPhase(.build)
    }

    private func fetchMatchConfigProduction() async throws -> MatchConfig {
        let url = URL(string: "https://api.example.com/match/new")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(MatchConfig.self, from: data)
    }

    private func fetchMatchConfigStaging() async -> MatchConfig {
        let seed = UInt64.random(in: 0...UInt64.max)
        var rng = SplitMix64(seed: seed)
        let cap = Int.random(in: 11...88, using: &rng)
        return MatchConfig(matchId: UUID().uuidString, seed: seed, energyCap: cap)
    }
}
