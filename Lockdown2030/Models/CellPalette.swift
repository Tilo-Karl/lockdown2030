import SwiftUI

struct CellPalette: Decodable {
    let version: Int
    let terrainColors: [String: String]
    let buildingColors: [String: String]
    let edgeColors: [String: String]

    static func colorFromHex(_ hex: String) -> Color {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }

        if cleaned.count == 8 {
            cleaned = String(cleaned.prefix(6))
        }

        guard cleaned.count == 6,
              let value = UInt64(cleaned, radix: 16) else {
            return Color.gray
        }

        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
    }
}
