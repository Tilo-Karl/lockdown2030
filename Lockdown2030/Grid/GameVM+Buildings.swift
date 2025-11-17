//
//  GameVM+Buildings.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

import Foundation

extension GameVM {
    func buildingAt(x: Int, y: Int) -> Building? {
        buildings.first { $0.root.x == x && $0.root.y == y }
    }
}
