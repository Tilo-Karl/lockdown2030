//
//  GridView.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import SwiftUI

struct GridView: View {
    @ObservedObject var vm: GameVM
    @State private var lastTap: Pos? = nil
    private let cellSize: CGFloat = 44

    var body: some View {
        if vm.gridW > 0 && vm.gridH > 0 {
            ScrollViewReader { proxy in
                ScrollView([.vertical, .horizontal]) {
                    VStack(spacing: 2) {
                        ForEach(0 ..< vm.gridH, id: \.self) { y in
                            HStack(spacing: 2) {
                                ForEach(0 ..< vm.gridW, id: \.self) { x in
                                    let isMe = (vm.myPos?.x == x && vm.myPos?.y == y)
                                    let isHighlighted = (lastTap?.x == x && lastTap?.y == y)
                                    let id = tileId(x: x, y: y)

                                    GridCellView(
                                        x: x,
                                        y: y,
                                        isMe: isMe,
                                        isHighlighted: isHighlighted,
                                        cellSize: cellSize
                                    )
                                    .id(id)
                                    .onTapGesture {
                                        handleTap(Pos(x: x, y: y))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                .onAppear {
                    // If we already know our position when the grid appears, center on it once.
                    if let pos = vm.myPos {
                        let id = tileId(x: pos.x, y: pos.y)
                        DispatchQueue.main.async {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
                .onChange(of: vm.myPos) { _, newValue in
                    // Whenever myPos changes (join or move), try to center on the new tile.
                    guard let pos = newValue else { return }
                    let id = tileId(x: pos.x, y: pos.y)
                    withAnimation {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
                .frame(minHeight: 200)
            }
        } else {
            Text("Waiting for map…")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func tileId(x: Int, y: Int) -> String {
        "tile-\(x)-\(y)"
    }

    private func handleTap(_ pos: Pos) {
        lastTap = pos
        print("Tapped tile: \(pos.x) \(pos.y)")
        vm.handleTileTap(pos: pos)
    }
}

// MARK: - Grid Cell

struct GridCellView: View {
    let x: Int
    let y: Int
    let isMe: Bool
    let isHighlighted: Bool
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: cellSize, height: cellSize)
                .cornerRadius(4)

            Text("\(x),\(y)")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .minimumScaleFactor(0.5)
        }
    }

    private var backgroundColor: Color {
        if isMe {
            return .blue.opacity(0.7)
        } else if isHighlighted {
            return .yellow.opacity(0.7)
        } else {
            return .gray.opacity(0.2)
        }
    }
}
