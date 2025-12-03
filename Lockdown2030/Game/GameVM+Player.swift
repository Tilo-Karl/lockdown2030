//
//  GameVM+Player.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

import Foundation
import FirebaseFirestore

// MARK: - Player

extension GameVM {
  func startMyPlayerListener() {
    // Tear down any previous listener
    myPlayerListener?.remove()
    myPlayerListener = nil

    // If we don't have a uid yet, clear position and bail
    guard !uid.isEmpty else { myPos = nil; focusPos = nil; return }

    guard let playersColRef = playersColRef else {
      myPos = nil
      focusPos = nil
      return
    }

    let ref = playersColRef.document(uid)

    myPlayerListener = ref.addSnapshotListener { [weak self] snap, _ in
      guard let self else { return }
      guard let data = snap?.data(),
            let pos = data["pos"] as? [String: Any],
            let x = pos["x"] as? Int,
            let y = pos["y"] as? Int else {
        // If the doc disappeared or is missing pos, clear it
        self.myPos = nil
        self.focusPos = nil
        return
      }

      let newPos = Pos(x: x, y: y)
      // Only update if it changed, to avoid pointless scroll spam
      if self.myPos != newPos {
        self.myPos = newPos
        self.focusPos = newPos
      }
    }
  }

  func upsertMyPlayer() {
    guard !uid.isEmpty, let playersColRef = playersColRef else { return }
    let ref = playersColRef.document(uid)

    ref.setData([
      "userId": uid,
      "displayName": "Tester",
      "pos": ["x": 0, "y": 0],
      "hp": 100,
      "ap": 3,
      "alive": true
    ], merge: true)
  }
}
