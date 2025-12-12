//
//  GridCellView.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

import SwiftUI

struct GridCellView: View {
    let x: Int
    let y: Int
    let isMe: Bool
    let isHighlighted: Bool

    /// Whether the currently selected entity is on this tile (for hit animation trigger).
    let isTargetSelectedEntity: Bool
    let hitTick: Int

    let building: GameVM.Building?
    let cellSize: CGFloat
    let buildingColor: Color?
    let tileColor: Color?
    let tileLabel: String

    let hasZombie: Bool
    let zombieIds: [String]
    let humanIds: [String]

    /// Single selected entity id (zombie/human/item) for highlight only.
    let selectedEntityId: String?

    var zombieCount: Int
    var otherPlayerCount: Int
    var humanCount: Int
    var itemCount: Int

    let onTileTap: (() -> Void)?
    let onZombieTap: ((Int) -> Void)?
    let onHumanTap: ((String) -> Void)?
    let onItemTap: (() -> Void)?

    @State private var isHitAnimating = false

    init(
        x: Int,
        y: Int,
        isMe: Bool,
        isHighlighted: Bool,
        isTargetSelectedEntity: Bool,
        hitTick: Int,
        building: GameVM.Building?,
        cellSize: CGFloat,
        buildingColor: Color?,
        tileColor: Color?,
        tileLabel: String,
        hasZombie: Bool,
        zombieIds: [String] = [],
        humanIds: [String] = [],
        selectedEntityId: String? = nil,
        zombieCount: Int = 0,
        otherPlayerCount: Int = 0,
        humanCount: Int = 0,
        itemCount: Int = 0,
        onTileTap: (() -> Void)? = nil,
        onZombieTap: ((Int) -> Void)? = nil,
        onHumanTap: ((String) -> Void)? = nil,
        onItemTap: (() -> Void)? = nil
    ) {
        self.x = x
        self.y = y
        self.isMe = isMe
        self.isHighlighted = isHighlighted
        self.isTargetSelectedEntity = isTargetSelectedEntity
        self.hitTick = hitTick
        self.building = building
        self.cellSize = cellSize
        self.buildingColor = buildingColor
        self.tileColor = tileColor
        self.tileLabel = tileLabel
        self.hasZombie = hasZombie
        self.zombieIds = zombieIds
        self.humanIds = humanIds
        self.selectedEntityId = selectedEntityId
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
        .onTapGesture { onTileTap?() }
        .onChange(of: hitTick) { _ in
            guard isTargetSelectedEntity else { return }
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
            .font(
                .system(
                    size: min(cellSize * 0.35, 16),
                    weight: .bold,
                    design: .monospaced
                )
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var zombieRow: some View {
        if effectiveZombieCount > 0 {
            HStack(spacing: 1) {
                let shown = min(effectiveZombieCount, 3)

                ForEach(0..<shown, id: \.self) { index in
                    let isSelectedEmoji =
                        index < zombieIds.count &&
                        selectedEntityId == zombieIds[index]

                    Text("🧟")
                        .font(.system(size: min(cellSize * 0.6, 28)))
                        .padding(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(
                                    isSelectedEmoji ? Color.yellow.opacity(0.9) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(isSelectedEmoji && isHitAnimating ? 1.15 : 1.0)
                        .animation(
                            .spring(response: 0.18, dampingFraction: 0.35),
                            value: isHitAnimating
                        )
                        .onTapGesture { onZombieTap?(index) }
                }

                if effectiveZombieCount > shown {
                    Text("+\(effectiveZombieCount - shown)")
                        .font(.system(size: min(cellSize * 0.45, 16)))
                        .onTapGesture { onZombieTap?(0) }
                }

                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    var humanRow: some View {
        let totalHumans = humanIds.count
        if totalHumans > 0 {
            HStack(spacing: 1) {
                let shown = min(totalHumans, 3)

                ForEach(0..<shown, id: \.self) { index in
                    let isSelected =
                        index < humanIds.count &&
                        selectedEntityId == humanIds[index]

                    Text("🙂")
                        .font(.system(size: min(cellSize * 0.3, 18)))
                        .padding(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(
                                    isSelected ? Color.yellow.opacity(0.9) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .onTapGesture {
                            if index < humanIds.count {
                                onHumanTap?(humanIds[index])
                            }
                        }
                }

                if totalHumans > shown {
                    Text("+\(totalHumans - shown)")
                        .font(.system(size: min(cellSize * 0.3, 12)))
                        .onTapGesture {
                            if let first = humanIds.first {
                                onHumanTap?(first)
                            }
                        }
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
                    .onTapGesture { onItemTap?() }
                Spacer(minLength: 0)
            }
        }
    }

    var coordsRow: some View {
        HStack(spacing: 2) {
            Spacer(minLength: 0)
            Text("\(x),\(y)")
                .font(
                    .system(
                        size: min(cellSize * 0.25, 10),
                        weight: .regular,
                        design: .monospaced
                    )
                )
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
