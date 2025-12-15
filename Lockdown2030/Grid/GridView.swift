//
//  GridView.swift
//  Lockdown2030
//

import SwiftUI

struct GridView: View {
    @ObservedObject var vm: GameVM
    @State private var zoomRadius: Int
    private let baseCellSize: CGFloat

    init(vm: GameVM, viewRadius: Int? = nil, cellSize: CGFloat = GridConfig.default.minCellSize) {
        self.vm = vm
        self.baseCellSize = cellSize
        _zoomRadius = State(initialValue: viewRadius ?? vm.maxViewRadius)
    }

    var body: some View {
        GeometryReader { geo in
            if vm.gridW > 0 && vm.gridH > 0 {
                ScrollViewReader { proxy in
                    ScrollView([.horizontal, .vertical]) {
                        ZStack(alignment: .bottomTrailing) {
                            VStack(spacing: 2) {
                                gridContent(geo: geo)
                            }
                            zoomControls.padding(8)
                        }
                        .padding(.vertical, 10)
                    }
                    .onAppear { scrollToMe(proxy) }
                    .onChange(of: vm.myPos) { _, _ in scrollToMe(proxy) }
                }
            } else {
                Text("Waiting for map…")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Grid

    @ViewBuilder
    private func gridContent(geo: GeometryProxy) -> some View {
        if let center = vm.myPos {
            visibleGrid(geo: geo, centerPos: clamp(center))
        } else {
            fullGridFallback()
        }
    }

    private func visibleGrid(geo: GeometryProxy, centerPos: Pos) -> some View {
        let radius = min(max(zoomRadius, 0), vm.maxViewRadius)
        let viewport = GridViewport(
            gridW: vm.gridW,
            gridH: vm.gridH,
            center: centerPos,
            radius: radius
        )
        let tileSize = viewport.tileSize(in: geo, baseCellSize: baseCellSize)

        return ForEach(viewport.yRange, id: \.self) { y in
            HStack(spacing: 2) {
                ForEach(viewport.xRange, id: \.self) { x in
                    cellView(x: x, y: y, tileSize: tileSize, centerPos: centerPos)
                }
            }
        }
    }

    private func fullGridFallback() -> some View {
        ForEach(0..<vm.gridH, id: \.self) { y in
            HStack(spacing: 2) {
                ForEach(0..<vm.gridW, id: \.self) { x in
                    cellView(x: x, y: y, tileSize: baseCellSize, centerPos: nil)
                }
            }
        }
    }

    // MARK: - Cell

    private func cellView(
        x: Int,
        y: Int,
        tileSize: CGFloat,
        centerPos: Pos?
    ) -> some View {
        let pos = Pos(x: x, y: y)

        let entitiesHere = vm.allEntities.filter { $0.pos == pos }

        let zombieIds = entitiesHere.filter { $0.type == .zombie }.map(\.id)
        let humanIds  = entitiesHere.filter { $0.type == .human }.map(\.id)
        let itemIds   = entitiesHere.filter { $0.type == .item }.map(\.id)

        let isMe: Bool = {
            if let c = centerPos { return c == pos }
            return vm.myPos == pos
        }()

        let isHighlighted: Bool = {
            guard let ip = vm.interactionPos else { return false }
            return ip == pos
        }()

        let tileLabel: String = {
            if let b = vm.buildingAt(x: x, y: y) {
                return b.type
            }
            if let code = vm.tileCodeAt(x: x, y: y),
               let meta = vm.tileMeta[code] {
                return meta.label.uppercased()
            }
            return ""
        }()

        let building = vm.buildingAt(x: x, y: y)

        return GridCellView(
            x: x,
            y: y,
            isMe: isMe,
            isHighlighted: isHighlighted,
            isTargetSelectedEntity: entitiesHere.contains { $0.id == vm.selectedEntityId },
            hitTick: vm.zombieHitTick,
            building: building,
            cellSize: tileSize,
            buildingColor: vm.buildingColor(for: building),
            tileColor: vm.tileColorAt(x: x, y: y),
            tileLabel: tileLabel,
            zombieIds: zombieIds,
            humanIds: humanIds,
            itemIds: itemIds,
            selectedEntityId: vm.selectedEntityId,
            zombieCount: zombieIds.count,
            humanCount: humanIds.count,
            itemCount: itemIds.count,
            onTileTap: { vm.handleTileTap(pos: pos) },
            onEntityTap: { vm.handleEntityTap(entityId: $0) }
        )
        .id("tile-\(x)-\(y)")
    }

    // MARK: - Helpers

    private func clamp(_ pos: Pos) -> Pos {
        Pos(
            x: min(max(pos.x, 0), vm.gridW - 1),
            y: min(max(pos.y, 0), vm.gridH - 1)
        )
    }

    private func scrollToMe(_ proxy: ScrollViewProxy) {
        guard let pos = vm.myPos else { return }
        withAnimation {
            proxy.scrollTo("tile-\(pos.x)-\(pos.y)", anchor: .center)
        }
    }

    // MARK: - Zoom

    private var zoomControls: some View {
        VStack(spacing: 4) {
            Button("+") { if zoomRadius > 0 { zoomRadius -= 1 } }
            Text("\(zoomRadius + 1)x").font(.caption2)
            Button("–") { if zoomRadius < vm.maxViewRadius { zoomRadius += 1 } }
        }
        .buttonStyle(.bordered)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
