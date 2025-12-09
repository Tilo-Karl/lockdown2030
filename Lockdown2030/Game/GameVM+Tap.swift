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
        log.info("Tapped tile in handleTileTap — x: \(pos.x, privacy: .public), y: \(pos.y, privacy: .public)")

        // We need our current position to interpret the tap.
        guard let current = myPos else { return }

        // 1) Tapped on our own tile → interact (e.g. enter building / inspect).
        if pos.x == current.x && pos.y == current.y {

            // If this tile is already selected as a tile interaction, tapping again clears it.
            if isSameTile(interactionPos, pos) && interactionKind == .tile {
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

    // MARK: - Zombie taps

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

        guard let distance = distanceFromMe(to: target.pos) else { return }

        if distance == 0 {
            // Same tile – toggle selection if already selected.
            if selectedZombieId == zombieId,
               interactionKind == .zombie,
               isSameTile(interactionPos, target.pos) {
                clearInteraction()
                log.info("Zombie tap by id on own tile again — clearing zombie interaction.")
            } else {
                selectZombie(target)
                log.info("Zombie tap by id on own tile — selecting zombie id=\(zombieId, privacy: .public).")
            }
        } else {
            // Too far for now, just feedback and clear selection.
            clearInteraction()
            log.info("Zombie tap by id too far away — would show 'out of range / no gun' message.")
        }
    }

    /// Fallback: tile-level zombie tap (no specific emoji index).
    func handleZombieTap(pos: Pos) {
        log.info("Tapped zombie at (\(pos.x, privacy: .public), \(pos.y, privacy: .public))")
        guard let distance = distanceFromMe(to: pos) else { return }

        if distance == 0 {
            // Same tile – either clear or select zombie interaction on this tile.
            if isSameTile(interactionPos, pos), interactionKind == .zombie {
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

                selectZombie(target, at: pos)
                log.info("Zombie tap on own tile — selecting zombie id=\(target.id, privacy: .public).")
            }
        } else {
            // Too far for now, just feedback and clear selection.
            clearInteraction()
            log.info("Zombie tap too far away — would show 'out of range / no gun' message.")
        }
    }

    // MARK: - Human taps (players / future NPCs)

    /// Tap on a specific human emoji in the grid (index within that tile).
    func handleHumanTapOnTile(pos: Pos, index: Int) {
        log.info("Tapped human emoji at (\(pos.x, privacy: .public), \(pos.y, privacy: .public)) index \(index, privacy: .public)")

        let humansHere = players.filter { p in
            p.userId != uid && p.pos?.x == pos.x && p.pos?.y == pos.y
        }

        guard !humansHere.isEmpty else {
            clearInteraction()
            log.info("Human tap on tile — but no human found here.")
            return
        }

        let clampedIndex = max(0, min(index, humansHere.count - 1))
        let target = humansHere[clampedIndex]
        handleHumanTap(humanId: target.userId)
    }

    /// Core handler: select / toggle a concrete human by id.
    func handleHumanTap(humanId: String) {
        guard let target = players.first(where: { $0.userId == humanId }),
              let targetPos = target.pos else {
            clearInteraction()
            log.info("Human tap by id — but no human found for id=\(humanId, privacy: .public)")
            return
        }

        guard let distance = distanceFromMe(to: targetPos) else { return }

        if distance == 0 {
            // Same tile – toggle selection if already selected.
            if selectedHumanId == humanId,
               interactionKind == .human,
               isSameTile(interactionPos, targetPos) {
                clearInteraction()
                log.info("Human tap by id on own tile again — clearing human interaction.")
            } else {
                selectHuman(target, at: targetPos)
                log.info("Human tap by id on own tile — selecting human id=\(humanId, privacy: .public).")
            }
        } else {
            clearInteraction()
            log.info("Human tap by id too far away — would show 'too far away' message.")
        }
    }

    /// Fallback: tap on the human row without per-emoji index.
    func handleHumanTap(pos: Pos) {
        log.info("Tapped human at (\(pos.x, privacy: .public), \(pos.y, privacy: .public))")
        guard let distance = distanceFromMe(to: pos) else { return }

        if distance == 0 {
            // All humans on this tile except me.
            let humansHere = players.filter { p in
                p.userId != uid && p.pos?.x == pos.x && p.pos?.y == pos.y
            }

            guard !humansHere.isEmpty else {
                clearInteraction()
                log.info("Human tap on own tile — but no human found here.")
                return
            }

            // If a human on this tile is already selected, second tap clears.
            if let selectedId = selectedHumanId,
               let selected = players.first(where: { $0.userId == selectedId }),
               let selPos = selected.pos,
               isSameTile(selPos, pos),
               interactionKind == .human {
                clearInteraction()
                log.info("Human tap on own tile again — clearing human interaction.")
            } else {
                // Otherwise select the first human on this tile.
                let target = humansHere.first!
                selectHuman(target, at: pos)
                log.info("Human tap on own tile — selecting human id=\(target.userId, privacy: .public).")
            }
        } else {
            clearInteraction()
            log.info("Human tap too far away — would show 'too far away' message.")
        }
    }

    // MARK: - Item taps

    func handleItemTap(pos: Pos) {
        log.info("Tapped item at (\(pos.x, privacy: .public), \(pos.y, privacy: .public))")
        guard let distance = distanceFromMe(to: pos) else { return }

        if distance == 0 {
            if isSameTile(interactionPos, pos), interactionKind == .item {
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

    // MARK: - Private helpers

    /// Manhattan distance from the player to a target position.
    private func distanceFromMe(to pos: Pos) -> Int? {
        guard let current = myPos else { return nil }
        return manhattanDistance(from: current, to: pos)
    }

    /// Simple manhattan distance between two positions.
    private func manhattanDistance(from a: Pos, to b: Pos) -> Int {
        abs(a.x - b.x) + abs(a.y - b.y)
    }

    /// Compare two positions for "same tile".
    private func isSameTile(_ lhs: Pos?, _ rhs: Pos?) -> Bool {
        guard let l = lhs, let r = rhs else { return false }
        return l.x == r.x && l.y == r.y
    }

    /// Compare an optional tile with a concrete position.
    private func isSameTile(_ lhs: Pos?, _ rhs: Pos) -> Bool {
        guard let l = lhs else { return false }
        return l.x == rhs.x && l.y == rhs.y
    }

    /// Select a zombie and wire up interaction state.
    private func selectZombie(_ zombie: Zombie, at pos: Pos? = nil) {
        let targetPos = pos ?? zombie.pos
        interactionPos = targetPos
        interactionKind = .zombie
        selectedZombieId = zombie.id
    }

    /// Select a human (player / future NPC) and wire up interaction state.
    private func selectHuman(_ human: PlayerDoc, at pos: Pos) {
        interactionPos = pos
        interactionKind = .human
        selectedHumanId = human.userId
    }
}
