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
    let hitTick: Int
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
    @State private var isHitAnimating = false

    init(
        x: Int,
        y: Int,
        isMe: Bool,
        isHighlighted: Bool,
        isTargetZombie: Bool,
        hitTick: Int,
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
        self.hitTick = hitTick
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
            background

            VStack(spacing: 4) {
                titleRow
                zombieRow
                humanRow
                itemRow
                coordsRow
            }
            .padding(4)
        }
        .frame(width: cellSize, height: cellSize)
        .contentShape(Rectangle())
        .onTapGesture {
            onTileTap?()
        }
        .onChange(of: hitTick) { _ in
            guard isTargetZombie else { return }
            isHitAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isHitAnimating = false
            }
        }
    }
}

private extension GridCellView {
    var background: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(backgroundColor)
    }

    var titleRow: some View {
        Text(tileLabel)
            .font(.system(size: min(cellSize * 0.35, 16),
                          weight: .bold,
                          design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var zombieRow: some View {
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
                        .scaleEffect(isTargetZombie && isHitAnimating ? 1.15 : 1.0)
                        .animation(.spring(response: 0.18, dampingFraction: 0.35), value: isHitAnimating)
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
    }

    @ViewBuilder
    var humanRow: some View {
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
    }

    @ViewBuilder
    var itemRow: some View {
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
    }

    var coordsRow: some View {
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
}

private extension GridCellView {
    var effectiveZombieCount: Int {
        max(zombieCount, hasZombie ? 1 : 0)
    }

    var backgroundColor: Color {
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
