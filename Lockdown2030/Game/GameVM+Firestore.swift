//
//  GameVM+Firestore.swift
//  Lockdown2030
//
//  Firestore listeners + decoding for Entity/ActorComponent/ItemComponent.
//  Canonical collections: players, humans, zombies, items.
//

import Foundation
import FirebaseFirestore

extension GameVM {

    // MARK: - Collection refs

    var gameDocRef: DocumentReference? {
        guard !gameId.isEmpty else { return nil }
        return db.collection("games").document(gameId)
    }

    var playersColRef: CollectionReference? { gameDocRef?.collection("players") }
    var humansColRef: CollectionReference?  { gameDocRef?.collection("humans") }
    var zombiesColRef: CollectionReference? { gameDocRef?.collection("zombies") }
    var itemsColRef: CollectionReference?   { gameDocRef?.collection("items") }

    // MARK: - Game doc listener (map/meta)

    func startGameDocListener() {
        guard let ref = gameDocRef else { return }
        gameListener?.remove()

        gameListener = ref.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            if let err = err {
                print("Game doc listener ERROR:", err.localizedDescription)
                return
            }
            guard let data = snap?.data() else { return }
            Task { @MainActor in self.applyGameSnapshot(data) }
        }
    }

    func stopGameDocListener() {
        gameListener?.remove()
        gameListener = nil
    }

    private func applyGameSnapshot(_ data: [String: Any]) {
        if let grid = data["gridsize"] as? [String: Any],
           let w = grid["w"] as? Int,
           let h = grid["h"] as? Int {
            gridW = w
            gridH = h
        }

        if let name = data["name"] as? String {
            gameName = name
        }

        if let mid = data["mapId"] as? String {
            mapId = mid
        }

        if let mapMeta = data["mapMeta"] as? [String: Any] {
            applyMapMeta(mapMeta)
        }
    }

    private func applyMapMeta(_ mapMeta: [String: Any]) {
        if let terrainArr = mapMeta["terrain"] as? [String] {
            tileRows = terrainArr
        }

        if let rawTileMeta = mapMeta["tileMeta"] as? [String: Any] {
            var dict: [String: TileMeta] = [:]

            for (code, value) in rawTileMeta {
                guard let metaDict = value as? [String: Any],
                      let label = metaDict["label"] as? String,
                      let colorHex = metaDict["colorHex"] as? String
                else { continue }

                dict[code] = TileMeta(
                    label: label,
                    colorHex: colorHex,
                    blocksMovement: metaDict["blocksMovement"] as? Bool ?? false,
                    blocksVision: metaDict["blocksVision"] as? Bool ?? false,
                    playerSpawnAllowed: metaDict["playerSpawnAllowed"] as? Bool ?? true,
                    zombieSpawnAllowed: metaDict["zombieSpawnAllowed"] as? Bool ?? true,
                    moveCost: metaDict["moveCost"] as? Int
                )
            }

            if !dict.isEmpty { tileMeta = dict }
        }

        if let buildingsArr = mapMeta["buildings"] as? [[String: Any]] {
            buildings = parseBuildingsArray(buildingsArr)
        }

        if let palette = mapMeta["buildingPalette"] as? [String: String] {
            buildingColors = palette
        } else if let anyPalette = mapMeta["buildingPalette"] as? [String: Any] {
            var normalized: [String: String] = [:]
            for (k, v) in anyPalette {
                if let s = v as? String { normalized[k] = s }
            }
            buildingColors = normalized
        }
    }

    // MARK: - Decode helpers

    private func decodePos(_ data: [String: Any]) -> Pos? {
        guard let p = data["pos"] as? [String: Any],
              let x = p["x"] as? Int,
              let y = p["y"] as? Int else { return nil }
        return Pos(x: x, y: y)
    }

    private func decodeDate(_ v: Any?) -> Date? {
        (v as? Timestamp)?.dateValue()
    }

    private func decodeInt64(_ v: Any?) -> Int64? {
        if let n = v as? Int64 { return n }
        if let n = v as? Int { return Int64(n) }
        if let n = v as? Double { return Int64(n) }
        return nil
    }

    private func decodeEquipment(_ data: [String: Any]) -> Equipment? {
        guard let eq = data["equipment"] as? [String: Any] else { return nil }

        var body: Equipment.Body? = nil
        if let b = eq["body"] as? [String: Any] {
            body = Equipment.Body(
                under: b["under"] as? String,
                outer: b["outer"] as? String
            )
        }

        var weapon: Equipment.Weapon? = nil
        if let w = eq["weapon"] as? [String: Any] {
            weapon = Equipment.Weapon(
                main: w["main"] as? String,
                off:  w["off"] as? String
            )
        }

        if body == nil && weapon == nil { return nil }
        return Equipment(body: body, weapon: weapon)
    }

    private func decodeActorComponent(_ data: [String: Any]) -> ActorComponent? {
        // Actor component exists for HUMAN/ZOMBIE docs. All fields optional except isPlayer.
        // If there are zero actor-ish fields AND isPlayer is missing, treat as not an actor.
        let hasAnyActorField =
            data["currentHp"] != nil || data["maxHp"] != nil ||
            data["currentAp"] != nil || data["maxAp"] != nil ||
            data["attackDamage"] != nil || data["hitChance"] != nil ||
            data["moveApCost"] != nil || data["attackApCost"] != nil ||
            data["faction"] != nil || data["hostileTo"] != nil ||
            data["equipment"] != nil || data["inventory"] != nil ||
            data["isPlayer"] != nil

        guard hasAnyActorField else { return nil }

        return ActorComponent(
            isPlayer: data["isPlayer"] as? Bool ?? false,

            currentHp: data["currentHp"] as? Int,
            maxHp: data["maxHp"] as? Int,
            currentAp: data["currentAp"] as? Int,
            maxAp: data["maxAp"] as? Int,

            armor: data["armor"] as? Int,
            defense: data["defense"] as? Int,
            attackDamage: data["attackDamage"] as? Int,
            hitChance: data["hitChance"] as? Double,
            moveApCost: data["moveApCost"] as? Int,
            attackApCost: data["attackApCost"] as? Int,

            faction: data["faction"] as? String,
            hostileTo: data["hostileTo"] as? [String],

            equipment: decodeEquipment(data),
            inventory: data["inventory"] as? [String]
        )
    }

    private func decodeItemComponent(_ data: [String: Any]) -> ItemComponent? {
        // Item component exists for ITEM docs; fields are optional.
        // If there's literally nothing item-ish, return nil.
        let hasAnyItemField =
            data["durabilityMax"] != nil || data["currentDurability"] != nil ||
            data["broken"] != nil || data["destructible"] != nil ||
            data["slot"] != nil || data["layer"] != nil ||
            data["weight"] != nil || data["value"] != nil ||
            data["armor"] != nil || data["damage"] != nil || data["range"] != nil

        guard hasAnyItemField else { return nil }

        return ItemComponent(
            durabilityMax: data["durabilityMax"] as? Int,
            currentDurability: data["currentDurability"] as? Int,
            broken: data["broken"] as? Bool,
            destructible: data["destructible"] as? Bool,

            slot: data["slot"] as? String,
            layer: data["layer"] as? String,

            weight: data["weight"] as? Int,
            value: data["value"] as? Int,
            armor: data["armor"] as? Int,
            damage: data["damage"] as? Int,
            range: data["range"] as? Int
        )
    }

    private func decodeEntity(doc: QueryDocumentSnapshot, forcedType: EntityType) -> Entity? {
        // Skip internal marker docs like "_logs"
        if doc.documentID.hasPrefix("_") { return nil }

        let data = doc.data()

        let kind = (data["kind"] as? String) ?? "DEFAULT"
        let pos = decodePos(data)

        let actor = decodeActorComponent(data)
        let item  = decodeItemComponent(data)

        return Entity(
            id: doc.documentID,
            type: forcedType,
            kind: kind,
            pos: pos,
            createdAt: decodeDate(data["createdAt"]),
            updatedAt: decodeDate(data["updatedAt"]),
            alive: data["alive"] as? Bool,
            downed: data["downed"] as? Bool,
            despawnAt: decodeInt64(data["despawnAt"]),
            actor: actor,
            item: item
        )
    }

    // MARK: - Listeners

    func startPlayersListener() {
        guard let col = playersColRef else { return }
        playersListener?.remove()

        playersListener = col.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            if let err = err {
                print("Players listener ERROR:", err.localizedDescription)
                return
            }
            let docs = snap?.documents ?? []
            let mapped = docs.compactMap { self.decodeEntity(doc: $0, forcedType: .human) }
            Task { @MainActor in self.players = mapped }
        }
    }

    func stopPlayersListener() { playersListener?.remove(); playersListener = nil }

    func startHumansListener() {
        guard let col = humansColRef else { return }
        humansListener?.remove()

        humansListener = col.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            if let err = err {
                print("Humans listener ERROR:", err.localizedDescription)
                return
            }
            let docs = snap?.documents ?? []
            let mapped = docs.compactMap { self.decodeEntity(doc: $0, forcedType: .human) }
            Task { @MainActor in self.humans = mapped }
        }
    }

    func stopHumansListener() { humansListener?.remove(); humansListener = nil }

    func startZombiesListener() {
        guard let col = zombiesColRef else { return }
        zombiesListener?.remove()

        zombiesListener = col.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            if let err = err {
                print("Zombies listener ERROR:", err.localizedDescription)
                return
            }
            let docs = snap?.documents ?? []
            let mapped = docs.compactMap { self.decodeEntity(doc: $0, forcedType: .zombie) }
            Task { @MainActor in self.zombies = mapped }
        }
    }

    func stopZombiesListener() { zombiesListener?.remove(); zombiesListener = nil }

    func startItemsListener() {
        guard let col = itemsColRef else { return }
        itemsListener?.remove()

        itemsListener = col.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            if let err = err {
                print("Items listener ERROR:", err.localizedDescription)
                return
            }
            let docs = snap?.documents ?? []
            let mapped = docs.compactMap { self.decodeEntity(doc: $0, forcedType: .item) }
            Task { @MainActor in self.items = mapped }
        }
    }

    func stopItemsListener() { itemsListener?.remove(); itemsListener = nil }
}
