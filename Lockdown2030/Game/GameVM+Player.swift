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
      guard let data = snap?.data() else {
        // Doc disappeared
        self.myPos = nil
        self.focusPos = nil
        self.myPlayer = nil
        return
      }

      // Position
      var newPos: Pos? = nil
      if let pos = data["pos"] as? [String: Any],
         let x = pos["x"] as? Int,
         let y = pos["y"] as? Int {
        newPos = Pos(x: x, y: y)
      }

      // HP / AP / alive
      let hp = data["hp"] as? Int
      let ap = data["ap"] as? Int
      let alive = data["alive"] as? Bool
      let displayName = data["displayName"] as? String

      // Update myPlayer snapshot used by UI
      self.myPlayer = PlayerDoc(
        userId: self.uid,
        displayName: displayName,
        pos: newPos,
        hp: hp,
        ap: ap,
        alive: alive
      )

      // Update map focus if position changed
      if let newPos {
        if self.myPos != newPos {
          self.myPos = newPos
          self.focusPos = newPos
        }
      } else {
        self.myPos = nil
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
