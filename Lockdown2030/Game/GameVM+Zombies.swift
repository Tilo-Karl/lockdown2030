//
//  GameVM+Zombies.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-27.
//

import Foundation

extension GameVM {
    /// Basic zombie model mirrored from the backend NPC schema.
    /// We keep this intentionally small for now – more fields can be added later.
    struct Zombie: Identifiable, Codable, Equatable {
        let id: String      // Firestore doc id
        let type: String    // e.g. "ZOMBIE"
        let kind: String    // e.g. "WALKER"
        var hp: Int
        var alive: Bool
        var pos: Pos        // grid position
    }

    /// All zombies on a given tile.
    func zombiesAt(x: Int, y: Int) -> [Zombie] {
        zombies.filter { $0.pos.x == x && $0.pos.y == y }
    }

    /// Quick check: is there at least one zombie here?
    func hasZombie(atX x: Int, y: Int) -> Bool {
        !zombiesAt(x: x, y: y).isEmpty
    }

    /// Convenience: pick one zombie on this tile (for UI actions like Attack).
    func primaryZombie(atX x: Int, y: Int) -> Zombie? {
        return zombiesAt(x: x, y: y).first
    }
}
