//
//  GameVM.swift
//  Lockdown2030
//
//  Fresh canonical state for Entities-based world (players + humans + zombies + items).
//

import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import os.log

@MainActor
final class GameVM: ObservableObject {

    // MARK: - Game state

    @Published var uid: String = ""
    @Published var gameName: String = ""
    @Published var gridW: Int = 0
    @Published var gridH: Int = 0
    @Published var status: String = ""
    @Published var myPos: Pos? = nil
    @Published var focusPos: Pos? = nil
    /// 0 = only your tile, 1 = adjacent tiles, etc.
    @Published var maxViewRadius: Int = 1
    @Published var mapId: String = ""

    // MARK: - Map/meta

    @Published var isInsideBuilding: Bool = false
    @Published var cellPalette: CellPalette? = nil
    @Published var cellsOutsideByPos: [Pos: Cell] = [:]
    @Published var cellsInsideByPos3D: [String: Cell] = [:]

    // MARK: - World entities (canonical)

    /// players = actor docs controlled by users (collection: games/{gameId}/players)
    @Published var players: [Entity] = []

    /// humans = non-player humans (collection: games/{gameId}/humans)
    @Published var humans: [Entity] = []

    /// zombies = zombies (collection: games/{gameId}/zombies)
    @Published var zombies: [Entity] = []

    /// items = world items (collection: games/{gameId}/items)
    @Published var items: [Entity] = []

    /// My own actor doc from `players/{uid}`.
    @Published var myActor: Entity? = nil

    // MARK: - Interaction / selection

    enum InteractionKind {
        case tile
        case zombie
        case human
        case item
    }

    @Published var interactionPos: Pos? = nil
    @Published var interactionKind: InteractionKind? = nil
    @Published var selectedEntityId: String? = nil

    // MARK: - UI messages

    struct GameMessage: Identifiable, Equatable {
        enum Kind { case system, combat, radio }
        let id = UUID().uuidString
        let kind: Kind
        let text: String
        let at: Date = Date()
    }

    @Published var messageLog: [GameMessage] = []
    @Published var zombieHitTick: Int = 0

    // MARK: - Firestore

    let db = Firestore.firestore()
    let gameId = "lockdown2030"
    let log = Logger(subsystem: "Lockdown2030", category: "GameVM")

    var myPlayerListener: ListenerRegistration?
    var gameListener: ListenerRegistration?
    var playersListener: ListenerRegistration?
    var humansListener: ListenerRegistration?
    var zombiesListener: ListenerRegistration?
    var itemsListener: ListenerRegistration?
    var cellsListener: ListenerRegistration?

    init() {
        Task { await signInAndLoad() }
    }

    // MARK: - Convenience lookups

    var allEntities: [Entity] { players + humans + zombies + items }

    var entitiesById: [String: Entity] {
        var dict: [String: Entity] = [:]
        for e in allEntities { dict[e.id] = e }
        return dict
    }

    var selectedEntity: Entity? {
        guard let id = selectedEntityId else { return nil }
        return entitiesById[id]
    }

    // MARK: - Cells (outside only)

    func outsideCellAt(x: Int, y: Int) -> Cell? {
        cellsOutsideByPos[Pos(x: x, y: y, z: 0, layer: 0)]
    }

    private func insideCellAt(x: Int, y: Int, z: Int) -> Cell? {
        cellsInsideByPos3D["\(x),\(y),\(z)"]
    }

    func renderCellAt(x: Int, y: Int) -> Cell? {
        if let pos = myPos, pos.layer == 1 {
            return insideCellAt(x: x, y: y, z: pos.z)
        }
        if isInsideBuilding {
            return insideCellAt(x: x, y: y, z: 0)
        }
        return outsideCellAt(x: x, y: y)
    }

    func tileLabelAt(x: Int, y: Int) -> String {
        guard let cell = renderCellAt(x: x, y: y) else { return "" }
        if let name = cell.building?.name, !name.isEmpty { return name }
        if let type = cell.building?.type, !type.isEmpty { return type }
        if let terrain = cell.terrain, !terrain.isEmpty { return terrain }
        return ""
    }

    func tileColorAt(x: Int, y: Int) -> Color? {
        guard let cell = renderCellAt(x: x, y: y) else {
            return Color.gray.opacity(0.2)
        }

        let terrainCode = cell.terrain ?? ""
        var baseColor: Color = {
            if let hex = cellPalette?.terrainColors[terrainCode] {
                return CellPalette.colorFromHex(hex)
            }
            return Color.gray
        }()

        let buildingType = cell.building?.type ?? cell.type
        if let bType = buildingType,
           let bHex = cellPalette?.buildingColors[bType] {
            baseColor = CellPalette.colorFromHex(bHex)
        }

        var opacity: Double = cell.blocksMove ? 0.55 : 0.25
        if cell.ruined {
            opacity = max(opacity, 0.7)
        }

        return baseColor.opacity(opacity)
    }

    // MARK: - Header stats (no legacy hp/ap)

    var myHpText: String {
        guard let a = myActor?.actor, let hp = a.currentHp else { return "—" }
        return "\(hp)"
    }

    var myApText: String {
        guard let a = myActor?.actor, let ap = a.currentAp else { return "—" }
        return "\(ap)"
    }
}
