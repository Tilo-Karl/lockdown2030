//
//  GameVM+Tap.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//


extension GameVM {
    func handleTileTap(pos: Pos) {
        log.info("Tapped tile in handleTileTap — x: \(pos.x, privacy: .public), y: \(pos.y, privacy: .public)")

        // We need our current position to interpret the tap.
        guard let current = myPos else { return }

        // 1) Tapped on our own tile → interact (e.g. enter building)
        if pos.x == current.x && pos.y == current.y {
            // Selecting our own tile – open/refresh interaction on this tile.
            interactionPos = pos
            interactionKind = .tile

            if let building = buildingAt(x: pos.x, y: pos.y) {
                log.info("Tapped own tile with building: \(building.type, privacy: .public) @ (\(building.root.x, privacy: .public), \(building.root.y, privacy: .public))")
            } else {
                log.info("Tapped own tile, but no building here.")
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
            interactionPos = nil
            interactionKind = nil
            log.info("Tapped tile too far away for move: (\(pos.x, privacy: .public), \(pos.y, privacy: .public))")
            return
        }

        Task {
            await self.move(dx: dx, dy: dy)
        }
    }

    func handleZombieTap(pos: Pos) {
        log.info("Tapped zombie at (\(pos.x, privacy: .public), \(pos.y, privacy: .public))")
        guard let current = myPos else { return }

        let dx = pos.x - current.x
        let dy = pos.y - current.y
        let distance = abs(dx) + abs(dy)

        if distance == 0 {
            // Same tile – open zombie interaction panel.
            interactionPos = pos
            interactionKind = .zombie
            log.info("Zombie tap on own tile — opening zombie interaction.")
        } else {
            // Too far for now, just feedback and clear selection.
            interactionPos = nil
            interactionKind = nil
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
            interactionPos = pos
            interactionKind = .human
            log.info("Human tap on own tile — opening human interaction.")
        } else {
            interactionPos = nil
            interactionKind = nil
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
            interactionPos = pos
            interactionKind = .item
            log.info("Item tap on own tile — opening item interaction.")
        } else {
            interactionPos = nil
            interactionKind = nil
            log.info("Item tap too far away — would show 'too far away to pick up' message.")
        }
    }
}
