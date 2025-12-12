//
//  GameVM+Sign.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//
import FirebaseAuth
import FirebaseFirestore
import os.log

// MARK: - Auth & Game Loading

extension GameVM {
  @MainActor
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
      showSignedIn(uid: uid)
    }

    // Listen to games/{gameId} (map + meta)
    startGameDocListener()

    // Start listening to zombies for this game
    startZombiesListener()

    // Start listening to all players for this game
    startPlayersListener()
      
    startNpcsListener()
    startItemsListener()
  }
}
