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
            if let building = buildingAt(x: pos.x, y: pos.y) {
                // For now, just log it; later we can set selectedBuilding / call an engine action.
                log.info("Tapped own tile with building: \(building.type, privacy: .public) @ (\(building.root.x, privacy: .public), \(building.root.y, privacy: .public))")
            } else {
                log.info("Tapped own tile, but no building here.")
            }
            return
        }

        // 2) Tapped somewhere else → treat as a move request.
        let dx = pos.x - current.x
        let dy = pos.y - current.y

        // If there's no movement, do nothing.
        guard dx != 0 || dy != 0 else { return }

        Task {
            await self.move(dx: dx, dy: dy)
        }
    }
}
