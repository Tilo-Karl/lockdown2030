//
//  Npc.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-12.
//


struct Npc: Identifiable {
    let id: String
    let type: String   // "HUMAN_NPC"
    let kind: String   // "CIVILIAN" / "RAIDER" / "TRADER"
    let faction: String?
    let hp: Int
    let alive: Bool
    let pos: Pos
}