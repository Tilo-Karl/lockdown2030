//
//  GameVM+Interaction.swift
//  Lockdown2030
//
//  Pure Entity-based selection (NO Zombie/Npc/WorldItem).
//

import Foundation

extension GameVM {

    // MARK: - Clear / select

    func clearInteraction() {
        interactionPos = nil
        interactionKind = nil
        selectedEntityId = nil
    }

    func selectEntity(at pos: Pos, kind: InteractionKind, id: String? = nil) {
        interactionPos = pos
        interactionKind = kind
        selectedEntityId = (kind == .tile) ? nil : id
    }

    // MARK: - Entity helpers

    private func entities(at pos: Pos) -> [Entity] {
        allEntities.filter { $0.pos == pos }
    }

    private func kindForEntity(_ e: Entity) -> InteractionKind {
        switch e.type {
        case .zombie: return .zombie
        case .item:   return .item
        case .human:  return .human
        }
    }

    func entityPos(for entityId: String) -> Pos? {
        entitiesById[entityId]?.pos
    }

    func interactionKind(for entityId: String) -> InteractionKind? {
        guard let e = entitiesById[entityId] else { return nil }
        return kindForEntity(e)
    }

    // MARK: - Keep selection valid after snapshots

    func syncInteractionAfterWorldUpdate() {
        guard let kind = interactionKind else { return }

        switch kind {
        case .tile:
            return
        case .zombie, .human, .item:
            // If an id is selected, it must still exist (and still have a pos).
            if let id = selectedEntityId {
                guard let e = entitiesById[id], e.pos != nil else {
                    clearInteraction()
                    return
                }
                // Keep interactionPos in sync with the entity's current pos
                interactionPos = e.pos
            } else {
                // No id selected -> nothing canonical to validate
                return
            }
        }
    }
}
