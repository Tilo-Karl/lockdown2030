//
//  GameVM+Tick.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-04.
//

import Foundation

extension GameVM {
  /// Manually trigger one game tick via the backend tick engine.
  /// - Calls /tick-game with the current gameId.
  /// - Backend will regen player AP/HP and move zombies.
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

          let summary: String
          if parts.isEmpty {
            summary = "Tick complete."
          } else {
            summary = "Tick: " + parts.joined(separator: ", ")
          }

          self.setLastEventMessage(summary)
        } else {
          let msg = res.message?.isEmpty == false ? res.message! : "Tick failed."
          self.setLastEventMessage(msg)
        }
      }
    } catch {
      await MainActor.run {
        self.setLastEventMessage("Tick error: \(error.localizedDescription)")
      }
      log.error("tickGame failed: \(String(describing: error), privacy: .public)")
    }
  }
}
