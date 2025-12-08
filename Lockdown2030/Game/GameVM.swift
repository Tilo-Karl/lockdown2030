//
//  GameVM.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import os.log

final class GameVM: ObservableObject {

  // MARK: - Tile meta (from Firestore map meta)

  struct TileMeta {
    let label: String
    let colorHex: String
    let blocksMovement: Bool
    let blocksVision: Bool
    let playerSpawnAllowed: Bool
    let zombieSpawnAllowed: Bool
    let moveCost: Int?
  }

  // MARK: - Player state (mirrored from Firestore player doc)
  @Published var myPlayer: PlayerDoc? = nil
  /// All players in the current game (including me, if subscribed).
  @Published var players: [PlayerDoc] = []

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

  // MARK: - Interaction state (what the player has selected)

  enum InteractionKind {
    case tile
    case zombie
    case human
    case item
  }

  /// Position the user is currently interacting with (tap target).
  @Published var interactionPos: Pos? = nil

  /// What kind of thing is selected at `interactionPos`.
  @Published var interactionKind: InteractionKind? = nil

  @Published var buildings: [Building] = []
  @Published var isInsideBuilding: Bool = false
  @Published var activeBuildingId: String? = nil
  @Published var buildingColors: [String: String] = [:]

  /// Canonical tile rows from mapMeta.terrain (array of strings).
  @Published var tileRows: [String] = []

  /// Per-tile metadata (labels, colors, movement rules, etc.) keyed by tile code.
  @Published var tileMeta: [String: TileMeta] = [:]

  @Published var zombies: [Zombie] = []
  @Published var lastEventMessage: String? = nil

  /// Unified message log for system/combat/radio messages shown in the Radio / Chat UI.
  @Published var messageLog: [GameMessage] = []

  /// Bumps whenever an attack successfully hits a zombie; used as a simple animation trigger.
  @Published var zombieHitTick: Int = 0

  @Published var mapId: String = ""

  // MARK: - Listeners / Firestore

  var myPlayerListener: ListenerRegistration?
  var gameListener: ListenerRegistration?
  var zombieListener: ListenerRegistration?
  var playersListener: ListenerRegistration?

  let db = Firestore.firestore()
  let gameId = "lockdown2030"
  let log = Logger(subsystem: "Lockdown2030", category: "GameVM")

  init() {
    Task { await signInAndLoad() }
  }

  func setLastEventMessage(_ message: String) {
    // Legacy helper: update the simple string + log.
    // New code should call pushSystem / pushCombat / pushRadio instead.
    DispatchQueue.main.async {
      self.lastEventMessage = message
      self.log.info("Event: \(message, privacy: .public)")
    }
  }

  // MARK: - Tile snapshot helpers

  /// Lightweight snapshot of everything interesting on a single tile.
  struct TileSnapshot {
    let pos: Pos
    /// Raw tile code (e.g. "0" = ROAD, "5" = WATER).
    let tileCode: String
    let building: Building?
    let zombies: [Zombie]
  }

  /// Current tile the player is standing on, if we know their position.
  var tileHere: TileSnapshot? {
    guard let pos = myPos else { return nil }
    return tileSnapshot(at: pos)
  }

  /// Build a unified view of a tile at a given position.
  func tileSnapshot(at pos: Pos) -> TileSnapshot {
    let tileCode = tileCodeAt(x: pos.x, y: pos.y) ?? "0"
    let b = buildingAt(x: pos.x, y: pos.y)
    let zs = zombies.filter { z in
      z.pos.x == pos.x && z.pos.y == pos.y
    }
    return TileSnapshot(pos: pos, tileCode: tileCode, building: b, zombies: zs)
  }

  /// Convenience: meta for the tile at a given position, if available.
  func tileMeta(at pos: Pos) -> TileMeta? {
    guard let code = tileCodeAt(x: pos.x, y: pos.y) else { return nil }
    return tileMeta[code]
  }
}
