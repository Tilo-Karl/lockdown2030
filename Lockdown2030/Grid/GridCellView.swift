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
    let isTargetZombie: Bool
    let building: GameVM.Building?
    let cellSize: CGFloat
    let buildingColor: Color?
    let tileColor: Color?
    let tileLabel: String
    let hasZombie: Bool
    var zombieCount: Int
    var otherPlayerCount: Int
    var humanCount: Int
    var itemCount: Int
    let onTileTap: (() -> Void)?
    let onZombieTap: (() -> Void)?
    let onHumanTap: (() -> Void)?
    let onItemTap: (() -> Void)?

    init(
        x: Int,
        y: Int,
        isMe: Bool,
        isHighlighted: Bool,
        isTargetZombie: Bool,
        building: GameVM.Building?,
        cellSize: CGFloat,
        buildingColor: Color?,
        tileColor: Color?,
        tileLabel: String,
        hasZombie: Bool,
        zombieCount: Int = 0,
        otherPlayerCount: Int = 0,
        humanCount: Int = 0,
        itemCount: Int = 0,
        onTileTap: (() -> Void)? = nil,
        onZombieTap: (() -> Void)? = nil,
        onHumanTap: (() -> Void)? = nil,
        onItemTap: (() -> Void)? = nil
    ) {
        self.x = x
        self.y = y
        self.isMe = isMe
        self.isHighlighted = isHighlighted
        self.isTargetZombie = isTargetZombie
        self.building = building
        self.cellSize = cellSize
        self.buildingColor = buildingColor
        self.tileColor = tileColor
        self.tileLabel = tileLabel
        self.hasZombie = hasZombie
        self.zombieCount = zombieCount
        self.otherPlayerCount = otherPlayerCount
        self.humanCount = humanCount
        self.itemCount = itemCount
        self.onTileTap = onTileTap
        self.onZombieTap = onZombieTap
        self.onHumanTap = onHumanTap
        self.onItemTap = onItemTap
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(backgroundColor)

            VStack(spacing: 4) {
                // Row 1 – tile label (building / terrain), always on top
                Text(tileLabel)
                    .font(.system(size: min(cellSize * 0.35, 16),
                                  weight: .bold,
                                  design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)

                // Row 2 – zombies (hostiles), if any
                if effectiveZombieCount > 0 {
                    HStack(spacing: 1) {
                        let shown = min(effectiveZombieCount, 3)
                        ForEach(0..<shown, id: \.self) { _ in
                            Text("🧟")
                                .font(.system(size: min(cellSize * 0.6, 28)))
                                .padding(2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(isTargetZombie ? Color.yellow.opacity(0.9) : Color.clear,
                                                lineWidth: 2)
                                )
                                .onTapGesture {
                                    onZombieTap?()
                                }
                        }
                        if effectiveZombieCount > shown {
                            Text("+\(effectiveZombieCount - shown)")
                                .font(.system(size: min(cellSize * 0.45, 16)))
                                .onTapGesture {
                                    onZombieTap?()
                                }
                        }
                        Spacer(minLength: 0)
                    }
                }

                // Row 3 – humans (other players / human NPCs), if any
                let totalHumans = otherPlayerCount + humanCount
                if totalHumans > 0 {
                    HStack(spacing: 2) {
                        Text("🙂\(totalHumans)")
                            .font(.system(size: min(cellSize * 0.3, 12)))
                            .onTapGesture {
                                onHumanTap?()
                            }
                        Spacer(minLength: 0)
                    }
                }

                // Row 4 – items on ground, if any
                if itemCount > 0 {
                    HStack(spacing: 2) {
                        Text("🎒\(itemCount)")
                            .font(.system(size: min(cellSize * 0.3, 12)))
                            .onTapGesture {
                                onItemTap?()
                            }
                        Spacer(minLength: 0)
                    }
                }

                // Row 5 – coords / debug info (always present for now)
                HStack(spacing: 2) {
                    Spacer(minLength: 0)
                    Text("\(x),\(y)")
                        .font(.system(size: min(cellSize * 0.25, 10),
                                      weight: .regular,
                                      design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(4)
        }
        .frame(width: cellSize, height: cellSize)
        .contentShape(Rectangle())
        .onTapGesture {
            onTileTap?()
        }
    }

    private var effectiveZombieCount: Int {
        max(zombieCount, hasZombie ? 1 : 0)
    }

    private var backgroundColor: Color {
        if isMe {
            return .blue.opacity(0.7)
        } else if isHighlighted {
            return .yellow.opacity(0.7)
        } else if let color = buildingColor {
            return color
        } else if let tColor = tileColor {
            return tColor
        } else {
            return .gray.opacity(0.2)
        }
    }
}
