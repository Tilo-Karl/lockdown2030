// GridCellView+EntityTap.swift  (FIX: missing returns)

import SwiftUI

extension GridCellView {

    @ViewBuilder
    func entityRow(
        emoji: String,
        ids: [String],
        fontSize: CGFloat,
        shownLimit: Int = 3,
        spacing: CGFloat = 1,
        onTapId: ((String) -> Void)?
    ) -> some View {

        if !ids.isEmpty {
            HStack(spacing: spacing) {
                ForEach(ids.prefix(shownLimit), id: \.self) { id in
                    entityIcon(
                        emoji: emoji,
                        id: id,
                        fontSize: fontSize,
                        onTapId: onTapId
                    )
                }

                if ids.count > shownLimit {
                    Text("+\(ids.count - shownLimit)")
                        .font(.caption2)
                        .onTapGesture {
                            if let first = ids.first {
                                onTapId?(first)
                            }
                        }
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    func entityIcon(
        emoji: String,
        id: String,
        fontSize: CGFloat,
        onTapId: ((String) -> Void)?
    ) -> some View {

        let isSelected = selectedEntityId == id

        Text(emoji)
            .font(.system(size: fontSize))
            .padding(2)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.yellow : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected && isHitAnimating ? 1.15 : 1.0)
            .onTapGesture { onTapId?(id) }
    }
}
