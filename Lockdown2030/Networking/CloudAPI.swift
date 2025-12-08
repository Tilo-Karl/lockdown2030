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
    static let join   = "\(baseEngine)/join-game"
    static let move   = "\(baseEngine)/move-player"
    static let attack = "\(baseEngine)/attack-player"
    static let attackZombie = "\(baseEngine)/attack-zombie"
    static let tickGame = "\(baseEngine)/tick-game"

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

struct EngineAttackReq: Codable {
    let gameId: String
    let uid: String
    let targetUid: String
}

struct EngineAttackRes: Codable {
    let ok: Bool
    let targetHp: Int?
    let reason: String?
}

struct EngineAttackZombieReq: Codable {
    let gameId: String
    let attackerUid: String          // attacker UID
    let zombieId: String
    let damage: Int?
    let apCost: Int?
}

struct EngineAttackZombieRes: Codable {
    let ok: Bool
    let zombieHp: Int?
    let playerHp: Int?
    let zombieDidHit: Bool?
    let zombieDamage: Int?
    let reason: String?
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
