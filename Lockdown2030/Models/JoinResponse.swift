//
//  JoinResponse.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import Foundation

struct JoinResponse: Decodable {
    let ok: Bool
    let x: Int?
    let y: Int?
    let hp: Int?
    let ap: Int?
    let reason: String?
}

func joinGame(
    uid: String,
    gameId: String = "lockdown2030",
    displayName: String? = nil,
    completion: @escaping (Result<JoinResponse, Error>) -> Void
) {
    guard let url = URL(string: "https://ld2030-52812703983.europe-west4.run.app/api/ld2030/v1/join-game") else {
        return completion(.failure(NSError(domain: "JoinGame", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bad URL"])))
    }

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "uid": uid,
        "gameId": gameId,
        "displayName": displayName ?? "Player"
    ]

    do {
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        return completion(.failure(error))
    }

    URLSession.shared.dataTask(with: req) { data, resp, err in
        if let err = err {
            return completion(.failure(err))
        }

        guard let data = data else {
            return completion(.failure(NSError(domain: "JoinGame", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data"])))
        }

        do {
            let res = try JSONDecoder().decode(JoinResponse.self, from: data)
            completion(.success(res))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}
