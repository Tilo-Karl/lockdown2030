//
//  ItemComponent.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-15.
//


import Foundation

/// Item-only data (weapons/armor/consumables/world objects).
struct ItemComponent: Equatable {
    // Durability (new schema)
    let durabilityMax: Int?
    let currentDurability: Int?
    let broken: Bool?
    let destructible: Bool?

    // Equip metadata (optional; depends on item kind)
    let slot: String?      // e.g. "weapon", "body"
    let layer: String?     // e.g. "under", "outer", "main"

    // Common item stats (optional)
    let weight: Int?
    let value: Int?
    let armor: Int?
    let damage: Int?
    let range: Int?
}