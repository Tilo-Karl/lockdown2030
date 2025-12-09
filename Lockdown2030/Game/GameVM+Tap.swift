//
//  GameVM+Tap.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

@MainActor
extension GameVM {
    func handleTileTap(pos: Pos) {
        log.info("Tapped tile in handleTileTap — x: \(pos.x, privacy: .public), y: \(pos.y, privacy: .public)")

        // We need our current position to interpret the tap.
        guard let current = myPos else { return }

        // 1) Tapped on our own tile → interact (e.g. enter building / inspect).
        if pos.x == current.x && pos.y == current.y {

            // If this tile is already selected as a tile interaction, tapping again clears it.
            if let selectedPos = interactionPos,
               selectedPos.x == pos.x,
               selectedPos.y == pos.y,
               interactionKind == .tile {
                clearInteraction()
                log.info("Tapped own tile again — clearing interaction.")
            } else {
                // Selecting our own tile – open/refresh interaction on this tile.
                interactionPos = pos
                interactionKind = .tile

                if let building = buildingAt(x: pos.x, y: pos.y) {
                    log.info("Tapped own tile with building: \(building.type, privacy: .public) @ (\(building.root.x, privacy: .public), \(building.root.y, privacy: .public))")
                } else {
                    log.info("Tapped own tile with no building.")
                }
            }

            return
        }

        // 2) Tapped somewhere else → treat as potential move.
        let dx = pos.x - current.x
        let dy = pos.y - current.y

        // Allow 8-direction movement (king move): up/down/left/right/diagonals.
        let step = max(abs(dx), abs(dy))

        // Ignore taps that are too far away (no auto-move, no camera jump).
        guard step == 1 else {
            log.info("Tapped tile too far away for move: (\(pos.x, privacy: .public), \(pos.y, privacy: .public))")
            return
        }

        // Moving to an adjacent tile clears any current interaction/selection.
        clearInteraction()
        Task {
            await self.move(dx: dx, dy: dy)
        }
    }

    func handleZombieTapOnTile(pos: Pos, index: Int) {
        log.info("Tapped zombie emoji at (\(pos.x, privacy: .public), \(pos.y, privacy: .public)) index \(index, privacy: .public)")
        let zombiesHere = zombies.filter { z in
            z.alive && z.pos.x == pos.x && z.pos.y == pos.y
        }
        guard !zombiesHere.isEmpty else {
            clearInteraction()
            log.info("Zombie tap on tile — but no alive zombie found here.")
            return
        }
        let clampedIndex = max(0, min(index, zombiesHere.count - 1))
        let target = zombiesHere[clampedIndex]
        handleZombieTap(zombieId: target.id)
    }

    func handleZombieTap(zombieId: String) {
        // Find the concrete zombie by id first.
        guard let target = zombies.first(where: { $0.id == zombieId }) else {
            clearInteraction()
            log.info("Zombie tap by id — but no zombie found for id=\(zombieId, privacy: .public)")
            return
        }

        guard let current = myPos else { return }

        let dx = target.pos.x - current.x
        let dy = target.pos.y - current.y
        let distance = abs(dx) + abs(dy)

        if distance == 0 {
            // Same tile – toggle selection if already selected.
            if selectedZombieId == zombieId,
               interactionKind == .zombie,
               interactionPos?.x == target.pos.x,
               interactionPos?.y == target.pos.y {
                clearInteraction()
                log.info("Zombie tap by id on own tile again — clearing zombie interaction.")
            } else {
                interactionPos = target.pos
                interactionKind = .zombie
                selectedZombieId = zombieId
                log.info("Zombie tap by id on own tile — selecting zombie id=\(zombieId, privacy: .public).")
            }
        } else {
            // Too far for now, just feedback and clear selection.
            clearInteraction()
            log.info("Zombie tap by id too far away — would show 'out of range / no gun' message.")
        }
    }

    func handleZombieTap(pos: Pos) {
        log.info("Tapped zombie at (\(pos.x, privacy: .public), \(pos.y, privacy: .public))")
        guard let current = myPos else { return }

        let dx = pos.x - current.x
        let dy = pos.y - current.y
        let distance = abs(dx) + abs(dy)

        if distance == 0 {
            // Same tile – either clear or select zombie interaction on this tile.
            if let selectedPos = interactionPos,
               selectedPos.x == pos.x,
               selectedPos.y == pos.y,
               interactionKind == .zombie {
                clearInteraction()
                log.info("Zombie tap on own tile again — clearing zombie interaction.")
            } else {
                // Pick a concrete zombie on this tile so we can track it by id.
                let zombiesHere = zombies.filter { z in
                    z.alive && z.pos.x == pos.x && z.pos.y == pos.y
                }

                guard let target = zombiesHere.first else {
                    // No alive zombie here anymore (stale UI) → clear.
                    clearInteraction()
                    log.info("Zombie tap on own tile — but no alive zombie found here.")
                    return
                }

                interactionPos = pos
                interactionKind = .zombie
                selectedZombieId = target.id
                log.info("Zombie tap on own tile — selecting zombie id=\(target.id, privacy: .public).")
            }
        } else {
            // Too far for now, just feedback and clear selection.
            clearInteraction()
            log.info("Zombie tap too far away — would show 'out of range / no gun' message.")
        }
    }

    func handleHumanTap(pos: Pos) {
        log.info("Tapped human at (\(pos.x, privacy: .public), \(pos.y, privacy: .public))")
        guard let current = myPos else { return }

        let dx = pos.x - current.x
        let dy = pos.y - current.y
        let distance = abs(dx) + abs(dy)

        if distance == 0 {
            if let selectedPos = interactionPos,
               selectedPos.x == pos.x,
               selectedPos.y == pos.y,
               interactionKind == .human {
                clearInteraction()
                log.info("Human tap on own tile again — clearing human interaction.")
            } else {
                interactionPos = pos
                interactionKind = .human
                log.info("Human tap on own tile — opening human interaction.")
            }
        } else {
            clearInteraction()
            log.info("Human tap too far away — would show 'too far away' message.")
        }
    }

    func handleItemTap(pos: Pos) {
        log.info("Tapped item at (\(pos.x, privacy: .public), \(pos.y, privacy: .public))")
        guard let current = myPos else { return }

        let dx = pos.x - current.x
        let dy = pos.y - current.y
        let distance = abs(dx) + abs(dy)

        if distance == 0 {
            if let selectedPos = interactionPos,
               selectedPos.x == pos.x,
               selectedPos.y == pos.y,
               interactionKind == .item {
                clearInteraction()
                log.info("Item tap on own tile again — clearing item interaction.")
            } else {
                interactionPos = pos
                interactionKind = .item
                log.info("Item tap on own tile — opening item interaction.")
            }
        } else {
            clearInteraction()
            log.info("Item tap too far away — would show 'too far away to pick up' message.")
        }
    }
}
