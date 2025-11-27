//
//  GridView.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import SwiftUI

struct GridView: View {
    @ObservedObject var vm: GameVM
    /// Optional per-device view radius. If nil, we fall back to vm.maxViewRadius.
    let viewRadius: Int?
    @State private var lastTap: Pos? = nil
    private let cellSize: CGFloat = 44

    init(vm: GameVM, viewRadius: Int? = nil) {
        self.vm = vm
        self.viewRadius = viewRadius
    }

    var body: some View {
        GeometryReader { geo in
            content(geo: geo)
        }
    }

    // Extracted into a helper so the main body stays simpler and Xcode can type-check it.
    @ViewBuilder
    private func content(geo: GeometryProxy) -> some View {
        if vm.gridW > 0 && vm.gridH > 0 {
            ScrollViewReader { proxy in
                ScrollView([.vertical, .horizontal]) {
                    VStack(spacing: 2) {
                        gridContent(geo: geo)
                    }
                    .padding(.vertical, 10)
                }
                .onAppear {
                    if let pos = vm.myPos {
                        let c = clampedToGrid(pos)
                        let id = tileId(x: c.x, y: c.y)
                        DispatchQueue.main.async {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
                .onChange(of: vm.myPos) { _, newValue in
                    guard let pos = newValue else { return }
                    let c = clampedToGrid(pos)
                    let id = tileId(x: c.x, y: c.y)
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

    @ViewBuilder
    private func gridContent(geo: GeometryProxy) -> some View {
        if let p = vm.myPos {
            let centerPos = clampedToGrid(p)
            let radius = max(0, viewRadius ?? vm.maxViewRadius)

            let viewport = GridViewport(
                gridW: vm.gridW,
                gridH: vm.gridH,
                center: centerPos,
                radius: radius
            )

            let tileSize = viewport.tileSize(
                in: geo,
                baseCellSize: cellSize
            )

            ForEach(viewport.yRange, id: \.self) { y in
                HStack(spacing: 2) {
                    ForEach(viewport.xRange, id: \.self) { x in
                        let isMe = (centerPos.x == x && centerPos.y == y)
                        let isHighlighted = (lastTap?.x == x && lastTap?.y == y)

                        cellView(
                            x: x,
                            y: y,
                            isMe: isMe,
                            isHighlighted: isHighlighted,
                            tileSize: tileSize
                        )
                    }
                }
            }
        } else {
            ForEach(0 ..< vm.gridH, id: \.self) { y in
                HStack(spacing: 2) {
                    ForEach(0 ..< vm.gridW, id: \.self) { x in
                        let isMe = (vm.myPos?.x == x && vm.myPos?.y == y)
                        let isHighlighted = (lastTap?.x == x && lastTap?.y == y)

                        cellView(
                            x: x,
                            y: y,
                            isMe: isMe,
                            isHighlighted: isHighlighted,
                            tileSize: cellSize
                        )
                    }
                }
            }
        }
    }

    private func cellView(
        x: Int,
        y: Int,
        isMe: Bool,
        isHighlighted: Bool,
        tileSize: CGFloat
    ) -> some View {
        let id = tileId(x: x, y: y)
        let building = vm.buildingAt(x: x, y: y)

        let tileLabel: String
        if let b = building {
            tileLabel = b.type
        } else if let code = vm.terrainCodeAt(x: x, y: y) {
            switch code {
            case "0": tileLabel = "ROAD"
            case "1": tileLabel = "PARK"
            case "2": tileLabel = "CEMETERY"
            case "3": tileLabel = "FOREST"
            case "4": tileLabel = "HILLS"
            case "5": tileLabel = "WATER"
            default:   tileLabel = ""
            }
        } else {
            tileLabel = ""
        }

        return GridCellView(
            x: x,
            y: y,
            isMe: isMe,
            isHighlighted: isHighlighted,
            building: building,
            cellSize: tileSize,
            buildingColor: vm.buildingColor(for: building),
            terrainColor: vm.terrainColorAt(x: x, y: y),
            tileLabel: tileLabel
        )
        .id(id)
        .onTapGesture {
            handleTap(Pos(x: x, y: y))
        }
    }

    // MARK: - Helpers

    private func clampedToGrid(_ pos: Pos) -> Pos {
        guard vm.gridW > 0, vm.gridH > 0 else { return pos }
        let x = min(max(pos.x, 0), vm.gridW - 1)
        let y = min(max(pos.y, 0), vm.gridH - 1)
        return Pos(x: x, y: y)
    }

    private func tileId(x: Int, y: Int) -> String {
        "tile-\(x)-\(y)"
    }

    private func handleTap(_ pos: Pos) {
        lastTap = pos
        print("Tapped tile: \(pos.x) \(pos.y)")
        vm.handleTileTap(pos: pos)
    }
}
