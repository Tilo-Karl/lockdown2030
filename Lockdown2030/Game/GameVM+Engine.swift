//
//  GameVM+Engine.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

extension GameVM {

    @MainActor
    func joinGame() async {
        if Auth.auth().currentUser == nil {
            _ = try? await Auth.auth().signInAnonymously()
        }
        uid = Auth.auth().currentUser?.uid ?? uid
        if uid.isEmpty {
            print("Join error: missing uid")
            return
        }

        let req = EngineJoinReq(gameId: gameId, uid: uid, displayName: "Tester")
        do {
            let res: EngineJoinRes = try await CloudAPI.postJSON(to: CloudAPI.join, body: req)
            if res.ok {
                let pos = Pos(x: res.x, y: res.y)
                self.myPos = pos
                self.focusPos = pos
                self.startMyPlayerListener()
                print("Joined:", ["ok": 1, "x": res.x, "y": res.y])
            } else {
                print("Join failed")
            }
        } catch {
            print("Join error:", error)
        }
    }

    @MainActor
    func move(dx: Int, dy: Int) async {
        guard !uid.isEmpty else { print("Move error: missing uid"); return }
        let req = EngineMoveReq(gameId: gameId, uid: uid, dx: dx, dy: dy)
        do {
            let res: EngineMoveRes = try await CloudAPI.postJSON(to: CloudAPI.move, body: req)
            if res.ok {
                if let x = res.x, let y = res.y {
                    let pos = Pos(x: x, y: y)
                    self.myPos = pos
                    self.focusPos = pos
                    print("Move:", ["ok": 1, "x": x, "y": y])
                } else {
                    print("Move ok (no coordinates in response)")
                }
            } else {
                print("Move failed:", res.reason ?? "unknown")
            }
        } catch {
            print("Move error:", error)
        }
    }

    @MainActor
    func attack(target: String) async {
        guard !uid.isEmpty else { print("Attack error: missing uid"); return }
        let req = EngineAttackReq(gameId: gameId, uid: uid, targetUid: target)
        do {
            let res: EngineAttackRes = try await CloudAPI.postJSON(to: CloudAPI.attack, body: req)
            if res.ok {
                print("Attack:", ["ok": 1, "targetHp": res.targetHp ?? -1])
            } else {
                print("Attack failed:", res.reason ?? "unknown")
            }
        } catch {
            print("Attack error:", error)
        }
    }
}

