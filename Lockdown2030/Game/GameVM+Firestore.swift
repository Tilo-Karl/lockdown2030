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

    /// Manually reload the current game document and re-apply basic meta fields.
    /// Handy if you ever want a "Refresh" button without restarting the app.
    @MainActor
    func reloadGameSnapshot() async {
        do {
            let snap = try await db.collection("games")
                .document(gameId)
                .getDocument()

            guard let data = snap.data() else { return }

            // Basic game fields
            self.gameName = (data["name"] as? String) ?? ""
            self.status   = (data["status"] as? String) ?? ""

            if let gs = data["gridsize"] as? [String: Any]
                ?? data["gridSize"] as? [String: Any] {
                self.gridW = gs["w"] as? Int ?? 0
                self.gridH = gs["h"] as? Int ?? 0
            }

            if let mid = data["mapId"] as? String {
                self.mapId = mid
            }

            // Optional map meta mirrored onto the game doc
            if let mapMeta = data["mapMeta"] as? [String: Any] {

                // Buildings (same shape as you already parse in signInAndLoad)
                if let arr = mapMeta["buildings"] as? [[String: Any]] {
                    self.buildings = self.parseBuildingsArray(arr)
                }

                // Building color palette (hex strings, e.g. "#F97316")
                if let palette = mapMeta["buildingPalette"] as? [String: String] {
                    self.buildingColors = palette
                } else if let paletteAny = mapMeta["buildingPalette"] as? [String: Any] {
                    var result: [String: String] = [:]
                    for (key, value) in paletteAny {
                        if let s = value as? String {
                            result[key] = s
                        }
                    }
                    self.buildingColors = result
                }

                // Terrain rows (array of strings)
                if let terrainArr = mapMeta["terrain"] as? [String] {
                    self.terrain = terrainArr
                }

                // Terrain color palette (hex strings, keyed by terrain code, e.g. "0","1","2"...)
                if let tPalette = mapMeta["terrainPalette"] as? [String: String] {
                    self.terrainColors = tPalette
                    print("[DEBUG] terrainPalette loaded:", tPalette)
                } else if let tPaletteAny = mapMeta["terrainPalette"] as? [String: Any] {
                    var result: [String: String] = [:]
                    for (key, value) in tPaletteAny {
                        if let s = value as? String {
                            result[key] = s
                        }
                    }
                    self.terrainColors = result
                    print("[DEBUG] terrainPalette loaded (from Any):", result)
                }
            }

        } catch {
            log.error("reloadGameSnapshot error: \(String(describing: error))")
        }
    }
}
