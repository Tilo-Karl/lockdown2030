//
//  GameVM+Engine+Attack.swift
//  Lockdown2030
//
//  Engine attack call + combat messaging.
//  IMPORTANT: targetType must be "zombie" | "player" | "human" | "item".
//

import Foundation

extension GameVM {

    @MainActor
    func attackEntity(targetId: String, targetType: String) async {
        guard !uid.isEmpty else { return }

        // New backend request is id-only (backend resolves type/kind by reading docs)
        let req = EngineAttackEntityReq(
            gameId: gameId,
            uid: uid,
            targetId: targetId
        )

        do {
            let res: EngineAttackEntityRes = try await CloudAPI.postJSON(
                to: CloudAPI.attackEntity,
                body: req
            )

            if res.ok {
                // Prefer server-reported type; fall back to the caller-provided targetType.
                let serverType = (res.target?.type ?? targetType).lowercased()
                let typeLabel = serverType.isEmpty ? "target" : serverType

                var parts: [String] = []

                if serverType == "item" {
                    if let dur = res.target?.currentDurability {
                        parts.append("You hit the \(typeLabel). Durability is now \(dur).")
                    } else {
                        parts.append("You hit the \(typeLabel).")
                    }

                    if res.target?.broken == true {
                        parts.append("The \(typeLabel) breaks.")
                    }
                } else {
                    if let hp = res.target?.currentHp {
                        parts.append("You hit the \(typeLabel). HP is now \(hp).")
                    } else {
                        parts.append("You hit the \(typeLabel).")
                    }

                    if res.target?.alive == false {
                        parts.append("The \(typeLabel) dies.")
                    }
                }

                self.pushCombat(parts.joined(separator: " "))
            } else {
                let reason = res.error ?? "unknown"
                let msg = String(format: GameStrings.combatAttackFailedReason, reason)
                self.pushCombat(msg)
            }

        } catch {
            self.pushCombat(GameStrings.combatAttackFailedNetwork)
        }
    }
}
