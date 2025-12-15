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

    // MARK: - Tile meta

    struct TileMeta {
        let label: String
        let colorHex: String
        let blocksMovement: Bool
        let blocksVision: Bool
        let playerSpawnAllowed: Bool
        let zombieSpawnAllowed: Bool
        let moveCost: Int?
    }

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

    @Published var buildings: [Building] = []
    @Published var isInsideBuilding: Bool = false
    @Published var activeBuildingId: String? = nil
    @Published var buildingColors: [String: String] = [:]
    @Published var tileRows: [String] = []
    @Published var tileMeta: [String: TileMeta] = [:]

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
