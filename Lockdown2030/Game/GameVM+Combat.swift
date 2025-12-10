//
//  GameVM+Combat.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-08.
//

import Foundation

extension GameVM {

    /// High-level combat entry point used by the UI.
    /// Uses the current interactionKind / interactionPos to decide what to attack.
    @MainActor
    func attackSelected() {
        guard let kind = interactionKind, let pos = interactionPos else {
            pushCombat(GameStrings.combatNoTargetSelected)
            return
        }

        switch kind {
        case .zombie:
            // Bump the hit tick so the selected zombie tile can animate (shake) in the UI.
            zombieHitTick &+= 1
            attackZombieOnTile(pos: pos)

        case .human:
            attackHumanOnTile(pos: pos)

        case .tile, .item:
            pushCombat(GameStrings.combatCantAttackThat)
        }
    }

    // MARK: - Zombie attacks

    /// Find a zombie on the given tile and send an attack to the engine.
    @MainActor
    private func attackZombieOnTile(pos: Pos) {
        // Must know where we are.
        guard let myPos = myPos else {
            pushCombat(GameStrings.combatDontKnowWhereYouAre)
            return
        }

        // For now, only allow attacks on your own tile.
        guard myPos.x == pos.x && myPos.y == pos.y else {
            pushCombat(GameStrings.combatZombieTooFar)
            return
        }

        // Prefer specifically selected zombie on this tile.
        let target: Zombie?

        if let selectedId = selectedZombieId,
           let z = zombies.first(where: { $0.id == selectedId && $0.alive }),
           z.pos.x == pos.x && z.pos.y == pos.y {
            target = z
        } else {
            let zombiesHere = zombies.filter { z in
                z.alive && z.pos.x == pos.x && z.pos.y == pos.y
            }
            target = zombiesHere.first
        }

        guard let finalTarget = target else {
            pushCombat(GameStrings.combatNoZombieHere)
            return
        }

        // Fire off the unified engine attack against a "zombie" entity.
        Task {
            await self.attackEntity(targetId: finalTarget.id, targetType: "zombie")
        }
    }

    // MARK: - Human attacks (players for now, NPCs later)

    @MainActor
    private func attackHumanOnTile(pos: Pos) {
        guard let myPos = myPos else {
            pushCombat(GameStrings.combatDontKnowWhereYouAre)
            return
        }

        // Same rule: only attack humans on your own tile (for now).
        guard myPos.x == pos.x && myPos.y == pos.y else {
            pushCombat("That human is too far away.")
            return
        }

        // All humans on this tile except me.
        let humansHere = players.filter { p in
            p.userId != uid && p.pos?.x == pos.x && p.pos?.y == pos.y
        }

        guard !humansHere.isEmpty else {
            pushCombat("There is no other human here.")
            return
        }

        let target: PlayerDoc

        // Prefer currently selected human if still on this tile.
        if let selectedId = selectedHumanId,
           let selected = humansHere.first(where: { $0.userId == selectedId }) {
            target = selected
        } else {
            target = humansHere.first!
        }

        // Unified attack vs a "player" entity.
        Task {
            await self.attackEntity(targetId: target.userId, targetType: "player")
        }
    }
}
