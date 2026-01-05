import Foundation
import FirebaseFirestore

/*
Cell Field Usage Map (frontend, as of current code)

Top-level fields:
- x,y: read via Cell.pos2D in `Lockdown2030/Models/Cell.swift` and used as keys in `cellsOutsideByPos` and `cellsInsideByPos3D` plus Grid rendering coordinates in `Lockdown2030/Game/GameVM+Firestore.swift` (startCellsListener) and `Lockdown2030/Grid/GridView.swift` (cellView).
- z: read in `Lockdown2030/Game/GameVM+Firestore.swift` (startCellsListener) to split outside (z == 0) vs inside (all z) cells; used in inside map key.
- layer: read in `Lockdown2030/Game/GameVM+Firestore.swift` (startCellsListener) to split outside (layer == 0) vs inside (layer == 1); also used in `Lockdown2030/Models/Cell.swift` (isInside).
- terrain: read in `Lockdown2030/Game/GameVM.swift` (tileColorAt) for palette lookup; shown in the Tile Inspector (CV+InteractionSection).
- blocksMove: read in `Lockdown2030/Game/GameVM.swift` (tileColorAt) to set final opacity; shown in the Tile Inspector.
- moveCost: UNUSED in code logic; shown in the Tile Inspector.
- ruined: read in `Lockdown2030/Game/GameVM.swift` (tileColorAt) to raise opacity; shown in the Tile Inspector.
- hp: UNUSED in code logic; shown in the Tile Inspector.
- type: read in `Lockdown2030/Game/GameVM.swift` (tileLabelAt, tileColorAt) as fallback when no building type; shown in the Tile Inspector.
- districtId: UNUSED in code logic; shown in the Tile Inspector.
- building: read in `Lockdown2030/Game/GameVM.swift` (tileLabelAt, tileColorAt) and `Lockdown2030/Game/GameVM+Buildings.swift` (buildingAt/buildingHere/activeBuilding); shown in the Tile Inspector.
- fuse/water/generator/search: UNUSED in code logic; shown in the Tile Inspector.
- createdAt/updatedAt: UNUSED in code logic; shown in the Tile Inspector.

Nested fields:
- building.type: read in `Lockdown2030/Game/GameVM.swift` (tileLabelAt, tileColorAt) and `Lockdown2030/Game/GameVM+Buildings.swift` (buildingAt/buildingHere); shown in the Tile Inspector.
- building.name: read in `Lockdown2030/Game/GameVM.swift` (tileLabelAt); shown in the Tile Inspector.
- building.floors: UNUSED in code logic; shown in the Tile Inspector.
- building.districtId: UNUSED in code logic; shown in the Tile Inspector.
- building.root.x/y: UNUSED in code logic; shown in the Tile Inspector.
- fuse.hp, water.hp: UNUSED in code logic; shown in the Tile Inspector.
- generator.installed, generator.hp: UNUSED in code logic; shown in the Tile Inspector.
- search.remaining, search.searchedCount: UNUSED in code logic; shown in the Tile Inspector.
*/

struct Cell: Codable, Hashable, Identifiable {
    var id: String { cellId }
    let cellId: String

    let x: Int
    let y: Int
    let z: Int
    let layer: Int

    let terrain: String?
    let blocksMove: Bool
    let moveCost: Int
    let ruined: Bool
    let hp: Int

    // Inside-only
    let type: String?
    let districtId: Int?

    // Shared “stamp”
    let building: BuildingStamp?

    // Inside runtime subsystems (optional on outside)
    let fuse: Component?
    let water: Component?
    let generator: Generator?
    let search: Search?

    let createdAt: Date?
    let updatedAt: Date?

    struct BuildingStamp: Codable, Hashable {
        let type: String?
        let floors: Int?
        let districtId: Int?
        let name: String?
        let root: Root?
        struct Root: Codable, Hashable { let x: Int; let y: Int }
    }

    struct Component: Codable, Hashable { let hp: Int? }
    struct Generator: Codable, Hashable { let installed: Bool?; let hp: Int? }
    struct Search: Codable, Hashable { let remaining: Int?; let searchedCount: Int? }
}

extension Cell {
    var pos2D: Pos { Pos(x: x, y: y, z: 0, layer: 0) }
    var isInside: Bool { layer == 1 }
}
