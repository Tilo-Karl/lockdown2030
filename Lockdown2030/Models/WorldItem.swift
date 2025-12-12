//
//  WorldItem.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-12.
//


struct WorldItem: Identifiable {
    let id: String
    let type: String   // "ITEM"
    let kind: String   // "POLICE_WEAPON", "SHOP_MISC", etc.
    let hp: Int?
    let weight: Int?
    let armor: Int?
    let damage: Int?
    let pos: Pos
}