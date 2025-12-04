//
//  CV+InfoSection.swift
//  Lockdown2030
//

import SwiftUI

/// High-level "tile details" card used by ContentView.
/// Shows building + zombie info for the tile the player is standing on,
/// and exposes the relevant actions (enter/exit, attack).
struct TileDetailsSection: View {
    @ObservedObject var vm: GameVM

    var body: some View {
        Group {
            if let tile = vm.tileHere {
                tileContent(for: tile)
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func tileContent(for tile: GameVM.TileSnapshot) -> some View {
        let building = tile.building
        let zombiesHere = tile.zombies

        if building == nil && zombiesHere.isEmpty {
            EmptyView()
        } else {
            tileCard(
                tile: tile,
                building: building,
                zombies: zombiesHere
            )
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func tileCard(
        tile: GameVM.TileSnapshot,
        building: GameVM.Building?,
        zombies: [GameVM.Zombie]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow(tile: tile, building: building, zombies: zombies)

            if let b = building {
                buildingSummary(b)
            }

            if let first = zombies.first {
                zombieSummary(first, count: zombies.count)
            }

            if building != nil || !zombies.isEmpty {
                actionRow(building: building, zombies: zombies)
                    .padding(.top, 4)
            }
        }
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Pieces

    private func headerRow(
        tile: GameVM.TileSnapshot,
        building: GameVM.Building?,
        zombies: [GameVM.Zombie]
    ) -> some View {
        let code = tile.tileCode
        let tileName: String
        if let meta = vm.tileMeta[code], !meta.label.isEmpty {
            tileName = meta.label
        } else {
            tileName = "Unknown"
        }

        let titleText: String
        let subtitleText: String

        if let b = building {
            titleText = b.type
            subtitleText = tileName
        } else {
            titleText = tileName
            subtitleText = "Tile"
        }

        return HStack {
            // Left: tile / building label
            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.subheadline)
                    .bold()
                Text(subtitleText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("(\(tile.pos.x), \(tile.pos.y))")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Right: small zombie badge if any
            if !zombies.isEmpty {
                Text("🧟 \(zombies.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    private func buildingSummary(_ b: GameVM.Building) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Building")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(b.floors) floors • \(b.tiles) tile\(b.tiles == 1 ? "" : "s") • root (\(b.root.x), \(b.root.y))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func zombieSummary(_ z: GameVM.Zombie, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Zombies")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("First: \(z.kind) • \(z.hp) HP")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func actionRow(
        building: GameVM.Building?,
        zombies: [GameVM.Zombie]
    ) -> some View {
        HStack(spacing: 12) {
            if let b = building {
                Button(
                    vm.isInsideBuilding && vm.activeBuildingId == b.id
                    ? "Exit building"
                    : "Enter building"
                ) {
                    if vm.isInsideBuilding && vm.activeBuildingId == b.id {
                        vm.leaveBuilding()
                    } else {
                        vm.enterBuildingHere()
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if let firstZombie = zombies.first {
                Button("Attack zombie") {
                    Task {
                        await vm.attackZombie(zombieId: firstZombie.id)
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
    }
}

struct EventLogSection: View {
    @ObservedObject var vm: GameVM

    var body: some View {
        Group {
            if let msg = vm.lastEventMessage, !msg.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent event")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("You: \(vm.myPlayer?.hp ?? 0) HP / \(vm.myPlayer?.ap ?? 0) AP")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(msg)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                    
                    Button("Tick game") {
                        Task {
                            await vm.tickGame()
                        }
                    }
                    .font(.caption2)
                }
                .padding(10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                EmptyView()
            }
        }
    }
}
