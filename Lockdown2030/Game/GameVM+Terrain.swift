//
//  GameVM-Terrain.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-27.

import SwiftUI

extension GameVM {

    /// Tile code at a given grid coordinate, e.g. "0", "1", "2"…
    func tileCodeAt(x: Int, y: Int) -> String? {
        let rows = tileRows
        guard !rows.isEmpty else { return nil }
        guard y >= 0, y < rows.count else { return nil }

        let row = rows[y]
        guard x >= 0, x < row.count else { return nil }

        let idx = row.index(row.startIndex, offsetBy: x)
        return String(row[idx])
    }

    /// Resolved Color for the tile at (x,y) using the backend tile meta palette.
    func tileColorAt(x: Int, y: Int) -> Color? {
        guard let code = tileCodeAt(x: x, y: y) else { return nil }
        return tileColor(for: code)
    }

    /// Resolved Color for a tile code (e.g. "0" = ROAD) using tileMeta from Firestore.
    func tileColor(for code: String) -> Color? {
        guard let meta = tileMeta[code] else { return nil }
        return tileColorFromHex(meta.colorHex)
    }

    // Local hex → Color helper for tile colors
    private func tileColorFromHex(_ hex: String) -> Color? {
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
