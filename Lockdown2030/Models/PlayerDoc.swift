//
//  PlayerDoc.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//


struct PlayerDoc: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    var displayName: String?
    var pos: Pos?
    var hp: Int?
    var ap: Int?
    var alive: Bool?
}