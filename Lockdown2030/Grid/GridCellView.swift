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
    let buildingColor: Color?
    let terrainColor: Color?
    let tileLabel: String
    let hasZombie: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(backgroundColor)

            if hasZombie {
                Text("🧟")
                    .font(.system(size: min(cellSize * 0.7, 24)))
                    .shadow(radius: 2)
            }

            VStack(spacing: 1) {
                Text(tileLabel)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                Text("\(x),\(y)")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .multilineTextAlignment(.center)
            .padding(2)
        }
        .frame(width: cellSize, height: cellSize)
    }

    private var backgroundColor: Color {
        if isMe {
            return .blue.opacity(0.7)
        } else if isHighlighted {
            return .yellow.opacity(0.7)
        } else if let color = buildingColor {
            return color
        } else if let tColor = terrainColor {
            return tColor
        } else {
            return .gray.opacity(0.2)
        }
    }
}
