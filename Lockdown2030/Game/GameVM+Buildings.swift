//
//  GameVM+Buildings.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

import SwiftUI

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

    /// Resolve the actual Color for a building using the palette from Firestore.
    /// Returns nil if there is no building on this tile or no color in the palette.
    func buildingColor(for building: Building?) -> Color? {
        // No building here → let the cell fall back to neutral color
        guard let type = building?.type else {
            return nil
        }

        guard let hex = buildingColors[type] else {
            print("[DEBUG] no hex color found for type =", type)
            return nil
        }

        return colorFromHex(hex)
    }

    /// Convert a hex string from the backend (e.g. "#F97316" or "#F97316FF") into a SwiftUI Color.
    private func colorFromHex(_ hex: String) -> Color? {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }

        // Support both RGB ("RRGGBB") and RGBA ("RRGGBBAA") by dropping the alpha if present.
        if cleaned.count == 8 {
            cleaned = String(cleaned.prefix(6))
        }

        guard cleaned.count == 6,
              let value = UInt64(cleaned, radix: 16) else {
            return nil
        }

        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
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
}
