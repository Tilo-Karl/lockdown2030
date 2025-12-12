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

        case .item:
            attackItemOnTile(pos: pos)

        case .tile:
            pushCombat(GameStrings.combatCantAttackThat)
        }
    }

    private func attackZombieOnTile(pos: Pos) {
        guard let myPos = myPos else { return }
        guard myPos == pos else {
            pushCombat(GameStrings.combatZombieTooFar)
            return
        }

        // Prefer selectedEntityId if it's a zombie on this tile.
        let target: Zombie? = {
            if let id = selectedEntityId,
               let z = zombies.first(where: { $0.id == id && $0.alive && $0.pos == pos }) {
                return z
            }
            return zombies.first { $0.alive && $0.pos == pos }
        }()

        guard let finalTarget = target else {
            pushCombat(GameStrings.combatNoZombieHere)
            return
        }

        Task { await attackEntity(targetId: finalTarget.id, targetType: "zombie") }
    }

    private func attackHumanOnTile(pos: Pos) {
        guard let myPos = myPos else { return }
        guard myPos == pos else {
            pushCombat("That human is too far away.")
            return
        }

        // Prefer selectedEntityId if it's on this tile.
        if let id = selectedEntityId {
            // Player target
            if let p = players.first(where: { $0.userId == id && $0.userId != uid && $0.pos == pos }) {
                Task { await attackEntity(targetId: p.userId, targetType: "player") }
                return
            }
            // NPC target
            if let n = npcs.first(where: { $0.id == id && ($0.alive ?? true) && $0.pos == pos }) {
                Task { await attackEntity(targetId: n.id, targetType: "npc") }
                return
            }
        }

        // Fallback: first player on tile, else first npc on tile
        if let p = players.first(where: { $0.userId != uid && $0.pos == pos }) {
            Task { await attackEntity(targetId: p.userId, targetType: "player") }
            return
        }
        if let n = npcs.first(where: { ($0.alive ?? true) && $0.pos == pos }) {
            Task { await attackEntity(targetId: n.id, targetType: "npc") }
            return
        }

        pushCombat("There is no other human here.")
    }

    private func attackItemOnTile(pos: Pos) {
        guard let myPos = myPos else { return }
        guard myPos == pos else {
            pushCombat("That item is too far away.")
            return
        }

        let target: WorldItem? = {
            if let id = selectedEntityId,
               let it = items.first(where: { $0.id == id && $0.pos == pos }) {
                return it
            }
            return items.first { $0.pos == pos }
        }()

        guard let item = target else {
            pushCombat("There is no item here.")
            return
        }

        Task { await attackEntity(targetId: item.id, targetType: "item") }
    }
}
