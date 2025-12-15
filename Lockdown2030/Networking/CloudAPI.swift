//
//  CloudAPI.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import Foundation

enum CloudAPI {
    private static let baseEngine = "https://ld2030-52812703983.europe-west4.run.app/api/ld2030/v1"

    static let join         = "\(baseEngine)/join-game"
    static let move         = "\(baseEngine)/move-player"
    static let attackEntity = "\(baseEngine)/attack-entity"
    static let tickGame     = "\(baseEngine)/tick-game"
    static let equipItem    = "\(baseEngine)/equip-item"
    static let unequipItem  = "\(baseEngine)/unequip-item"

    static func postJSON<T: Encodable, R: Decodable>(to url: String, body: T) async throws -> R {
        var req = URLRequest(url: URL(string: url)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse else {
            print("CloudAPI.postJSON — non-HTTP response from", url)
            throw URLError(.badServerResponse)
        }

        if !(200..<300).contains(http.statusCode) {
            let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            print("CloudAPI.postJSON — HTTP status", http.statusCode, "from", url)
            print("CloudAPI.postJSON — response body:", bodyText)
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(R.self, from: data)
    }
}

// MARK: - DTOs

struct EngineJoinReq: Codable {
    let gameId: String
    let uid: String
    let displayName: String
}

struct EngineJoinRes: Codable {
    let ok: Bool
    let x: Int
    let y: Int
    let hp: Int?
    let ap: Int?
    let reason: String?
}

struct EngineMoveReq: Codable {
    let gameId: String
    let uid: String
    let dx: Int
    let dy: Int
}

struct EngineMoveRes: Codable {
    let ok: Bool
    let x: Int?
    let y: Int?
    let reason: String?
}

// Attack (id-only)
struct EngineAttackEntityReq: Codable {
    let gameId: String?
    let uid: String
    let targetId: String
}

struct EngineAttackEntityRes: Codable {
    struct ActorSnap: Codable {
        let id: String?
        let type: String?
        let kind: String?
        let isPlayer: Bool?
        let currentHp: Int?
        let currentAp: Int?
    }

    struct TargetSnap: Codable {
        let id: String?
        let type: String?
        let kind: String?
        let currentHp: Int?
        let currentDurability: Int?
        let alive: Bool?
        let broken: Bool?
    }

    let ok: Bool
    let attacker: ActorSnap?
    let target: TargetSnap?
    let error: String?
}

// Equip / Unequip
struct EngineEquipItemReq: Codable {
    let gameId: String?
    let uid: String
    let itemId: String
}

struct EngineEquipItemRes: Codable {
    let ok: Bool
    let error: String?
}

struct EngineUnequipItemReq: Codable {
    let gameId: String?
    let uid: String
    let itemId: String
}

struct EngineUnequipItemRes: Codable {
    let ok: Bool
    let error: String?
}

struct EngineTickReq: Codable {
    let gameId: String
}

struct EngineTickRes: Codable {
    let ok: Bool
    let gameId: String?
    let zombiesMoved: Int?
    let zombiesTotal: Int?
    let playersUpdated: Int?
    let message: String?
}
