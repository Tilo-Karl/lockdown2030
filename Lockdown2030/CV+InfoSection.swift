//
//  ContentView+InfoSections.swift
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
            if let pos = vm.myPos {
                tileContent(for: pos)
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func tileContent(for pos: Pos) -> some View {
        let building = vm.buildingAt(x: pos.x, y: pos.y)
        let zombiesHere = vm.zombies.filter { $0.pos.x == pos.x && $0.pos.y == pos.y }

        if building == nil && zombiesHere.isEmpty {
            EmptyView()
        } else {
            tileCard(
                pos: pos,
                building: building,
                zombies: zombiesHere
            )
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func tileCard(
        pos: Pos,
        building: GameVM.Building?,
        zombies: [GameVM.Zombie]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow(pos: pos, building: building, zombies: zombies)

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

    @ViewBuilder
    private func headerRow(
        pos: Pos,
        building: GameVM.Building?,
        zombies: [GameVM.Zombie]
    ) -> some View {
        HStack {
            // Left: tile label
            Text(building?.type ?? "Tile")
                .font(.subheadline)
                .bold()

            Text("(\(pos.x), \(pos.y))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

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

    @ViewBuilder
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

    @ViewBuilder
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

    @ViewBuilder
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
                    Text("You: \(vm.hp) HP / \(vm.ap) AP")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(msg)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
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
