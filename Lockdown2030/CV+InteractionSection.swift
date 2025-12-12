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
            if let pos = vm.interactionPos, let kind = vm.interactionKind {
                VStack(alignment: .leading, spacing: 4) {
                    // Header row: title + coords + close button
                    HStack(spacing: 8) {
                        Text(interactionTitle(for: kind))
                            .font(.caption)
                            .fontWeight(.semibold)

                        Spacer()

                        Text("(\(pos.x), \(pos.y))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Button(action: {
                            vm.clearInteraction()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }

                    // Simple description placeholder for now.
                    Text(interactionDescription(for: kind))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // HP line + bar for any attackable entity (zombie / human NPC)
                    if (kind == .zombie || kind == .human),
                       let hp = vm.interactionZombieHp,
                       let ratio = vm.interactionZombieHpRatio {
                        let hpColor = vm.interactionZombieHpColor ?? .green

                        VStack(spacing: 2) {
                            HStack {
                                Text("HP")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(hpColor)
                                Spacer()
                                Text("\(hp)/\(vm.interactionZombieMaxHp)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(hpColor)
                            }

                            ProgressView(value: ratio)
                                .progressViewStyle(.linear)
                                .tint(hpColor)
                        }
                    }

                    HStack {
                        Spacer()
                        Button(interactionButtonLabel(for: kind)) {
                            switch kind {
                            case .zombie:
                                vm.attackSelected()
                            case .human:
                                // For now share same attack path as zombie.
                                vm.attackSelected()
                            case .tile, .item:
                                break
                            }
                        }
                        .buttonStyle(.bordered)
                        // Enable for zombie + human (human uses same attackSelected() for now).
                        .disabled(!(kind == .zombie || kind == .human))
                    }
                }
                .padding(8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.top, 4)
            }
        }
    }

    func interactionTitle(for kind: GameVM.InteractionKind) -> String {
        switch kind {
        case .tile:   return "Tile"
        case .zombie: return "Zombie"
        case .human:  return "Human"
        case .item:   return "Item"
        }
    }

    func interactionDescription(for kind: GameVM.InteractionKind) -> String {
        switch kind {
        case .tile:
            return "You are standing here."
        case .zombie:
            return "Zombie on your tile. Future: inspect and attack."
        case .human:
            return "Human on your tile. Future: talk / inspect."
        case .item:
            return "Item on your tile. Future: pick up."
        }
    }

    func interactionButtonLabel(for kind: GameVM.InteractionKind) -> String {
        switch kind {
        case .tile:   return "Use tile"
        case .zombie: return "Attack"
        case .human:  return "Attack"
        case .item:   return "Pick up"
        }
    }
}
