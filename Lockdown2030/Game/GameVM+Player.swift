//
//  GameVM+Player.swift
//  Lockdown2030
//
//  Listen to my actor doc at players/{uid} (Entity + ActorComponent).
//  equipment/inventory are itemId refs; actual item docs live in /items.
//

import Foundation
import FirebaseFirestore

extension GameVM {

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

    func startMyPlayerListener() {
        myPlayerListener?.remove()
        myPlayerListener = nil

        guard !uid.isEmpty, let playersColRef else {
            myPos = nil
            focusPos = nil
            myActor = nil
            return
        }

        let ref = playersColRef.document(uid)

        myPlayerListener = ref.addSnapshotListener { [weak self] snap, _ in
            guard let self else { return }

            guard let data = snap?.data() else {
                DispatchQueue.main.async {
                    self.myPos = nil
                    self.focusPos = nil
                    self.myActor = nil
                }
                return
            }

            let pos: Pos? = {
                guard let p = data["pos"] as? [String: Any],
                      let x = p["x"] as? Int,
                      let y = p["y"] as? Int else { return nil }
                return Pos(x: x, y: y)
            }()

            let actor = ActorComponent(
                isPlayer: data["isPlayer"] as? Bool ?? true,

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

                equipment: self.decodeEquipment(data),
                inventory: data["inventory"] as? [String]
            )

            let kind = (data["kind"] as? String) ?? "PLAYER"

            let entity = Entity(
                id: self.uid,
                type: .human,
                kind: kind,
                pos: pos,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue(),
                alive: data["alive"] as? Bool,
                downed: data["downed"] as? Bool,
                despawnAt: (data["despawnAt"] as? Int64) ?? (data["despawnAt"] as? Int).map(Int64.init),
                actor: actor,
                item: nil
            )

            DispatchQueue.main.async {
                self.myActor = entity

                if let pos {
                    if self.myPos != pos {
                        self.myPos = pos
                        self.focusPos = pos
                    }
                } else {
                    self.myPos = nil
                    self.focusPos = nil
                }
            }
        }
    }

    func upsertMyPlayer() {
        guard !uid.isEmpty, let playersColRef else { return }
        let ref = playersColRef.document(uid)

        ref.setData([
            "userId": uid,
            "displayName": "Tester",
            "pos": ["x": 0, "y": 0],

            "type": "HUMAN",
            "kind": "PLAYER",
            "isPlayer": true,
            "alive": true,

            "maxHp": 100,
            "maxAp": 3,
            "currentHp": 100,
            "currentAp": 3,

            "equipment": [
                "body": ["under": NSNull(), "outer": NSNull()],
                "weapon": ["main": NSNull(), "off": NSNull()]
            ],
            "inventory": [],

            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
}
