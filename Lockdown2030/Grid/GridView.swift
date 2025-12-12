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
    private let baseCellSize: CGFloat

    init(vm: GameVM, viewRadius: Int? = nil, cellSize: CGFloat = GridConfig.default.minCellSize) {
        self.vm = vm
        self.baseCellSize = cellSize
        _zoomRadius = State(initialValue: viewRadius ?? vm.maxViewRadius)
    }

    var body: some View {
        GeometryReader { geo in
            content(geo: geo)
        }
    }

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
                            withAnimation { proxy.scrollTo(id, anchor: .center) }
                        }
                    }
                }
                .onChange(of: vm.myPos) { _, newValue in
                    guard let pos = newValue else { return }
                    let c = clampedToGrid(pos)
                    let id = tileId(x: c.x, y: c.y)
                    withAnimation { proxy.scrollTo(id, anchor: .center) }
                }
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
            visibleGrid(geo: geo, centerPos: centerPos)
        } else {
            fullGridFallback()
        }
    }

    private func cellView(tile: GridTileViewModel) -> some View {
        let pos = Pos(x: tile.x, y: tile.y)

        return GridCellView(
            x: tile.x,
            y: tile.y,
            isMe: tile.isMe,
            isHighlighted: tile.isHighlighted,
            isTargetSelectedEntity: tile.isTargetSelectedEntity,
            hitTick: tile.hitTick,
            building: tile.building,
            cellSize: tile.tileSize,
            buildingColor: tile.buildingColor,
            tileColor: tile.tileColor,
            tileLabel: tile.tileLabel,
            hasZombie: tile.hasZombie,
            zombieIds: tile.zombieIds,
            humanIds: tile.humanIds,
            selectedEntityId: tile.selectedEntityId,
            zombieCount: tile.zombieCount,
            otherPlayerCount: tile.otherPlayerCount,
            humanCount: tile.humanCount,
            itemCount: tile.itemCount,
            onTileTap: { [weak vm] in
                guard let vm = vm else { return }
                vm.handleTileTap(pos: pos)
            },
            onZombieTap: { [weak vm] emojiIndex in
                guard let vm = vm else { return }
                vm.handleZombieTapOnTile(pos: pos, index: emojiIndex)
            },
            onHumanTap: { [weak vm] humanId in
                vm?.handleHumanTap(humanId: humanId)
            },
            onItemTap: { [weak vm] in
                vm?.handleItemTap(pos: pos)
            }
        )
        .id(tile.id)
    }

    // MARK: - Zoom controls

    @ViewBuilder
    private var zoomControls: some View {
        let clampedRadius = max(0, min(zoomRadius, vm.maxViewRadius))
        let zoomFactor = clampedRadius + 1

        VStack(spacing: 4) {
            Button(action: {
                if zoomRadius > 0 { zoomRadius -= 1 }
            }) {
                Text("+").font(.subheadline)
            }
            .buttonStyle(.bordered)

            Text("\(zoomFactor)x")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button(action: {
                if zoomRadius < vm.maxViewRadius { zoomRadius += 1 }
            }) {
                Text("–").font(.subheadline)
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

    @ViewBuilder
    private func visibleGrid(geo: GeometryProxy, centerPos: Pos) -> some View {
        let radius = max(0, min(zoomRadius, vm.maxViewRadius))

        let viewport = GridViewport(
            gridW: vm.gridW,
            gridH: vm.gridH,
            center: centerPos,
            radius: radius
        )

        let tileSize = viewport.tileSize(in: geo, baseCellSize: baseCellSize)

        ForEach(viewport.yRange, id: \.self) { y in
            HStack(spacing: 2) {
                ForEach(viewport.xRange, id: \.self) { x in
                    let tile = makeTileViewModel(x: x, y: y, tileSize: tileSize, centerPos: centerPos)
                    cellView(tile: tile)
                }
            }
        }
    }

    @ViewBuilder
    private func fullGridFallback() -> some View {
        ForEach(0 ..< vm.gridH, id: \.self) { y in
            HStack(spacing: 2) {
                ForEach(0 ..< vm.gridW, id: \.self) { x in
                    let tile = makeTileViewModel(x: x, y: y, tileSize: baseCellSize, centerPos: nil)
                    cellView(tile: tile)
                }
            }
        }
    }

    private func makeTileViewModel(
        x: Int,
        y: Int,
        tileSize: CGFloat,
        centerPos: Pos?
    ) -> GridTileViewModel {
        let isMe: Bool
        if let center = centerPos {
            isMe = (center.x == x && center.y == y)
        } else {
            isMe = (vm.myPos?.x == x && vm.myPos?.y == y)
        }

        let isHighlighted = (lastTap?.x == x && lastTap?.y == y)

        let zombiesHere = vm.zombies.filter { $0.pos.x == x && $0.pos.y == y }
        let zombieIdsHere = zombiesHere.map { $0.id }

        let npcsHere = vm.npcs.filter { $0.pos.x == x && $0.pos.y == y }

        let otherPlayersHere = vm.players.filter { p in
            p.userId != vm.uid && p.pos?.x == x && p.pos?.y == y
        }
        let humanIdsHere = otherPlayersHere.map { $0.userId } + npcsHere.map { $0.id }

        let itemsHere = vm.items.filter { $0.pos.x == x && $0.pos.y == y }

        let selectedEntityId = vm.selectedEntityId

        let isTargetSelectedEntity: Bool = {
            guard let id = selectedEntityId, let kind = vm.interactionKind else { return false }
            switch kind {
            case .zombie:
                return zombieIdsHere.contains(id)
            case .human:
                return humanIdsHere.contains(id)
            case .item:
                return itemsHere.contains(where: { $0.id == id })
            case .tile:
                return false
            }
        }()

        let building = vm.buildingAt(x: x, y: y)

        let tileLabel: String
        if let b = building {
            tileLabel = b.type
        } else if let code = vm.tileCodeAt(x: x, y: y) {
            if let meta = vm.tileMeta[code], !meta.label.isEmpty {
                tileLabel = meta.label.uppercased()
            } else {
                tileLabel = ""
            }
        } else {
            tileLabel = ""
        }

        let hasZombie = !zombiesHere.isEmpty
        let hitTick = vm.zombieHitTick

        return GridTileViewModel(
            id: tileId(x: x, y: y),
            x: x,
            y: y,
            isMe: isMe,
            isHighlighted: isHighlighted,
            isTargetSelectedEntity: isTargetSelectedEntity,
            building: building,
            tileSize: tileSize,
            buildingColor: vm.buildingColor(for: building),
            tileColor: vm.tileColorAt(x: x, y: y),
            tileLabel: tileLabel,
            hasZombie: hasZombie,
            zombieIds: zombieIdsHere,
            humanIds: humanIdsHere,
            selectedEntityId: selectedEntityId,
            zombieCount: zombiesHere.count,
            otherPlayerCount: otherPlayersHere.count,
            humanCount: humanIdsHere.count,
            itemCount: itemsHere.count,
            hitTick: hitTick
        )
    }
}

private struct GridTileViewModel {
    let id: String
    let x: Int
    let y: Int
    let isMe: Bool
    let isHighlighted: Bool
    let isTargetSelectedEntity: Bool
    let building: GameVM.Building?
    let tileSize: CGFloat
    let buildingColor: Color?
    let tileColor: Color?
    let tileLabel: String
    let hasZombie: Bool
    let zombieIds: [String]
    let humanIds: [String]
    let selectedEntityId: String?
    let zombieCount: Int
    let otherPlayerCount: Int
    let humanCount: Int
    let itemCount: Int
    let hitTick: Int
}
