//
//  GameVM-Terrain.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-27.

import SwiftUI

extension GameVM {

    /// Terrain code at a given grid coordinate, e.g. "0", "1", "2"…
    func terrainCodeAt(x: Int, y: Int) -> String? {
        guard y >= 0, y < terrain.count else { return nil }
        let row = terrain[y]
        guard x >= 0, x < row.count else { return nil }
        let idx = row.index(row.startIndex, offsetBy: x)
        return String(row[idx])
    }

    /// Resolved Color for the terrain at (x,y) using the backend palette.
    func terrainColorAt(x: Int, y: Int) -> Color? {
        guard let code = terrainCodeAt(x: x, y: y) else { return nil }
        return terrainColor(for: code)
    }

    /// Resolved Color for a terrain code (e.g. "0" = ROAD) using terrainColors from Firestore.
    func terrainColor(for code: String) -> Color? {
        guard let hex = terrainColors[code] else { return nil }
        return terrainColorFromHex(hex)
    }

    // Local hex → Color helper for terrain palette
    private func terrainColorFromHex(_ hex: String) -> Color? {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
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
}

