//
//  GameVM+Tap.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

@MainActor
extension GameVM {

    // MARK: - Tile taps (movement + tile panel)

    func handleTileTap(pos: Pos) {
        guard let current = myPos else { return }

        // Own tile: toggle tile interaction
        if pos == current {
            if isSameTile(interactionPos, pos), interactionKind == .tile {
                clearInteraction()
            } else {
                selectEntity(at: pos, kind: .tile, id: nil)
            }
            return
        }

        // Adjacent move (8-direction)
        let dx = pos.x - current.x
        let dy = pos.y - current.y
        let step = max(abs(dx), abs(dy))
        guard step == 1 else { return }

        clearInteraction()
        Task { await move(dx: dx, dy: dy) }
    }

    // MARK: - ONE entity tap (zombie / player / npc / item)

    func handleEntityTap(entityId: String) {
        guard let pos = entityPos(for: entityId),
              let kind = interactionKind(for: entityId) else {
            clearInteraction()
            return
        }

        guard let distance = distanceFromMe(to: pos) else { return }

        if distance == 0 {
            // Toggle selection if already selected on same tile
            if interactionKind == kind,
               selectedEntityId == entityId,
               isSameTile(interactionPos, pos) {
                clearInteraction()
            } else {
                selectEntity(at: pos, kind: kind, id: entityId)
            }
        } else {
            clearInteraction()
        }
    }

    // MARK: - Private helpers

    private func interactionKind(for entityId: String) -> InteractionKind? {
        if zombies.contains(where: { $0.id == entityId }) { return .zombie }
        if players.contains(where: { $0.userId == entityId }) { return .human }
        if npcs.contains(where: { $0.id == entityId }) { return .human }
        if items.contains(where: { $0.id == entityId }) { return .item }
        return nil
    }

    private func entityPos(for entityId: String) -> Pos? {
        if let z = zombies.first(where: { $0.id == entityId }) { return z.pos }
        if let p = players.first(where: { $0.userId == entityId }) { return p.pos }
        if let n = npcs.first(where: { $0.id == entityId }) { return n.pos }
        if let i = items.first(where: { $0.id == entityId }) { return i.pos }
        return nil
    }

    private func distanceFromMe(to pos: Pos) -> Int? {
        guard let current = myPos else { return nil }
        return abs(current.x - pos.x) + abs(current.y - pos.y)
    }

    private func isSameTile(_ lhs: Pos?, _ rhs: Pos) -> Bool {
        guard let l = lhs else { return false }
        return l.x == rhs.x && l.y == rhs.y
    }
}
