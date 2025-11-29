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
    
  @Published var hp: Int = 100
  @Published var ap: Int = 3
    
  @Published var uid: String = ""
  @Published var gameName: String = ""
  @Published var gridW = 0
  @Published var gridH = 0
  @Published var status: String = ""
  @Published var myPos: Pos? = nil
  @Published var focusPos: Pos? = nil
  @Published var maxViewRadius: Int = 1   // 0 = only your tile, 1 = adjacent tiles, etc.

  @Published var buildings: [Building] = []
  @Published var isInsideBuilding: Bool = false
  @Published var activeBuildingId: String? = nil
  @Published var buildingColors: [String: String] = [:]
  @Published var terrain: [String] = []
  @Published var terrainColors: [String: String] = [:]
    
  @Published var zombies: [Zombie] = []
  @Published var lastEventMessage: String? = nil
  
  @Published var mapId: String = ""
    
  var myPlayerListener: ListenerRegistration?
    
    

  let db = Firestore.firestore()
  let gameId = "lockdown2030"
  var gameListener: ListenerRegistration?
  var zombieListener: ListenerRegistration?
  let log = Logger(subsystem: "Lockdown2030", category: "GameVM")

  init() {
    Task { await signInAndLoad() }
  }
  
  func terrainAt(_ x: Int, _ y: Int) -> String {
    guard y >= 0, y < terrain.count else { return "0" }
    let row = terrain[y]
    guard x >= 0, x < row.count else { return "0" }
    return String(row[row.index(row.startIndex, offsetBy: x)])
  }

  func setLastEventMessage(_ message: String) {
    DispatchQueue.main.async {
      self.lastEventMessage = message
      self.log.info("Event: \(message, privacy: .public)")
    }
  }
}
