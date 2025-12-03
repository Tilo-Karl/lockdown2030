//
//  GameVM+Firestore.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-19.
//

import Foundation
import FirebaseFirestore
import os.log

extension GameVM {

    /// Start listening to the zombies subcollection for this game.
    /// Populates `zombies` with all current zombie documents.
    @MainActor
    func startZombiesListener() {
        guard !gameId.isEmpty else { return }

        // Tear down any previous listener first
        zombieListener?.remove()
        zombieListener = db.collection("games")
            .document(gameId)
            .collection("zombies")
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }

                if let err = err {
                    log.error("Zombie listener error: \(err.localizedDescription)")
                    return
                }

                let docs = snap?.documents ?? []
                let mapped: [Zombie] = docs.compactMap { doc in
                    let data = doc.data()

                    guard
                        let type = data["type"] as? String,
                        let kind = data["kind"] as? String,
                        let hp = data["hp"] as? Int,
                        let alive = data["alive"] as? Bool,
                        let pos = data["pos"] as? [String: Any],
                        let x = pos["x"] as? Int,
                        let y = pos["y"] as? Int
                    else {
                        return nil
                    }

                    return Zombie(
                        id: doc.documentID,
                        type: type,
                        kind: kind,
                        hp: hp,
                        alive: alive,
                        pos: Pos(x: x, y: y)
                    )
                }

                DispatchQueue.main.async {
                    self.zombies = mapped
                }
            }
    }

    /// Stop listening to the zombies subcollection.
    @MainActor
    func stopZombiesListener() {
        zombieListener?.remove()
        zombieListener = nil
    }
}
