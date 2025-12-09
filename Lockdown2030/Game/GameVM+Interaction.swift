//
//  GameVM+Interaction.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-08.
//

import Foundation

extension GameVM {

    // MARK: - Core interaction helpers

    /// Clear any active interaction selection (panel + highlight).
    @MainActor
    func clearInteraction() {
        interactionPos = nil
        interactionKind = nil
        selectedZombieId = nil
    }

    // MARK: - Current zombie helpers

    /// The zombie currently selected via interaction (if any).
    /// Prefers a concrete zombie id, but falls back to tile-based lookup.
    var interactionZombie: Zombie? {
        guard interactionKind == .zombie else {
            return nil
        }

        // If we have a specific zombie id selected, use that first.
        if let id = selectedZombieId {
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

    /// Current HP of the selected zombie, if any.
    var interactionZombieHp: Int? {
        interactionZombie?.hp
    }

    /// Max HP we assume for zombies (keep in sync with backend base HP).
    var interactionZombieMaxHp: Int {
        60   // walkers currently spawn with 60 HP
    }

    /// 0.0–1.0 ratio for the HP bar.
    var interactionZombieHpRatio: Double? {
        guard let hp = interactionZombieHp else { return nil }
        let maxHp = Double(interactionZombieMaxHp)
        return max(0.0, min(1.0, Double(hp) / maxHp))
    }

    // MARK: - Sync after data changes

    /// After zombies are reloaded from Firestore, make sure the
    /// current interaction still makes sense. If the selected
    /// zombie has died or disappeared, clear the interaction.
    @MainActor
    func syncInteractionAfterZombiesUpdate() {
        guard interactionKind == .zombie else {
            return
        }

        // If we have a concrete zombie id, ensure it still exists and is alive.
        if let id = selectedZombieId {
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
    }

    /// Backwards-compatible wrapper used by older code paths.
    @MainActor
    func refreshInteractionAfterZombiesUpdate() {
        syncInteractionAfterZombiesUpdate()
    }
}
