//
//  Entity.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-15.
//


import Foundation

/// One canonical client model for anything on the map.
/// Backed directly by Firestore docs (players/zombies/humans/items collections).
struct Entity: Identifiable, Equatable {
    let id: String

    // Discriminators (Firestore truth)
    let type: EntityType
    let kind: String          // "PLAYER", "WALKER", "RUNNER", "TRADER", "PISTOL", etc.

    // World/runtime
    let pos: Pos?
    let createdAt: Date?
    let updatedAt: Date?

    // Optional lifecycle flags (actors)
    let alive: Bool?
    let downed: Bool?
    let despawnAt: Int64?     // ms epoch if you use it

    // Components (present depending on type/kind)
    let actor: ActorComponent?
    let item: ItemComponent?

    // Convenience
    var isActor: Bool { type == .human || type == .zombie }
    var isItem: Bool { type == .item }
}