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
    @State private var draggingCard: Card? = nil
    @State private var dragSourceSlots: [Card?]? = nil
    @State private var dragPreviewSlots: [Card?]? = nil
    @State private var dragLocation: CGPoint? = nil
    @State private var dragFingerOffset: CGSize? = nil
    @State private var dragOriginIndex: Int? = nil
    @State private var hoverIndex: Int? = nil
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
    
    private func applyDragPreviewPlacement(targetIndex: Int) {
        guard let card = draggingCard, let origin = dragOriginIndex else { return }
        let baseSlots = dragSourceSlots ?? board.slots
        let clampedTarget = max(0, min(targetIndex, Board.maxSlots - 1))

        var preview = baseSlots
        preview[origin] = nil

        if clampedTarget == origin {
            preview[origin] = card
        } else if clampedTarget < origin {
            for idx in stride(from: origin - 1, through: clampedTarget, by: -1) {
                preview[idx + 1] = preview[idx]
            }
            preview[clampedTarget] = card
        } else {
            if origin + 1 <= clampedTarget {
                for idx in (origin + 1)...clampedTarget {
                    preview[idx - 1] = preview[idx]
                }
            }
            preview[clampedTarget] = card
        }

        withAnimation(.spring(response: 0.22, dampingFraction: 0.9, blendDuration: 0.1)) {
            dragPreviewSlots = preview
            hoverIndex = clampedTarget
        }
    }

    private func commitDragPlacement() {
        guard let card = draggingCard, let origin = dragOriginIndex else { cleanupDragState(); return }
        let baseSlots = dragSourceSlots ?? board.slots
        let target = hoverIndex ?? origin
        var slots = baseSlots
        slots[origin] = nil

        if target == origin {
            slots[origin] = card
        } else if target < origin {
            for idx in stride(from: origin - 1, through: target, by: -1) {
                slots[idx + 1] = slots[idx]
            }
            slots[target] = card
        } else {
            if origin + 1 <= target {
                for idx in (origin + 1)...target {
                    slots[idx - 1] = slots[idx]
                }
            }
            slots[target] = card
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.88, blendDuration: 0.2)) {
            board.slots = slots
        }

        cleanupDragState()
    }

    private func cleanupDragState() {
        draggingID = nil
        draggingCard = nil
        dragSourceSlots = nil
        dragPreviewSlots = nil
        dragLocation = nil
        hoverIndex = nil
        dragOriginIndex = nil
        dragFingerOffset = nil
    }

    private func targetIndex(for location: CGPoint, cardSize: CGSize) -> Int {
        let columnWidth = cardSize.width + BattleLayout.gridSpacing
        let rowHeight = cardSize.height + BattleLayout.gridSpacing

        let approximateCol = (location.x - cardSize.width / 2) / columnWidth
        let approximateRow = (location.y - cardSize.height / 2) / rowHeight

        let clampedCol = min(max(Int(round(approximateCol)), 0), BattleLayout.boardColumns - 1)
        let maxRows = Int(ceil(Double(Board.maxSlots) / Double(BattleLayout.boardColumns)))
        let clampedRow = min(max(Int(round(approximateRow)), 0), maxRows - 1)

        let index = clampedRow * BattleLayout.boardColumns + clampedCol
        return min(max(index, 0), Board.maxSlots - 1)
    }
    
    @ViewBuilder
    private func formationSlot(at index: Int, size: CGSize) -> some View {
        let activeSlots = dragPreviewSlots ?? board.slots
        let card = activeSlots[index]
        let highlighted = hoverIndex == index && draggingCard != nil
        
        var base = CardSlotView(
            card: card,
            index: index,
            isHighlighted: highlighted,
            isPlayerSide: true,
            onTap: {
                guard draggingCard == nil else { return }
                removeCardFromFormation(at: index)
            },
            size: size
        )
        
        if let card {
            base
                .opacity(draggingID == card.id ? 0.35 : 1)
                .overlay(alignment: .topTrailing) {
                    if draggingID == card.id {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.caption)
                            .padding(6)
                            .foregroundStyle(Color.white)
                    }
                }
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("formationGrid"))
                        .onChanged { value in
                            let translation = value.translation
                            let magnitude = hypot(translation.width, translation.height)
                            if draggingCard == nil {
                                guard magnitude > 4 else { return }
                                draggingID = card.id
                                draggingCard = card
                                dragSourceSlots = board.slots
                                dragPreviewSlots = nil
                                dragOriginIndex = index
                                hoverIndex = index

                                let spacing = BattleLayout.gridSpacing
                                let col = index % BattleLayout.boardColumns
                                let row = index / BattleLayout.boardColumns
                                let center = CGPoint(
                                    x: (size.width + spacing) * CGFloat(col) + size.width / 2,
                                    y: (size.height + spacing) * CGFloat(row) + size.height / 2
                                )
                                dragFingerOffset = CGSize(
                                    width: value.startLocation.x - center.x,
                                    height: value.startLocation.y - center.y
                                )
                            }

                            let location: CGPoint
                            if let offset = dragFingerOffset {
                                location = CGPoint(
                                    x: value.location.x - offset.width,
                                    y: value.location.y - offset.height
                                )
                            } else {
                                location = value.location
                            }

                            dragLocation = location

                            let nextIndex = targetIndex(for: location, cardSize: size)
                            applyDragPreviewPlacement(targetIndex: nextIndex)
                        }
                        .onEnded { _ in
                            if draggingCard != nil {
                                commitDragPlacement()
                            } else if board.slots[index] != nil {
                                removeCardFromFormation(at: index)
                            }
                        }
                )
        } else {
            base
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
        .overlay(alignment: .topTrailing) {
            Button {
                selectedCardForDetail = card
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .padding(6)
            }
            .buttonStyle(.plain)
            .background(.thinMaterial, in: Circle())
            .padding(6)
        }
    }
    
    
    private func submitTeam() {
        onSubmit()
        board = Board()
        cleanupDragState()
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
                    ZStack(alignment: .topLeading) {
                        LazyVGrid(columns: metrics.formationColumns, alignment: .center, spacing: BattleLayout.gridSpacing) {
                            ForEach(0..<Board.maxSlots, id: \.self) { idx in
                                formationSlot(at: idx, size: metrics.formationCardSize)
                            }
                        }
                        .coordinateSpace(name: "formationGrid")
                        
                        if let draggingCard, let dragLocation {
                            CardView(card: draggingCard, size: metrics.formationCardSize)
                                .shadow(radius: BattleLayout.cardShadowRadius * 2)
                                .position(dragLocation)
                                .allowsHitTesting(false)
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
