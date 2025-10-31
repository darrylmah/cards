//
//  DragDropTestView.swift
//  cards
//
//  Created by Darryl Mah.
//

import SwiftUI

struct DragDropTestView: View {
    struct DemoItem: Identifiable, Equatable {
        let id = UUID()
        let label: String
        let color: Color
    }

    @State private var items: [DemoItem] = [
        DemoItem(label: "Arcane", color: .indigo),
        DemoItem(label: "Inferno", color: .orange),
        DemoItem(label: "Frost", color: .blue),
        DemoItem(label: "Nature", color: .green),
        DemoItem(label: "Shadow", color: .purple),
        DemoItem(label: "Radiant", color: .yellow)
    ]

    @State private var draggingID: UUID? = nil

    var onClose: () -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("Drag & Drop Playground")
                .font(.title2)
                .bold()

            Text("Try dragging any tile onto another to swap their order, or drag between tiles to insert it. This isolates the drag/drop logic outside of TeamBuilderView.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    tile(for: item)
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

            Button("Back to Home", action: onClose)
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("Drag Test")
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Reset", action: reset) } }
    }

    private func tile(for item: DemoItem) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(item.color.gradient)
            .frame(height: 120)
            .overlay(
                Text(item.label)
                    .font(.headline)
                    .foregroundStyle(.white)
            )
            .overlay(alignment: .topTrailing) {
                if draggingID == item.id {
                    Image(systemName: "hand.point.up.left.fill")
                        .padding(8)
                        .foregroundStyle(.white)
                }
            }
            .opacity(draggingID == item.id ? 0.35 : 1)
            .onDrag {
                draggingID = item.id
                return NSItemProvider(object: item.id.uuidString as NSString)
            }
            .onDrop(
                of: [.text],
                delegate: DemoDropDelegate(
                    target: item,
                    items: $items,
                    draggingID: $draggingID
                )
            )
    }

    private func reset() {
        items.sort { $0.label < $1.label }
        draggingID = nil
    }

    private struct DemoDropDelegate: DropDelegate {
        let target: DemoItem
        @Binding var items: [DemoItem]
        @Binding var draggingID: UUID?

        func validateDrop(info: DropInfo) -> Bool {
            info.hasItemsConforming(to: [.text])
        }

        func dropEntered(info: DropInfo) {
            guard
                let draggingID,
                draggingID != target.id,
                let fromIndex = items.firstIndex(where: { $0.id == draggingID }),
                let toIndex = items.firstIndex(of: target)
            else { return }

            if items[toIndex].id != draggingID {
                withAnimation(.spring(response: 0.3)) {
                    let moving = items.remove(at: fromIndex)
                    items.insert(moving, at: toIndex)
                }
            }
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            DropProposal(operation: .move)
        }

        func performDrop(info: DropInfo) -> Bool {
            draggingID = nil
            return true
        }

        func dropExited(info: DropInfo) {
            if draggingID == target.id {
                draggingID = nil
            }
        }
    }
}

#Preview {
    DragDropTestView(onClose: {})
}
