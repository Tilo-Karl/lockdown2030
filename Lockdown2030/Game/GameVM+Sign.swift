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

        // Map id
        if let mid = data["mapId"] as? String {
          self.mapId = mid
        }

        // Prefer buildings from game.mapMeta (written by backend),
        // fall back to loading from the maps collection if missing.
        if let mapMeta = data["mapMeta"] as? [String: Any] {
          if let arr = mapMeta["buildings"] as? [[String: Any]] {
            self.buildings = self.parseBuildingsArray(arr)
          } else if !self.mapId.isEmpty {
            Task { await self.loadMapBuildings(mapId: self.mapId) }
          } else {
            self.buildings = []
          }

          // Optional backend palette, e.g. { "POLICE": "#123456", ... }
          if let palette = mapMeta["buildingPalette"] as? [String: String] {
            self.buildingColors = palette
          } else {
            self.buildingColors = [:]
          }

          // Terrain rows (array of strings, one per map row)
          if let terrainArr = mapMeta["terrain"] as? [String] {
            self.terrain = terrainArr
          } else {
            self.terrain = []
          }

          // Terrain color palette (hex strings keyed by terrain code "0","1",...)
          if let tPalette = mapMeta["terrainPalette"] as? [String: String] {
            self.terrainColors = tPalette
          } else if let tPaletteAny = mapMeta["terrainPalette"] as? [String: Any] {
            var result: [String: String] = [:]
            for (key, value) in tPaletteAny {
              if let s = value as? String {
                result[key] = s
              }
            }
            self.terrainColors = result
          } else {
            self.terrainColors = [:]
          }
        } else {
          self.buildings = []
          self.buildingColors = [:]
        }
      }
  }
}
