//
//  GridViewport.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

import SwiftUI
import CoreGraphics

struct GridViewport {
    let gridW: Int
    let gridH: Int
    let center: Pos
    let radius: Int

    var minX: Int { max(0, center.x - radius) }
    var maxX: Int { min(gridW - 1, center.x + radius) }
    var minY: Int { max(0, center.y - radius) }
    var maxY: Int { min(gridH - 1, center.y + radius) }

    var xRange: ClosedRange<Int> { minX...maxX }
    var yRange: ClosedRange<Int> { minY...maxY }

    func tileSize(
        in geo: GeometryProxy,
        baseCellSize: CGFloat
    ) -> CGFloat {
        let cols = maxX - minX + 1
        let availableWidth = geo.size.width - CGFloat(cols + 1) * 2
        let dynamicSize = availableWidth / CGFloat(cols)
        return max(baseCellSize, dynamicSize)
    }
    
}
