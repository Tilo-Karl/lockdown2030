//
//  GameVM+Buildings.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

extension GameVM {

    typealias Building = Cell.BuildingStamp

    func buildingAt(x: Int, y: Int) -> Building? {
        outsideCellAt(x: x, y: y)?.building
    }
    
    /// The building (if any) at the player’s current position.
    var buildingHere: Building? {
        guard let pos = myPos else { return nil }
        return buildingAt(x: pos.x, y: pos.y)
    }

    /// The building the player is currently inside, if any.
    var activeBuilding: Building? {
        buildingHere
    }

    /// Enter the building on the player’s current tile, if there is one.
    func enterBuildingHere() {
        guard buildingHere != nil else { return }
        isInsideBuilding = true
    }

    /// Leave whatever building the player is currently inside, if any.
    func leaveBuilding() {
        isInsideBuilding = false
    }
}
