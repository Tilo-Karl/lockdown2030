// GameVM+Engine.swift

import Foundation
import FirebaseAuth
import FirebaseFirestore

extension GameVM {

    @MainActor
    func joinGame() async {
        if Auth.auth().currentUser == nil {
            _ = try? await Auth.auth().signInAnonymously()
        }

        uid = Auth.auth().currentUser?.uid ?? ""
        guard !uid.isEmpty else {
            showJoinFailed(reason: "missing uid")
            return
        }

        let req = EngineJoinReq(gameId: gameId, uid: uid, displayName: "Tester")

        do {
            let res: EngineJoinRes = try await CloudAPI.postJSON(to: CloudAPI.join, body: req)
            if res.ok {
                let pos = Pos(x: res.x, y: res.y)
                myPos = pos
                focusPos = pos
                startMyPlayerListener()
                showJoinSuccess(x: pos.x, y: pos.y)
            } else {
                showJoinFailed(reason: res.reason ?? "unknown")
            }
        } catch {
            showJoinFailed(reason: "network error")
        }
    }

    @MainActor
    func move(dx: Int, dy: Int) async {
        guard !uid.isEmpty else { return }

        let req = EngineMoveReq(gameId: gameId, uid: uid, dx: dx, dy: dy)

        do {
            let res: EngineMoveRes = try await CloudAPI.postJSON(to: CloudAPI.move, body: req)

            if res.ok {
                // Move succeeded. Some backends return no coordinates; Firestore listeners will update myPos.
                if let x = res.x, let y = res.y {
                    let pos = Pos(x: x, y: y)
                    myPos = pos
                    focusPos = pos
                }
                return
            }

            // Move failed (blocked / not allowed).
            showMoveBlocked(reason: res.reason ?? "blocked")
        } catch {
            showMoveBlocked(reason: "network error")
        }
    }
}
