//
//  GameVM+Engine+Attack.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-28.
//

import Foundation

extension GameVM {

    /// Unified engine attack: player (you) vs any target entity.
    /// `targetType` must match backend expectation: "zombie", "player", "item", etc.
    @MainActor
    func attackEntity(targetId: String, targetType: String) async {
        guard !uid.isEmpty else {
            print("AttackEntity error: missing uid")
            return
        }

        let req = EngineAttackEntityReq(
            gameId: gameId,
            uid: uid,               // ← was attackerUid: uid
            targetId: targetId,
            targetType: targetType
        )

        do {
            let res: EngineAttackEntityRes = try await CloudAPI.postJSON(
                to: CloudAPI.attackEntity,
                body: req
            )
            // ... rest of your method unchanged ...

            if res.ok {
                let typeLabel: String
                switch targetType {
                case "zombie": typeLabel = "zombie"
                case "player": typeLabel = "human"
                default:       typeLabel = "target"
                }

                var parts: [String] = []

                if res.hit == true {
                    if let dmg = res.damage {
                        if let hpAfter = res.hpAfter {
                            parts.append("You hit the \(typeLabel) for \(dmg). HP is now \(hpAfter).")
                        } else {
                            parts.append("You hit the \(typeLabel) for \(dmg).")
                        }
                    } else {
                        parts.append("You hit the \(typeLabel).")
                    }
                } else {
                    parts.append("Your attack missed the \(typeLabel).")
                }

                if res.dead == true {
                    parts.append("The \(typeLabel) dies.")
                }

                self.pushCombat(parts.joined(separator: " "))

            } else {
                let reason = res.error ?? "unknown"
                let msg = String(format: GameStrings.combatAttackFailedReason, reason)
                self.pushCombat(msg)
            }

        } catch {
            print("AttackEntity error:", error)
            self.pushCombat(GameStrings.combatAttackFailedNetwork)
        }
    }
}
