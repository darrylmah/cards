//
//  ContentView.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import SwiftUI


struct ContentView: View {
    @StateObject private var game = GameState()
    
    @State private var phase: AppPhase = .home

    @State private var builderBoard = Board()
    @State private var pool: [Card] = []
    @State private var collection: [Card] = []
    @State private var energyCap: Int = 22
    @State private var matchSeed: UInt64? = nil
    @State private var runMode: RunMode = .offline

    @State private var lastPlayerTeam: Board? = nil
    @State private var lastEnemyTeam: Board? = nil
    @State private var lastMatchSeed: UInt64? = nil
    @State private var lastEnergyCap: Int? = nil
    
    private let coordinator: MatchCoordinator
    
    init() {
        let g = GameState()
        _game = StateObject(wrappedValue: g)
        coordinator = MatchCoordinator(game: g)
    }

    
    @ViewBuilder
    private var routedView: some View {
        switch phase {
        case .home:
            HomeView(
                collectionCount: collection.count,
                onOpenCollection: { phase = .collection },
                onInitiate: {
                    coordinator.initiateBattle(
                        runMode: runMode,
                        setSeed: { matchSeed = $0 },
                        setEnergyCap: { energyCap = $0 },
                        setPhase: { phase = $0 }
                    )
                }
            )
        case .collection:
            CollectionView(cards: collection) { phase = .home }
        case .build:
            TeamBuilderView(
                pool: $pool,
                board: $builderBoard,
                energyCap: energyCap,
                onSubmit: {
                    lastPlayerTeam = builderBoard
                    lastEnemyTeam = game.field.enemy
                    lastMatchSeed = matchSeed
                    lastEnergyCap = energyCap
                    game.loadTeams(player: builderBoard, enemy: game.field.enemy)
                    phase = .battle
                    game.log.removeAll()
                    game.startTurn()
                    game.startAutoBattle()
                }
            )
            .onAppear {
                if pool.isEmpty { seedPool() }
                if game.field.enemy.aliveIndices.isEmpty { game.seedDemo() }
                game.field.player = Board()
            }
        case .battle:
            BattleView(
                game: game,
                onReplay: {
                    guard let p = lastPlayerTeam, let e = lastEnemyTeam else { return }
                    game.hardReset()
                    game.loadTeams(player: p, enemy: e)
                    game.startTurn()
                    game.startAutoBattle()
                },
                onHome: {
                    game.hardReset()
                    phase = .home
                },
                onNewGame: {
                    game.hardReset()
                    builderBoard = Board()
                    pool.removeAll()
                    coordinator.initiateBattle(
                        runMode: runMode,
                        setSeed: { matchSeed = $0 },
                        setEnergyCap: { energyCap = $0 },
                        setPhase: { phase = $0 }
                    )
                }
            )
        }
    }

    var body: some View {
        NavigationStack {
            routedView
            .onAppear {
                if collection.isEmpty { seedCollection() }
            }
            // Hide the default navigation title bar
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
        // Custom centered header near the top (respects Dynamic Island)
        .safeAreaInset(edge: .top) {
            VStack(spacing: 6) {
                if phase == .battle {
                    // Minimal spacer to give breathing room under the island
                    Color.clear.frame(height: 6)
                } else {
                    Text(
                        phase == .home ? "Welcome" :
                        (phase == .collection ? "Collection" : "Build Your Team")
                    )
                    .font(.headline)
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .background(.clear)
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                if phase == .home {
                    Picker("Mode", selection: $runMode) {
                        ForEach(RunMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            #elseif os(macOS)
            ToolbarItem(placement: .automatic) {
                if phase == .home {
                    Picker("Mode", selection: $runMode) {
                        ForEach(RunMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                if phase == .home {
                    Picker("Mode", selection: $runMode) {
                        ForEach(RunMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            #endif
        }
    }

    private func seedPool() {
        pool = CardSeeder.createPool()
    }

    private func seedCollection() {
        collection = CardSeeder.createCollection()
    }
}

#Preview {
    ContentView()
}
