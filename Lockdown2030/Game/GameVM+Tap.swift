//
//  GameVM+Tap.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

extension GameVM {
    func handleTileTap(pos: Pos) {
        print("Tapped tile:", pos.x, pos.y)

        guard let current = myPos else { return }

        let dx = pos.x - current.x
        let dy = pos.y - current.y

        guard dx != 0 || dy != 0 else { return }

        Task {
            await self.move(dx: dx, dy: dy)
        }
    }
}
