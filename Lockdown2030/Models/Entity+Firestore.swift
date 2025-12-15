//
//  Entity+Firestore.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-15.
//

import Foundation
import FirebaseFirestore

extension Entity {
    init?(docId: String, data: [String: Any]) {
        guard
            let typeStr = data["type"] as? String,
            let type = EntityType(rawValue: typeStr),
            let kind = data["kind"] as? String
        else { return nil }

        self.id = docId
        self.type = type
        self.kind = kind

        if let posDict = data["pos"] as? [String: Any],
           let x = posDict["x"] as? Int,
           let y = posDict["y"] as? Int {
            self.pos = Pos(x: x, y: y)
        } else {
            self.pos = nil
        }

        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()

        self.alive = data["alive"] as? Bool
        self.downed = data["downed"] as? Bool
        self.despawnAt = (data["despawnAt"] as? NSNumber)?.int64Value

        // Actor component (humans + zombies)
        if type == .human || type == .zombie {
            let equipment: Equipment? = {
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
                        off: w["off"] as? String
                    )
                }

                return Equipment(body: body, weapon: weapon)
            }()

            self.actor = ActorComponent(
                isPlayer: (data["isPlayer"] as? Bool) ?? false,
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
                equipment: equipment,
                inventory: data["inventory"] as? [String]
            )
        } else {
            self.actor = nil
        }

        // Item component
        if type == .item {
            self.item = ItemComponent(
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
        } else {
            self.item = nil
        }
    }
}
