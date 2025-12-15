//
//  GridCellView.swift
//  Lockdown2030
//

import SwiftUI

struct GridCellView: View {
    let x: Int
    let y: Int
    let isMe: Bool
    let isHighlighted: Bool
    let isTargetSelectedEntity: Bool
    let hitTick: Int

    let building: GameVM.Building?
    let cellSize: CGFloat
    let buildingColor: Color?
    let tileColor: Color?
    let tileLabel: String

    let zombieIds: [String]
    let humanIds: [String]
    let itemIds: [String]

    let selectedEntityId: String?

    let zombieCount: Int
    let humanCount: Int
    let itemCount: Int

    let onTileTap: (() -> Void)?
    let onEntityTap: ((String) -> Void)?

    // MUST NOT be private because GridCellView+EntityTap reads it.
    @State var isHitAnimating = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 2) {
                Text(tileLabel)
                    .font(.system(size: min(cellSize * 0.3, 14), weight: .bold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                // rows rendered by extension
                entityRow(
                    emoji: "🧟",
                    ids: zombieIds,
                    fontSize: min(cellSize * 0.55, 26),
                    shownLimit: 3,
                    spacing: 1,
                    onTapId: onEntityTap
                )

                entityRow(
                    emoji: "🙂",
                    ids: humanIds,
                    fontSize: min(cellSize * 0.35, 18),
                    shownLimit: 3,
                    spacing: 1,
                    onTapId: onEntityTap
                )

                entityRow(
                    emoji: "🎒",
                    ids: itemIds,
                    fontSize: min(cellSize * 0.35, 18),
                    shownLimit: 3,
                    spacing: 2,
                    onTapId: onEntityTap
                )

                Spacer(minLength: 0)

                Text("\(x),\(y)")
                    .font(.system(size: min(cellSize * 0.22, 10), design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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

    private var background: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(
                isMe ? Color.blue.opacity(0.7) :
                isHighlighted ? Color.yellow.opacity(0.6) :
                buildingColor ?? tileColor ?? Color.gray.opacity(0.2)
            )
    }
}
