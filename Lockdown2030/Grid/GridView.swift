//
//  GridView.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import SwiftUI

struct GridView: View {
    @ObservedObject var vm: GameVM
    /// Internal zoom radius (how far around the player we render).
    @State private var zoomRadius: Int
    @State private var lastTap: Pos? = nil
    /// Base tile size (in points) used as input to the viewport’s sizing logic.
    /// Defaults to `GridConfig.default.minCellSize` so ContentView and GridView
    /// share the same notion of “minimum tile size”.
    private let baseCellSize: CGFloat

    init(vm: GameVM, viewRadius: Int? = nil, cellSize: CGFloat = GridConfig.default.minCellSize) {
        self.vm = vm
        self.baseCellSize = cellSize
        // Seed the zoom radius from the caller if provided, otherwise use the engine’s max view radius.
        _zoomRadius = State(initialValue: viewRadius ?? vm.maxViewRadius)
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
                    ZStack(alignment: .bottomTrailing) {
                        VStack(spacing: 2) {
                            gridContent(geo: geo)
                        }

                        zoomControls
                            .padding(8)
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
                //.frame(minHeight: 200)
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
            let radius = max(0, min(zoomRadius, vm.maxViewRadius))

            let viewport = GridViewport(
                gridW: vm.gridW,
                gridH: vm.gridH,
                center: centerPos,
                radius: radius
            )

            let tileSize = viewport.tileSize(
                in: geo,
                baseCellSize: baseCellSize
            )

            ForEach(viewport.yRange, id: \.self) { y in
                HStack(spacing: 2) {
                    ForEach(viewport.xRange, id: \.self) { x in
                        let isMe = (centerPos.x == x && centerPos.y == y)
                        let isHighlighted = (lastTap?.x == x && lastTap?.y == y)
                        let isTargetZombie =
                            vm.interactionKind == .zombie &&
                            vm.interactionPos?.x == x &&
                            vm.interactionPos?.y == y

                        cellView(
                            x: x,
                            y: y,
                            isMe: isMe,
                            isHighlighted: isHighlighted,
                            isTargetZombie: isTargetZombie,
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
                        let isTargetZombie =
                            vm.interactionKind == .zombie &&
                            vm.interactionPos?.x == x &&
                            vm.interactionPos?.y == y

                        cellView(
                            x: x,
                            y: y,
                            isMe: isMe,
                            isHighlighted: isHighlighted,
                            isTargetZombie: isTargetZombie,
                            tileSize: baseCellSize
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
        isTargetZombie: Bool,
        tileSize: CGFloat
    ) -> some View {
        let id = tileId(x: x, y: y)
        let building = vm.buildingAt(x: x, y: y)
        let pos = Pos(x: x, y: y)

        let tileLabel: String
        if let b = building {
            // Buildings keep using their type as the label
            tileLabel = b.type
        } else if let code = vm.tileCodeAt(x: x, y: y) {
            // For terrain, pull the label from tileMeta if available
            if let meta = vm.tileMeta[code], !meta.label.isEmpty {
                tileLabel = meta.label.uppercased()
            } else {
                tileLabel = ""
            }
        } else {
            tileLabel = ""
        }

        let zombiesHere = vm.zombies.filter { z in
            z.pos.x == x && z.pos.y == y
        }
        // Other players on this tile (excluding me)
        let otherPlayersHere = vm.players.filter { p in
            p.userId != vm.uid && p.pos?.x == x && p.pos?.y == y
        }
        let hasZombie = !zombiesHere.isEmpty

        return GridCellView(
            x: x,
            y: y,
            isMe: isMe,
            isHighlighted: isHighlighted,
            isTargetZombie: isTargetZombie,
            building: building,
            cellSize: tileSize,
            buildingColor: vm.buildingColor(for: building),
            tileColor: vm.tileColorAt(x: x, y: y),
            tileLabel: tileLabel,
            hasZombie: hasZombie,
            zombieCount: zombiesHere.count,
            otherPlayerCount: otherPlayersHere.count,
            humanCount: 0,
            itemCount: 0,
            onTileTap: { [weak vm] in
                guard let vm = vm else { return }
                vm.log.info("Tapped tile in GridView — x: \(pos.x, privacy: .public), y: \(pos.y, privacy: .public)")
                vm.handleTileTap(pos: pos)
            },
            onZombieTap: { [weak vm] in
                vm?.handleZombieTap(pos: pos)
            },
            onHumanTap: { [weak vm] in
                vm?.handleHumanTap(pos: pos)
            },
            onItemTap: { [weak vm] in
                vm?.handleItemTap(pos: pos)
            }
        )
        .id(id)
    }

    // MARK: - Zoom controls

    @ViewBuilder
    private var zoomControls: some View {
        // Clamp radius safely
        let clampedRadius = max(0, min(zoomRadius, vm.maxViewRadius))
        let zoomFactor = clampedRadius + 1

        VStack(spacing: 4) {
            Button(action: {
                if zoomRadius > 0 {
                    zoomRadius -= 1
                }
            }) {
                Text("+")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)

            Text("\(zoomFactor)x")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button(action: {
                if zoomRadius < vm.maxViewRadius {
                    zoomRadius += 1
                }
            }) {
                Text("–")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
        }
        .padding(4)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        vm.log.info("Tapped tile in GridView — x: \(pos.x, privacy: .public), y: \(pos.y, privacy: .public)")
        vm.handleTileTap(pos: pos)
    }
}
