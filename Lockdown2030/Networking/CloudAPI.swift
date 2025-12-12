//
//  CloudAPI.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import Foundation

enum CloudAPI {
    // Engine base (update if your service URL changes)
    private static let baseEngine = "https://ld2030-52812703983.europe-west4.run.app/api/ld2030/v1"

    static let join        = "\(baseEngine)/join-game"
    static let move        = "\(baseEngine)/move-player"
    static let attackEntity = "\(baseEngine)/attack-entity"
    static let tickGame    = "\(baseEngine)/tick-game"

    /// POST JSON helper with typed request/response
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

// Unified attack-entity request
struct EngineAttackEntityReq: Codable {
    let gameId: String?
    let uid: String          // ← was attackerUid
    let targetId: String
    /// "player", "zombie", "human", "npc", "item", "object"
    let targetType: String
}

// Unified attack-entity response (matches current backend shape)
struct EngineAttackEntityRes: Codable {
    let ok: Bool
    let attackerUid: String?
    let targetId: String?
    let targetType: String?
    let hit: Bool?
    let damage: Int?
    let hpAfter: Int?
    let dead: Bool?
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
