//
//  GameVM+Firestore.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-19.
//

import Foundation
import FirebaseFirestore
import os.log

extension GameVM {

    // MARK: - Firestore helpers (centralized entry points)

    /// games/{gameId}
    var gameDocRef: DocumentReference? {
        guard !gameId.isEmpty else { return nil }
        return db.collection("games").document(gameId)
    }

    /// games/{gameId}/players
    var playersColRef: CollectionReference? {
        gameDocRef?.collection("players")
    }

    /// games/{gameId}/zombies
    var zombiesColRef: CollectionReference? {
        gameDocRef?.collection("zombies")
    }

    // MARK: - Game document listener (map + meta)

    /// Listen to games/{gameId} and fan out into grid, mapId, tileRows, tileMeta, buildings, palettes.
    @MainActor
    func startGameDocListener() {
        guard let ref = gameDocRef else { return }

        // Tear down any old listener
        gameListener?.remove()

        gameListener = ref.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }

            if let err = err {
                print("Game doc listener ERROR: \(err.localizedDescription)")
                return
            }

            guard let data = snap?.data() else {
                return
            }

            DispatchQueue.main.async {
                self.applyGameSnapshot(data)
            }
        }
    }

    @MainActor
    func stopGameDocListener() {
        gameListener?.remove()
        gameListener = nil
    }

    /// Apply one snapshot of games/{gameId} to the view model.
    private func applyGameSnapshot(_ data: [String: Any]) {
        // gridsize
        if let grid = data["gridsize"] as? [String: Any],
           let w = grid["w"] as? Int,
           let h = grid["h"] as? Int {
            gridW = w
            gridH = h
        }

        // mapId
        if let mid = data["mapId"] as? String {
            mapId = mid
        }

        // mapMeta (terrain codes, tileMeta, buildings, palettes…)
        if let mapMeta = data["mapMeta"] as? [String: Any] {
            applyMapMeta(mapMeta)
        }
    }

    /// Parse and apply the mapMeta section from the game document.
    private func applyMapMeta(_ mapMeta: [String: Any]) {
        // --- Tile rows (codes) ---
        if let terrainArr = mapMeta["terrain"] as? [String] {
            tileRows = terrainArr
        }

        // --- Tile meta (code → TileMeta) ---
        if let rawTileMeta = mapMeta["tileMeta"] as? [String: Any] {
            var dict: [String: TileMeta] = [:]

            for (code, value) in rawTileMeta {
                guard let metaDict = value as? [String: Any],
                      let label = metaDict["label"] as? String,
                      let colorHex = metaDict["colorHex"] as? String
                else { continue }

                let blocksMovement     = metaDict["blocksMovement"] as? Bool ?? false
                let blocksVision       = metaDict["blocksVision"] as? Bool ?? false
                let playerSpawnAllowed = metaDict["playerSpawnAllowed"] as? Bool ?? true
                let zombieSpawnAllowed = metaDict["zombieSpawnAllowed"] as? Bool ?? true
                let moveCost           = metaDict["moveCost"] as? Int ?? 1

                dict[code] = TileMeta(
                    label: label,
                    colorHex: colorHex,
                    blocksMovement: blocksMovement,
                    blocksVision: blocksVision,
                    playerSpawnAllowed: playerSpawnAllowed,
                    zombieSpawnAllowed: zombieSpawnAllowed,
                    moveCost: moveCost
                )
            }

            // Debug logging so we can see what came from Firestore
            if dict.isEmpty {
                log.info("tileMeta from mapMeta is EMPTY")
            } else {
                let codes = Array(dict.keys).sorted()
                log.info("tileMeta from mapMeta: \(dict.count, privacy: .public) entries, codes: \(codes, privacy: .public)")
            }

            if !dict.isEmpty {
                tileMeta = dict
            }
        }

        // --- Buildings array (same shape you already use in parseBuildingsArray) ---
        if let buildingsArr = mapMeta["buildings"] as? [[String: Any]] {
            buildings = parseBuildingsArray(buildingsArr)
        }

        // --- Building palette (type → hex) ---
        if let palette = mapMeta["buildingPalette"] as? [String: String] {
            buildingColors = palette
        } else if let anyPalette = mapMeta["buildingPalette"] as? [String: Any] {
            var normalized: [String: String] = [:]
            for (key, value) in anyPalette {
                if let s = value as? String {
                    normalized[key] = s
                }
            }
            buildingColors = normalized
        }
    }

    // MARK: - Zombies listener

    /// Listen to games/{gameId}/zombies and keep `zombies` in sync.
    @MainActor
    func startZombiesListener() {
        guard let zombiesColRef else { return }

        // Tear down any previous listener
        zombieListener?.remove()

        zombieListener = zombiesColRef.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }

            if let err = err {
                print("Zombie listener ERROR: \(err.localizedDescription)")
                return
            }

            let docs = snap?.documents ?? []
            
            let mapped: [Zombie] = docs.compactMap { doc in
                let data = doc.data()
                
                guard
                    let type = data["type"] as? String,
                    let kind = data["kind"] as? String,
                    let hp = data["hp"] as? Int,
                    let alive = data["alive"] as? Bool,
                    let pos = data["pos"] as? [String: Any],
                    let x = pos["x"] as? Int,
                    let y = pos["y"] as? Int
                else {
                    return nil
                }
                
                return Zombie(
                    id: doc.documentID,
                    type: type,
                    kind: kind,
                    hp: hp,
                    alive: alive,
                    pos: Pos(x: x, y: y)
                )
            }

            DispatchQueue.main.async {
                self.zombies = mapped
                // Keep the current interaction in sync with updated zombies (clear selection if it moved/died)
                self.refreshInteractionAfterZombiesUpdate()
            }
        }
    }

    @MainActor
    func stopZombiesListener() {
        zombieListener?.remove()
        zombieListener = nil
    }

    // MARK: - Players listener (all players in game)

    /// Listen to games/{gameId}/players and keep `players` in sync.
    @MainActor
    func startPlayersListener() {
        guard let playersColRef else { return }

        // Tear down any previous listener
        playersListener?.remove()

        playersListener = playersColRef.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }

            if let err = err {
                print("Players listener ERROR: \(err.localizedDescription)")
                return
            }

            let docs = snap?.documents ?? []

            let mapped: [PlayerDoc] = docs.compactMap { doc in
                let data = doc.data()

                let userId = (data["userId"] as? String) ?? doc.documentID
                let displayName = data["displayName"] as? String

                var pos: Pos? = nil
                if let posDict = data["pos"] as? [String: Any],
                   let x = posDict["x"] as? Int,
                   let y = posDict["y"] as? Int {
                    pos = Pos(x: x, y: y)
                }

                let hp = data["hp"] as? Int
                let ap = data["ap"] as? Int
                let alive = data["alive"] as? Bool

                return PlayerDoc(
                    userId: userId,
                    displayName: displayName,
                    pos: pos,
                    hp: hp,
                    ap: ap,
                    alive: alive
                )
            }

            DispatchQueue.main.async {
                self.players = mapped
            }
        }
    }

    @MainActor
    func stopPlayersListener() {
        playersListener?.remove()
        playersListener = nil
    }
}
