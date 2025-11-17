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
            case "MALL": return .purple.opacity(0.8)
            case "POLICE": return .red.opacity(0.8)
            case "RESTAURANT": return .orange.opacity(0.8)
            case "BUILD": return .green.opacity(0.8)
            default: return .gray.opacity(0.4)
            }
        } else {
            return .gray.opacity(0.2)
        }
    }
}
