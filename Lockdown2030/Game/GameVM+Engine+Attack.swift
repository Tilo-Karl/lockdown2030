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
                let hp = res.targetHp ?? -1
                print("Attack:", ["ok": 1, "targetHp": hp])
                // Keep this simple success line hard-coded for now.
                self.pushCombat("Attack succeeded. Target HP is now \(hp).")
            } else {
                let reason = res.reason ?? "unknown"
                print("Attack failed:", reason)
                let msg = String(format: GameStrings.combatAttackFailedReason, reason)
                self.pushCombat(msg)
            }
        } catch {
            print("Attack error:", error)
            self.pushCombat(GameStrings.combatAttackFailedNetwork)
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
                var zombieDied = false

                if let zHp = zHp {
                    let hitLine = String(
                        format: GameStrings.combatHitWithRemainingHp,
                        damage,
                        zHp
                    )
                    parts.append(hitLine)
                    if zHp <= 0 {
                        zombieDied = true
                    }
                } else {
                    parts.append(GameStrings.combatSwingAtZombie)
                }

                if zHit {
                    if let pHp = pHp {
                        parts.append(
                            String(
                                format: GameStrings.combatZombieHitsYouWithRemainingHp,
                                zDmg,
                                pHp
                            )
                        )
                    } else {
                        parts.append(
                            String(
                                format: GameStrings.combatZombieHitsYou,
                                zDmg
                            )
                        )
                    }
                }

                if zombieDied {
                    parts.append(GameStrings.combatZombieDies)
                }

                self.pushCombat(parts.joined(separator: " "))

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
                
                let msg = String(format: GameStrings.combatAttackFailedReason, reasonToShow)
                self.pushCombat(msg)
            }
        } catch {
            print("Attack zombie error:", error)
            self.pushCombat(GameStrings.combatAttackFailedNetwork)
        }
    }
}
