//
//  ActorComponent.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-15.
//


import Foundation

/// Actor-only data (humans + zombies).
struct ActorComponent: Equatable {
    // Player flag exists on ACTORS (human OR zombie)
    let isPlayer: Bool

    // Stats (new schema)
    let currentHp: Int?
    let maxHp: Int?
    let currentAp: Int?
    let maxAp: Int?

    // Optional combat tuning (may be absent on runtime docs; templates hold defaults)
    let armor: Int?
    let defense: Int?
    let attackDamage: Int?
    let hitChance: Double?
    let moveApCost: Int?
    let attackApCost: Int?

    // Social / AI hooks
    let faction: String?
    let hostileTo: [String]?

    // Equipment / inventory (keep flexible until you finalize JSON)
    let equipment: Equipment?
    let inventory: [String]?
}