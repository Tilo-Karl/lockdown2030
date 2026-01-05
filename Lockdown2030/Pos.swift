//
//  Pos.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import Foundation

struct Pos: Codable, Hashable {
    var x: Int
    var y: Int
    var z: Int
    var layer: Int

    init(x: Int, y: Int, z: Int = 0, layer: Int = 0) {
        self.x = x
        self.y = y
        self.z = z
        self.layer = layer
    }
}
