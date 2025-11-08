//
//  Pos.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import Foundation

struct Pos: Codable, Hashable { var x: Int; var y: Int }

struct PlayerDoc: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    var displayName: String?
    var pos: Pos?
    var hp: Int?
    var ap: Int?
    var alive: Bool?
}

struct JoinRequest: Codable { let uid: String; let displayName: String }
struct MoveRequest: Codable { let uid: String; let dx: Int; let dy: Int }
struct AttackRequest: Codable { let uid: String; let targetUid: String }

// If you already have JoinResponse.swift, keep that one and remove duplicates.
