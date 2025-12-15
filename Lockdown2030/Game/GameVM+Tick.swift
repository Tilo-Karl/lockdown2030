//
//  GameVM+Tick.swift
//  Lockdown2030
//

import Foundation

extension GameVM {

    func tickGame() async {
        let req = EngineTickReq(gameId: gameId)

        do {
            let res: EngineTickRes = try await CloudAPI.postJSON(
                to: CloudAPI.tickGame,
                body: req
            )

            await MainActor.run {
                if res.ok {
                    var parts: [String] = []

                    if let playersUpdated = res.playersUpdated, playersUpdated > 0 {
                        parts.append("\(playersUpdated) player(s) updated")
                    }
                    if let zombiesMoved = res.zombiesMoved, zombiesMoved > 0 {
                        parts.append("\(zombiesMoved) zombie(s) moved")
                    }

                    let summary = parts.isEmpty
                        ? "Tick complete."
                        : "Tick: " + parts.joined(separator: ", ")

                    self.pushSystem(summary)
                } else {
                    let msg = (res.message?.isEmpty == false) ? res.message! : "Tick failed."
                    self.pushSystem(msg)
                }
            }

        } catch {
            await MainActor.run {
                self.pushSystem("Tick error: \(error.localizedDescription)")
            }
            log.error("tickGame failed: \(String(describing: error), privacy: .public)")
        }
    }
}
