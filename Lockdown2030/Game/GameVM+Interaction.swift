//
//  GameVM+Interaction.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-08.
//

import Foundation
import SwiftUI

extension GameVM {

    // MARK: - Core interaction helpers

    /// Clear any active interaction selection (panel + highlight).
    @MainActor
    func clearInteraction() {
        interactionPos = nil
        interactionKind = nil
        selectedEntityId = nil
    }

    /// Core helper: select any entity type on a tile.
    /// - Parameters:
    ///   - pos: Tile position.
    ///   - kind: Interaction kind (.tile, .zombie, .human, .item).
    ///   - id: Optional entity id (used for zombie / human / item).
    @MainActor
    func selectEntity(at pos: Pos, kind: InteractionKind, id: String? = nil) {
        interactionPos = pos
        interactionKind = kind

        switch kind {
        case .tile:
            // Pure tile selection has no entity id.
            selectedEntityId = nil
        case .zombie, .human, .item:
            selectedEntityId = id
        }
    }

    // MARK: - Backwards helpers (thin wrappers)

    /// Backwards helpers that just call `selectEntity(...)` so other code
    /// doesn’t have to know about the internal entity id storage.
    @MainActor
    func selectTile(at pos: Pos) {
        selectEntity(at: pos, kind: .tile, id: nil)
    }

    @MainActor
    func selectZombie(_ zombie: Zombie) {
        selectEntity(at: zombie.pos, kind: .zombie, id: zombie.id)
    }

    @MainActor
    func selectHuman(_ npc: Npc) {
        selectEntity(at: npc.pos, kind: .human, id: npc.id)
    }

    @MainActor
    func selectItem(_ item: WorldItem) {
        selectEntity(at: item.pos, kind: .item, id: item.id)
    }

    // MARK: - Current entity helpers (zombie / human)

    /// The zombie currently selected via interaction (if any).
    /// Prefers a concrete id, but falls back to tile-based lookup.
    var interactionZombie: Zombie? {
        guard interactionKind == .zombie else {
            return nil
        }

        // If we have a specific id selected, use that first.
        if let id = selectedEntityId {
            if let found = zombies.first(where: { $0.id == id && $0.alive }) {
                return found
            }
        }

        // Fallback: use the tile position, if any.
        guard let pos = interactionPos else {
            return nil
        }

        return zombies.first { z in
            z.alive && z.pos.x == pos.x && z.pos.y == pos.y
        }
    }

    /// The human NPC currently selected via interaction (if any).
    /// Same pattern as zombies: prefer id, fall back to tile-based lookup.
    var interactionHuman: Npc? {
        guard interactionKind == .human else {
            return nil
        }

        if let id = selectedEntityId {
            if let found = npcs.first(where: { $0.id == id && ($0.alive ?? true) }) {
                return found
            }
        }

        guard let pos = interactionPos else {
            return nil
        }

        return npcs.first { n in
            (n.alive ?? true) && n.pos.x == pos.x && n.pos.y == pos.y
        }
    }

    /// Current HP of the selected attackable entity (zombie or human), if any.
    var interactionZombieHp: Int? {
        switch interactionKind {
        case .zombie:
            return interactionZombie?.hp
        case .human:
            return interactionHuman?.hp
        default:
            return nil
        }
    }

    /// Max HP we assume for the current attackable entity.
    /// Keep roughly in sync with backend spawn configs.
    var interactionZombieMaxHp: Int {
        switch interactionKind {
        case .human:
            // Civilians/raiders/traders are a bit tougher than walkers.
            return 80
        case .zombie, .tile, .item, .none:
            // Walkers currently spawn with 60 HP.
            return 60
        }
    }

    /// 0.0–1.0 ratio for the HP bar.
    var interactionZombieHpRatio: Double? {
        guard let hp = interactionZombieHp else { return nil }
        let maxHp = Double(interactionZombieMaxHp)
        guard maxHp > 0 else { return nil }
        return max(0.0, min(1.0, Double(hp) / maxHp))
    }

    /// Color to use for the HP bar, derived from HP ratio.
    /// - Green: > 60%
    /// - Yellow: 30–60%
    /// - Red: < 30%
    var interactionZombieHpColor: Color {
        guard let ratio = interactionZombieHpRatio else {
            return .green
        }

        if ratio > 0.6 {
            return .green
        } else if ratio > 0.3 {
            return .yellow
        } else {
            return .red
        }
    }

    // MARK: - Sync after data changes

    /// After entities are reloaded from Firestore, make sure the
    /// current interaction still makes sense. If the selected
    /// zombie/human has died or disappeared, clear the interaction.
    @MainActor
    func syncInteractionAfterZombiesUpdate() {
        guard let kind = interactionKind else {
            return
        }

        switch kind {
        case .zombie:
            // If we have a concrete zombie id, ensure it still exists and is alive.
            if let id = selectedEntityId {
                let stillExists = zombies.contains { z in
                    z.id == id && z.alive
                }

                if !stillExists {
                    clearInteraction()
                }
                return
            }

            // Fallback: validate tile-based selection if no id is set.
            guard let pos = interactionPos else {
                return
            }

            let stillHere = zombies.contains { z in
                z.alive && z.pos.x == pos.x && z.pos.y == pos.y
            }

            if !stillHere {
                clearInteraction()
            }

        case .human:
            // Same logic for human NPCs.
            if let id = selectedEntityId {
                let stillExists = npcs.contains { n in
                    n.id == id && (n.alive ?? true)
                }

                if !stillExists {
                    clearInteraction()
                }
                return
            }

            guard let pos = interactionPos else {
                return
            }

            let stillHere = npcs.contains { n in
                (n.alive ?? true) && n.pos.x == pos.x && n.pos.y == pos.y
            }

            if !stillHere {
                clearInteraction()
            }

        case .tile, .item:
            // Tile-only / item-only selection doesn't depend on zombies/NPCs.
            return
        }
    }

    /// Backwards-compatible wrapper used by older code paths.
    @MainActor
    func refreshInteractionAfterZombiesUpdate() {
        syncInteractionAfterZombiesUpdate()
    }
}
