//
//  TeamBuilderView.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import SwiftUI

struct TeamBuilderView: View {
    @Binding var pool: [Card]
    @Binding var board: Board
    let energyCap: Int
    var onSubmit: () -> Void

    @State private var draggingID: UUID? = nil
    @State private var remaining: Int = 120

    // Search / Sort / Filter
    @State private var searchText: String = ""
    @State private var selectedRole: Role? = nil
    @State private var selectedHouse: House? = nil
    @State private var sortKey: CardFiltering.SortKey = .energyAsc

    // Card detail sheet
    @State private var selectedCardForDetail: Card? = nil
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var usedEnergy: Int { board.totalSelectedEnergy }
    private var remainingEnergy: Int { max(0, energyCap - usedEnergy) }

    private func boardContainsCard(id: UUID) -> Bool { board.slots.contains { $0?.id == id } }

    private var visiblePool: [Card] {
        return CardFiltering.filterAndSort(
            cards: pool,
            searchText: searchText,
            selectedRole: selectedRole,
            selectedHouse: selectedHouse,
            sortKey: sortKey
        )
    }

    private func removeCardFromFormation(at index: Int) {
        guard let card = board.slots[index] else { return }
        board.slots[index] = nil
        board.collapseToFront()
    }

    private func attemptPlaceFromPool(_ card: Card, targetIndex: Int) {
        guard !boardContainsCard(id: card.id) else { return }
        let existingEnergy = board.slots[targetIndex]?.energy ?? 0
        let newTotal = board.totalSelectedEnergy - existingEnergy + card.energy
        guard newTotal <= energyCap else { return }
        board.slots[targetIndex] = card
    }

    private func addCardFromPoolToFirstEmpty(_ card: Card) {
        guard let targetIndex = board.firstEmptyIndex else { return }
        attemptPlaceFromPool(card, targetIndex: targetIndex)
    }

    private func moveCardOnBoard(id: UUID, to targetIndex: Int) {
        guard let sourceIndex = board.slots.firstIndex(where: { $0?.id == id }) else { return }
        guard sourceIndex != targetIndex else { return }
        let movingCard = board.slots[sourceIndex]
        let targetCard = board.slots[targetIndex]
        board.slots[sourceIndex] = targetCard
        board.slots[targetIndex] = movingCard
    }

    private func handleDrop(_ id: UUID, to targetIndex: Int) {
        if let card = pool.first(where: { $0.id == id }) {
            attemptPlaceFromPool(card, targetIndex: targetIndex)
        } else {
            moveCardOnBoard(id: id, to: targetIndex)
        }
    }
    
