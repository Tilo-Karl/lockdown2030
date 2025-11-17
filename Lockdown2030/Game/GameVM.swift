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
  @Published var uid: String = ""
  @Published var gameName: String = ""
  @Published var gridW = 0
  @Published var gridH = 0
  @Published var status: String = ""
  @Published var myPos: Pos? = nil
  @Published var focusPos: Pos? = nil
  @Published var maxViewRadius: Int = 1   // 0 = only your tile, 1 = adjacent tiles, etc.

  @Published var buildings: [Building] = []
  @Published var mapId: String = ""
    
  var myPlayerListener: ListenerRegistration?

  let db = Firestore.firestore()
  let gameId = "lockdown2030"
  var gameListener: ListenerRegistration?
  let log = Logger(subsystem: "Lockdown2030", category: "GameVM")

  init() {
    Task { await signInAndLoad() }
  }
}
 
