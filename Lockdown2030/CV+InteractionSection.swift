//
//  CV+InteractionSection.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-09.
//

import SwiftUI

extension ContentView {

    var interactionSection: some View {
        Group {
            // Show panel if we have a tapped tile OR a selected entity
            if let pos = vm.interactionPos {
                let selected = vm.selectedEntity // derived from selectedEntityId

                VStack(alignment: .leading, spacing: 6) {

                    // Header row
                    HStack(spacing: 8) {
                        Text(selected.map(entityTitle) ?? "Tile")
                            .font(.caption)
                            .fontWeight(.semibold)

                        Spacer()

                        Text("(\(pos.x), \(pos.y))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Button(action: { vm.clearInteraction() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }

                    // Description
                    Text(selected.map(entitySubtitle) ?? "Tap an entity on this tile.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // HP bar only if selected entity is an ACTOR (HUMAN/ZOMBIE)
                    if let actor = selected?.actor {
                        let hp = actor.currentHp ?? 0
                        let maxHp = max(actor.maxHp ?? 1, 1)
                        let ratio = Double(hp) / Double(maxHp)

                        VStack(spacing: 2) {
                            HStack {
                                Text("HP")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(hp)/\(maxHp)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }

                            ProgressView(value: ratio)
                                .progressViewStyle(.linear)
                        }
                    }

                    // Actions
                    HStack {
                        Spacer()

                        if let selected = selected {
                            switch selected.type {
                            case .item:
                                Button("Equip") { }
                                    .buttonStyle(.bordered)
                                    .disabled(true)

                            case .zombie, .human:
                                Button("Attack") {
                                    vm.attackSelectedEntity()
                                }
                                .buttonStyle(.bordered)
                            }
                        } else {
                            Button("OK") { }
                                .buttonStyle(.bordered)
                                .disabled(true)
                        }
                    }

                    // Tile Inspector (debug)
                    if let cell = vm.renderCellAt(x: pos.x, y: pos.y) {
                        let terrainCode = cell.terrain ?? ""
                        let buildingName = cell.building?.name ?? ""
                        let buildingType = cell.building?.type ?? ""
                        let cellType = cell.type ?? ""
                        let labelSource: String = {
                            if !buildingName.isEmpty { return "building.name" }
                            if !buildingType.isEmpty { return "building.type" }
                            if !cellType.isEmpty { return "cell.type" }
                            return "empty"
                        }()

                        let terrainHex = vm.cellPalette?.terrainColors[terrainCode]
                        let paletteType = !buildingType.isEmpty ? buildingType : cellType
                        let buildingHex = paletteType.isEmpty ? nil : vm.cellPalette?.buildingColors[paletteType]
                        let chosenHex = buildingHex ?? terrainHex
                        let colorSource = buildingHex != nil
                            ? "buildingColors[type]"
                            : (terrainHex != nil ? "terrainColors[terrain]" : "fallback")

                        let baseOpacity: Double = cell.blocksMove ? 0.55 : 0.25
                        let opacityFinal = cell.ruined ? max(baseOpacity, 0.7) : baseOpacity
                        let opacityStr = String(format: "%.2f", opacityFinal)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Tile Inspector")
                                .font(.caption2)
                                .fontWeight(.semibold)

                            Text("raw: x=\(cell.x) y=\(cell.y) z=\(cell.z) layer=\(cell.layer)")
                                .font(.caption2)
                            Text("terrain=\(terrainCode) blocksMove=\(opt(cell.blocksMove)) moveCost=\(opt(cell.moveCost)) ruined=\(opt(cell.ruined)) hp=\(opt(cell.hp))")
                                .font(.caption2)
                            Text("type=\(opt(cell.type)) districtId=\(opt(cell.districtId))")
                                .font(.caption2)
                            Text("building.type=\(opt(cell.building?.type)) name=\(opt(cell.building?.name)) floors=\(opt(cell.building?.floors)) districtId=\(opt(cell.building?.districtId)) root=\(opt(cell.building?.root?.x)),\(opt(cell.building?.root?.y))")
                                .font(.caption2)
                            Text("fuse.hp=\(opt(cell.fuse?.hp)) water.hp=\(opt(cell.water?.hp)) generator.installed=\(opt(cell.generator?.installed)) generator.hp=\(opt(cell.generator?.hp))")
                                .font(.caption2)
                            Text("search.remaining=\(opt(cell.search?.remaining)) search.searchedCount=\(opt(cell.search?.searchedCount))")
                                .font(.caption2)
                            Text("createdAt=\(opt(cell.createdAt)) updatedAt=\(opt(cell.updatedAt))")
                                .font(.caption2)

                            Text("labelSource=\(labelSource)")
                                .font(.caption2)
                            Text("colorSource=\(colorSource) terrainHex=\(opt(terrainHex)) buildingHex=\(opt(buildingHex)) chosenHex=\(opt(chosenHex)) opacityFinal=\(opacityStr)")
                                .font(.caption2)
                        }
                        .padding(.top, 4)
                    } else {
                        Text("Tile Inspector: no outside cell at this position.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Helpers

    private func entityTitle(_ e: Entity) -> String {
        // Prefer kind (WALKER/PLAYER/PISTOL/etc). Fall back to type.
        let kind = e.kind.trimmingCharacters(in: .whitespacesAndNewlines)
        if !kind.isEmpty { return kind }
        return e.type.rawValue
    }

    private func entitySubtitle(_ e: Entity) -> String {
        switch e.type {
        case .zombie, .human:
            if let a = e.actor {
                let hp = a.currentHp ?? 0
                let maxHp = a.maxHp ?? 0
                let ap = a.currentAp ?? 0
                let maxAp = a.maxAp ?? 0
                return "HP \(hp)/\(maxHp) • AP \(ap)/\(maxAp)"
            }
            return e.type.rawValue

        case .item:
            // Don’t assume item component fields here (keep compile-safe).
            return "ITEM"
        }
    }

    private func opt<T>(_ value: T?) -> String {
        value.map { "\($0)" } ?? "nil"
    }
}
