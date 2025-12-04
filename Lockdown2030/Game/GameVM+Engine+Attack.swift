//
//  GameVM+Engine+Attack.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-28.
//

import Foundation

extension GameVM {

    @MainActor
    func attack(target: String) async {
        guard !uid.isEmpty else { print("Attack error: missing uid"); return }
        let req = EngineAttackReq(gameId: gameId, uid: uid, targetUid: target)
        do {
            let res: EngineAttackRes = try await CloudAPI.postJSON(
                to: CloudAPI.attack,
                body: req
            )
            if res.ok {
                print("Attack:", ["ok": 1, "targetHp": res.targetHp ?? -1])
            } else {
                print("Attack failed:", res.reason ?? "unknown")
            }
        } catch {
            print("Attack error:", error)
        }
    }

    @MainActor
    func attackZombie(zombieId: String, damage: Int = 10, apCost: Int = 1) async {
        guard !uid.isEmpty else {
            print("AttackZombie error: missing uid")
            return
        }

        let req = EngineAttackZombieReq(
            gameId: gameId,
            attackerUid: uid,
            zombieId: zombieId,
            damage: damage,
            apCost: apCost
        )

        do {
            let res: EngineAttackZombieRes = try await CloudAPI.postJSON(
                to: CloudAPI.attackZombie,
                body: req
            )

            if res.ok {
                let zHp = res.zombieHp
                let pHp = res.playerHp
                let zHit = res.zombieDidHit ?? false
                let zDmg = res.zombieDamage ?? 0

                print("Attack zombie:", [
                    "ok": 1,
                    "zombieHp": zHp ?? -1,
                    "playerHp": pHp ?? -1,
                    "zombieDidHit": zHit,
                    "zombieDamage": zDmg
                ])

                var parts: [String] = []

                if let zHp = zHp {
                    parts.append("You hit the zombie for \(damage) HP (now \(zHp) HP).")
                } else {
                    parts.append("You swing at the zombie.")
                }

                if zHit {
                    if let pHp = pHp {
                        parts.append("The zombie hits you back for \(zDmg) HP (you now at \(pHp) HP).")
                    } else {
                        parts.append("The zombie hits you back for \(zDmg) HP.")
                    }
                }

                self.setLastEventMessage(parts.joined(separator: " "))

            } else {
                // Prefer backend error if reason is just "internal"
                let backendReason = res.reason
                let backendError  = res.error
                
                print("Attack zombie failed. reason=\(backendReason ?? "nil"), error=\(backendError ?? "nil")")
                
                let reasonToShow: String
                if backendReason == "internal" || backendReason == nil {
                    reasonToShow = backendError ?? "internal"
                } else {
                    reasonToShow = backendReason ?? "unknown"
                }
                
                self.setLastEventMessage("Attack failed: \(reasonToShow)")
            }
        } catch {
            print("Attack zombie error:", error)
            self.setLastEventMessage("Attack failed: network error")
        }
    }
}
