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
}