    private func formationSlot(at index: Int, size: CGSize) -> some View {
        let card = board.slots[index]
        let highlighted = draggingID != nil && draggingID != card?.id
        
        return CardSlotView(
            card: card,
            index: index,
            isHighlighted: highlighted,
            isPlayerSide: true,
            onTap: { removeCardFromFormation(at: index) },
            size: size
        )
        .onDrag {
            guard let existing = board.slots[index] else { return NSItemProvider() }
            draggingID = existing.id
            return NSItemProvider(object: existing.id.uuidString as NSString)
        }
        .onDrop(of: [.text], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            provider.loadObject(ofClass: NSString.self) { obj, _ in
                if let s = obj as? String, let id = UUID(uuidString: s) {
                    DispatchQueue.main.async {
                        self.handleDrop(id, to: index)
                        self.draggingID = nil
                    }
                }
            }
            return true
        }
    }
    
    
    private func poolCardView(_ card: Card, size: CGSize, affordable: Bool, isSelected: Bool) -> some View {
        let canSelect = affordable && !isSelected
        return CardSlotView(card: card, index: 0, isHighlighted: false, isPlayerSide: true, onTap: {
            guard canSelect else { return }
            addCardFromPoolToFirstEmpty(card)
        },
        size: size
        )
        .saturation(isSelected ? 0 : 1)
        .opacity(isSelected ? 0.55 : 1)
        .overlay(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: BattleLayout.cardCornerRadius)
                        .fill(Color.gray.opacity(0.35))
                } else if !affordable {
                    RoundedRectangle(cornerRadius: BattleLayout.cardCornerRadius)
                        .fill(Color.red.opacity(0.22))
                }
            }
        )
        .onLongPressGesture { selectedCardForDetail = card }
        .onDrag {
            guard canSelect else { return NSItemProvider() }
            draggingID = card.id
            return NSItemProvider(object: card.id.uuidString as NSString)
        }
    }
    

    private func submitTeam() {
        onSubmit()
        board = Board()
    }
    
    var body: some View {
        GeometryReader { geo in
            let metrics = LayoutMetrics(geometry: geo)
            let poolCols = Array(
                repeating: GridItem(.flexible(), spacing: BattleLayout.gridSpacing),
                count: metrics.poolCardColumns
            )
            VStack(spacing: 10) {
                HStack {
                    Label("Time: \(remaining / 60):\(String(format: "%02d", remaining % 60))", systemImage: "clock")
                    Spacer()
                    Label("Energy: \(usedEnergy)/\(energyCap)", systemImage: "bolt.fill")
                }
                .padding(.horizontal, metrics.horizontalPadding)

                VStack(spacing: 6) {
                    Text("Upcoming Battle Rules").font(.headline)
                    Text("Energy cap: \(energyCap)").font(.subheadline)
                    Text("Extra rules: (reserved)").font(.footnote).foregroundStyle(.secondary)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, metrics.horizontalPadding)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Formation").font(.headline)
                    LazyVGrid(columns: metrics.formationColumns, alignment: .center, spacing: BattleLayout.gridSpacing) {
                        ForEach(0..<Board.maxSlots, id: \.self) { idx in
                            formationSlot(at: idx, size: metrics.formationCardSize)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.top, metrics.verticalPadding)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pick Your Cards").font(.headline)
                        Spacer()
                        Menu {
                            // Sort
                            Section("Sort") {
                                Picker("Sort", selection: $sortKey) {
                                    Text("Energy ↑").tag(CardFiltering.SortKey.energyAsc)
                                    Text("Energy ↓").tag(CardFiltering.SortKey.energyDesc)
                                    Text("ATK ↓").tag(CardFiltering.SortKey.atkDesc)
                                    Text("HP ↓").tag(CardFiltering.SortKey.hpDesc)
                                    Text("Speed ↓").tag(CardFiltering.SortKey.speedDesc)
                                }
                            }
                            // Filter Role
                            Section("Role") {
                                Button("All") { selectedRole = nil }
                                ForEach(Role.allCases, id: \.self) { r in
                                    Button(r.rawValue.capitalized) { selectedRole = r }
                                }
                            }
                            // Filter House
                            Section("House") {
                                Button("All") { selectedHouse = nil }
                                ForEach(House.allCases, id: \.self) { h in
                                    Button(h.displayName) { selectedHouse = h }
                                }
                            }
                        } label: {
                            Label("Sort / Filter", systemImage: "slider.horizontal.3")
                                .labelStyle(.iconOnly)
                                .padding(8)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    Text("Cards tinted red exceed the remaining energy and can’t be placed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScrollView(.vertical) {
                        LazyVGrid(columns: poolCols, spacing: BattleLayout.gridSpacing) {
                            ForEach(visiblePool, id: \.id) { card in
                                let affordable = remainingEnergy >= card.energy
                                let isSelected = boardContainsCard(id: card.id)
                                poolCardView(
                                    card,
                                    size: metrics.poolCardSize,
                                    affordable: affordable,
                                    isSelected: isSelected
                                )
                            }
                        }
                        .padding(.horizontal, metrics.horizontalPadding)
                        .padding(.bottom, metrics.verticalPadding)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }

                Button(action: submitTeam) { Text("Submit & Start Battle").bold() }
                    .buttonStyle(.borderedProminent)
                    .disabled(usedEnergy == 0 || usedEnergy > energyCap)
                    .padding(.bottom, 8)
            }
        }
        .onReceive(ticker) { _ in
            if remaining > 0 { remaining -= 1 } else { submitTeam() }
        }
        .onAppear { remaining = 120 }
        .sheet(item: $selectedCardForDetail) { card in
            CardDetailSheet(card: card)
        }
        .onDisappear { /* timer auto-invalidate with autoconnect; nothing required */ }
    }
    
    private struct LayoutMetrics {
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        let formationColumns: [GridItem]
        let formationCardSize: CGSize
        let poolCardColumns: Int
        let poolCardSize: CGSize

        init(geometry: GeometryProxy) {
            horizontalPadding = BattleLayout.outerPadding
            verticalPadding = 8

            let formationWidth = (
                geometry.size.width
                - horizontalPadding * 2
                - BattleLayout.gridSpacing * CGFloat(BattleLayout.boardColumns - 1)
            ) / CGFloat(BattleLayout.boardColumns)
            formationCardSize = CGSize(
                width: formationWidth,
                height: formationWidth * BattleLayout.cardAspectRatio
            )
            formationColumns = Array(
                repeating: GridItem(
                    .fixed(formationWidth),
                    spacing: BattleLayout.gridSpacing,
                    alignment: .center
                ),
                count: BattleLayout.boardColumns
            )

            poolCardColumns = 4
            let poolWidth = (
                geometry.size.width
                - horizontalPadding * 2
                - BattleLayout.gridSpacing * CGFloat(poolCardColumns - 1)
            ) / CGFloat(poolCardColumns)
            poolCardSize = CGSize(
                width: poolWidth,
                height: poolWidth * BattleLayout.cardAspectRatio
            )
        }
    }
}

