//
//  GameVM+Tap.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

@MainActor
extension GameVM {

    // MARK: - Tile taps

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

    // MARK: - Zombie taps

    func handleZombieTapOnTile(pos: Pos, index: Int) {
        let zombiesHere = zombies.filter {
            $0.alive && $0.pos == pos
        }
        guard !zombiesHere.isEmpty else {
            clearInteraction()
            return
        }

        let clampedIndex = max(0, min(index, zombiesHere.count - 1))
        let target = zombiesHere[clampedIndex]
        handleZombieTap(zombieId: target.id)
    }

    func handleZombieTap(zombieId: String) {
        guard let target = zombies.first(where: { $0.id == zombieId }) else {
            clearInteraction()
            return
        }

        guard let distance = distanceFromMe(to: target.pos) else { return }

        if distance == 0 {
            // Toggle selection on same tile
            if interactionKind == .zombie,
               selectedEntityId == zombieId,
               isSameTile(interactionPos, target.pos) {
                clearInteraction()
            } else {
                selectEntity(at: target.pos, kind: .zombie, id: zombieId)
            }
        } else {
            clearInteraction()
        }
    }

    // MARK: - Human taps (players for now; NPCs later)

    func handleHumanTap(humanId: String) {
        guard let target = players.first(where: { $0.userId == humanId }),
              let pos = target.pos else {
            clearInteraction()
            return
        }

        guard let distance = distanceFromMe(to: pos) else { return }

        if distance == 0 {
            if interactionKind == .human,
               selectedEntityId == humanId,
               isSameTile(interactionPos, pos) {
                clearInteraction()
            } else {
                selectEntity(at: pos, kind: .human, id: humanId)
            }
        } else {
            clearInteraction()
        }
    }

    // MARK: - Item taps (tile-level for now)

    func handleItemTap(pos: Pos) {
        guard let distance = distanceFromMe(to: pos) else { return }

        if distance == 0 {
            if isSameTile(interactionPos, pos), interactionKind == .item {
                clearInteraction()
            } else {
                // No concrete item id yet in UI (tile-level open)
                selectEntity(at: pos, kind: .item, id: nil)
            }
        } else {
            clearInteraction()
        }
    }

    // MARK: - Private helpers

    private func distanceFromMe(to pos: Pos) -> Int? {
        guard let current = myPos else { return nil }
        return abs(current.x - pos.x) + abs(current.y - pos.y)
    }

    private func isSameTile(_ lhs: Pos?, _ rhs: Pos) -> Bool {
        guard let l = lhs else { return false }
        return l.x == rhs.x && l.y == rhs.y
    }
}
