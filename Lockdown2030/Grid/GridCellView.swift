//
//  GridCellView.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

import SwiftUI

// MARK: - Grid Cell

struct GridCellView: View {
    let x: Int
    let y: Int
    let isMe: Bool
    let isHighlighted: Bool
    let building: GameVM.Building?
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: cellSize, height: cellSize)
                .cornerRadius(4)

            Text("\(x),\(y)")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .minimumScaleFactor(0.5)
        }
    }

    private var backgroundColor: Color {
        if isMe {
            return .blue.opacity(0.7)
        } else if isHighlighted {
            return .yellow.opacity(0.7)
        } else if let b = building {
            switch b.type {
            case "POLICE":
                return .blue.opacity(0.8)            // police → blue
            case "FIRE_STATION":
                return .red.opacity(0.8)             // fire → red
            case "HOSPITAL":
                return .pink.opacity(0.7)            // hospitals often use red/pink/white signals
            case "CLINIC":
                return .mint.opacity(0.7)
            case "PHARMACY":
                return .green.opacity(0.7)           // medical-green cross vibe

            case "HOUSE":
                return .brown.opacity(0.6)
            case "APARTMENT":
                return .yellow.opacity(0.6)
            case "OFFICE":
                return .gray.opacity(0.6)
            case "WAREHOUSE":
                return .gray.opacity(0.5)

            case "SHOP", "MALL":
                return .purple.opacity(0.7)          // mall / shop → same color

            case "PARKING":
                return .black.opacity(0.4)
            case "GAS_STATION":
                return .orange.opacity(0.8)

            case "SCHOOL":
                return .indigo.opacity(0.7)

            case "SAFEHOUSE":
                return .teal.opacity(0.8)
            case "OUTPOST":
                return .cyan.opacity(0.8)
            case "BUNKER":
                return .gray.opacity(0.8)
            case "HQ":
                return .red.opacity(0.9)

            case "BUILD":
                return .green.opacity(0.8)           // generic building

            default:
                return .gray.opacity(0.4)
            }
        } else {
            return .gray.opacity(0.2)
        }
    }
}
