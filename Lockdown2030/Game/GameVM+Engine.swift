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
                let pos = Pos(
                    x: res.x,
                    y: res.y,
                    z: myPos?.z ?? 0,
                    layer: myPos?.layer ?? 0
                )
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
    func move(to target: Pos) async {
        guard !uid.isEmpty else { return }
        guard let entityId = myActor?.id else { return }

        let req = EngineMoveReq(
            entityId: entityId,
            gameId: gameId,
            to: .init(x: target.x, y: target.y, z: target.z, layer: target.layer)
        )

        do {
            let res: EngineMoveRes = try await CloudAPI.postJSON(to: CloudAPI.move, body: req)

            if res.ok {
                // Move succeeded. Firestore listeners will update authoritative state.
                return
            }

            // Move failed (blocked / not allowed).
            showMoveBlocked(reason: res.reason ?? "blocked")
        } catch {
            showMoveBlocked(reason: "network error")
        }
    }
}
