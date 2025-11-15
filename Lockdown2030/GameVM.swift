//
//  GameVM.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import os.log


final class GameVM: ObservableObject {
    
    func handleTileTap(pos: Pos) {
        // Translate tap on an absolute tile into a relative move request.
        print("Tapped tile:", pos.x, pos.y)
        
        // We can only compute a delta if we know our current position.
        guard let current = myPos else {
            return
        }
        
        let dx = pos.x - current.x
        let dy = pos.y - current.y
        
        // If there's no movement, do nothing.
        guard dx != 0 || dy != 0 else { return }
        
        Task {
            await self.move(dx: dx, dy: dy)
        }
    }
    
  @Published var uid: String = ""
  @Published var gameName: String = ""
  @Published var gridW = 0
  @Published var gridH = 0
  @Published var status: String = ""
  @Published var myPos: Pos? = nil
  @Published var focusPos: Pos? = nil
  private var myPlayerListener: ListenerRegistration?

  private let db = Firestore.firestore()
  private let gameId = "lockdown2030"
  private var gameListener: ListenerRegistration?
  private let log = Logger(subsystem: "Lockdown2030", category: "GameVM")

  init() {
    Task { await signInAndLoad() }
  }

  @MainActor
  func joinGame() async {
    // Ensure we have an anonymous Firebase UID
    if Auth.auth().currentUser == nil {
      _ = try? await Auth.auth().signInAnonymously()
    }
    uid = Auth.auth().currentUser?.uid ?? uid
    if uid.isEmpty {
      print("Join error: missing uid")
      return
    }

    // Call the Engine join endpoint
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
          // Backend reported ok but didn't send coordinates; Firestore listener will update myPos.
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

  @MainActor
  private func signInAndLoad() async {
    if Auth.auth().currentUser == nil {
      do {
        _ = try await Auth.auth().signInAnonymously()
        log.info("Signed in anonymously ✅")
      } catch {
        log.error("Auth error: \(String(describing: error))")
      }
    }

    uid = Auth.auth().currentUser?.uid ?? ""
    log.info("UID: \(self.uid, privacy: .public)")

    gameListener = db.collection("games").document(gameId)
      .addSnapshotListener { [weak self] snap, err in
        guard let self else { return }
        if let err = err {
          log.error("Game listener error: \(err.localizedDescription)")
          return
        }
        guard let data = snap?.data() else { return }

        self.gameName = (data["name"] as? String) ?? ""
        self.status   = (data["status"] as? String) ?? ""

        if let gs = data["gridsize"] as? [String: Any] ??
                    data["gridSize"] as? [String: Any] {
          self.gridW = gs["w"] as? Int ?? 0
          self.gridH = gs["h"] as? Int ?? 0
        }
      }
  }

    private func startMyPlayerListener() {
      // Tear down any previous listener
      myPlayerListener?.remove()
      myPlayerListener = nil

      // If we don't have a uid yet, clear position and bail
      guard !uid.isEmpty else { myPos = nil; focusPos = nil; return }

      let ref = db.collection("games").document(gameId)
        .collection("players").document(uid)

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
    guard !uid.isEmpty else { return }
    let ref = db.collection("games").document(gameId)
      .collection("players").document(uid)

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
