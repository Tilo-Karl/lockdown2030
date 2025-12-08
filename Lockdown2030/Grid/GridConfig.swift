//
//  GridConfig.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-06.
//
// NOT USING NOW. MAYBE FOR FUTURE IPAD.
//

import SwiftUI

/// Visual tuning for the grid and helpers to keep map sizing consistent.
///
/// **Intended usage pattern:**
/// - `GridConfig` defines the *rules* (min/max tile size, padding), not a fixed size.
/// - `ContentView` (or whatever owns layout) should:
///   - Read the available width/height via `GeometryReader`,
///   - Call `computeCellSize(availableWidth:availableHeight:columns:rows:config:)`,
///   - Optionally call `computeGridHeight(...)` if it wants to clamp the map’s height,
///   - Pass the resulting `cellSize` (and possibly gridHeight) down into `GridView`.
/// - `GridView` should accept `cellSize` as an input and render tiles at exactly that size,
///   without hard‑coding its own constants or doing its own device‑dependent scaling.
///
/// This keeps:
/// - Sizing decisions in one place (the parent layout),
/// - The map looking reasonable on both small phones and large iPads,
/// - The grid and any HUD / overlays aligned on the same notion of tile size.
struct GridConfig {
    /// Minimum tile size so things stay tappable.
    let minCellSize: CGFloat
    /// Maximum tile size so tiles don’t become ridiculous on huge screens.
    let maxCellSize: CGFloat
    /// Padding around the grid inside its container.
    let outerPadding: CGFloat

    /// Default config used in most places.
    static let `default` = GridConfig(
        minCellSize: 44,   // Apple “comfortable tap” minimum
        maxCellSize: 96,   // tweak later if you want bigger tiles on iPad
        outerPadding: 8
    )
}

/// Compute a cell size based on available space and grid dimensions.
/// - Parameters:
///   - availableWidth: space the map is allowed to use horizontally
///   - availableHeight: space the map is allowed to use vertically
///   - columns: number of columns in the grid (vm.gridW)
///   - rows: number of rows in the grid (vm.gridH)
///   - config: visual config (min/max size, padding)
/// - Returns: a concrete cell size in points
func computeCellSize(
    availableWidth: CGFloat,
    availableHeight: CGFloat,
    columns: Int,
    rows: Int,
    config: GridConfig = .default
) -> CGFloat {
    let cols = max(columns, 1)
    let rows = max(rows, 1)

    // Space left for actual tiles once we subtract outer padding
    let widthForCells  = max(availableWidth  - config.outerPadding * 2, 0)
    let heightForCells = max(availableHeight - config.outerPadding * 2, 0)

    // How big could a tile be in each direction
    let wPerCol = widthForCells  / CGFloat(cols)
    let hPerRow = heightForCells / CGFloat(rows)

    let raw = min(wPerCol, hPerRow)

    // Clamp to [minCellSize, maxCellSize]
    return max(config.minCellSize, min(raw, config.maxCellSize))
}

/// Helper to compute the total grid height from a cell size + row count.
/// This is handy if ContentView wants to clamp GridView’s height.
func computeGridHeight(
    cellSize: CGFloat,
    rows: Int,
    rowSpacing: CGFloat = 2,
    verticalPadding: CGFloat = 0
) -> CGFloat {
    let r = max(rows, 0)
    guard r > 0 else { return 0 }

    let cellsHeight = CGFloat(r) * cellSize
    let spacingHeight = CGFloat(max(r - 1, 0)) * rowSpacing
    return cellsHeight + spacingHeight + verticalPadding
}
