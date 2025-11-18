//
//  GameVM+Buildings.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

import Foundation

extension GameVM {
    
    struct Building: Identifiable, Codable, Equatable {
        let id: String
        let type: String
        let root: Pos
        let tiles: Int
        let floors: Int
    }
    
    func buildingAt(x: Int, y: Int) -> Building? {
        buildings.first { $0.root.x == x && $0.root.y == y }
    }
    
    /// The building (if any) at the player’s current position.
    var buildingHere: Building? {
        guard let pos = myPos else { return nil }
        return buildingAt(x: pos.x, y: pos.y)
    }

    /// The building the player is currently inside, if any.
    var activeBuilding: Building? {
        guard let id = activeBuildingId else { return nil }
        return buildings.first { $0.id == id }
    }

    /// Return a Color hex string for a building type, if available.
    func buildingColorHex(for type: String) -> String? {
        buildingColors[type]
    }

    /// Enter the building on the player’s current tile, if there is one.
    func enterBuildingHere() {
        guard let b = buildingHere else { return }
        activeBuildingId = b.id
        isInsideBuilding = true
    }

    /// Leave whatever building the player is currently inside, if any.
    func leaveBuilding() {
        activeBuildingId = nil
        isInsideBuilding = false
    }

    func parseBuildingsArray(_ arr: [[String: Any]]) -> [Building] {
        var result: [Building] = []
        for b in arr {
            guard let id = b["id"] as? String,
                  let type = b["type"] as? String,
                  let rootDict = b["root"] as? [String: Any],
                  let rx = rootDict["x"] as? Int,
                  let ry = rootDict["y"] as? Int,
                  let tiles = b["tiles"] as? Int,
                  let floors = b["floors"] as? Int else { continue }

            result.append(
                Building(
                    id: id,
                    type: type,
                    root: Pos(x: rx, y: ry),
                    tiles: tiles,
                    floors: floors
                )
            )
        }
        return result
    }

    @MainActor
    func loadMapBuildings(mapId: String) async {
        guard !mapId.isEmpty else {
            self.buildings = []
            return
        }
        do {
            let snap = try await db.collection("maps").document(mapId).getDocument()
            guard let data = snap.data(),
                  let meta = data["meta"] as? [String: Any],
                  let arr = meta["buildings"] as? [[String: Any]] else {
                self.buildings = []
                return
            }

            self.buildings = self.parseBuildingsArray(arr)
        } catch {
            self.buildings = []
        }
    }
}
