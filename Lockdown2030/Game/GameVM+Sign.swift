//  GameVM+Sign.swift
//  Lockdown2030
//
//  Auth + start listeners (NO NPC).

import FirebaseAuth
import os.log

extension GameVM {

    func signInAndLoad() async {
        if Auth.auth().currentUser == nil {
            do {
                _ = try await Auth.auth().signInAnonymously()
                log.info("Signed in anonymously ✅")
            } catch {
                log.error("Auth error: \(String(describing: error))")
                pushSystem("Auth error: \(String(describing: error))")
            }
        }

        uid = Auth.auth().currentUser?.uid ?? ""
        log.info("UID: \(self.uid, privacy: .public)")

        if !uid.isEmpty {
            status = "Signed in"
            pushSystem("Signed in: \(uid)")
        }

        startGameDocListener()
        startCellsListener()
        startPlayersListener()
        startHumansListener()
        startZombiesListener()
        startItemsListener()
    }
}
