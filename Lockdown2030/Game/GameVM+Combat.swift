//
//  GameVM+Combat.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-08.
//

import Foundation

extension GameVM {

    @MainActor
    func attackSelected() {
        guard let kind = interactionKind,
              let pos = interactionPos else {
            pushCombat(GameStrings.combatNoTargetSelected)
            return
        }

        switch kind {
        case .zombie:
            zombieHitTick &+= 1
            attackZombieOnTile(pos: pos)

        case .human:
            attackHumanOnTile(pos: pos)

        case .tile, .item:
            pushCombat(GameStrings.combatCantAttackThat)
        }
    }

    // MARK: - Zombie attacks

    @MainActor
    private func attackZombieOnTile(pos: Pos) {
        guard let myPos = myPos else { return }
        guard myPos == pos else {
            pushCombat(GameStrings.combatZombieTooFar)
            return
        }

        let target: Zombie?

        // Prefer selected entity id (only if we’re in zombie interaction and it’s on this tile)
        if interactionKind == .zombie,
           let selectedId = selectedEntityId,
           let z = zombies.first(where: { $0.id == selectedId && $0.alive && $0.pos == pos }) {
            target = z
        } else {
            target = zombies.first { $0.alive && $0.pos == pos }
        }

        guard let finalTarget = target else {
            pushCombat(GameStrings.combatNoZombieHere)
            return
        }

        Task {
            await attackEntity(targetId: finalTarget.id, targetType: "zombie")
        }
    }

    // MARK: - Human attacks (players for now)

    @MainActor
    private func attackHumanOnTile(pos: Pos) {
        guard let myPos = myPos else { return }
        guard myPos == pos else {
            pushCombat("That human is too far away.")
            return
        }

        let humansHere = players.filter {
            $0.userId != uid && $0.pos == pos
        }

        guard !humansHere.isEmpty else {
            pushCombat("There is no other human here.")
            return
        }

        let target: PlayerDoc

        // Prefer selected entity id (only if we’re in human interaction and it’s on this tile)
        if interactionKind == .human,
           let selectedId = selectedEntityId,
           let selected = humansHere.first(where: { $0.userId == selectedId }) {
            target = selected
        } else {
            target = humansHere.first!
        }

        Task {
            await attackEntity(targetId: target.userId, targetType: "player")
        }
    }
}
