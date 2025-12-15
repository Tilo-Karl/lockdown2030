//  GameVM+Combat.swift
//  Lockdown2030
//
//  Attack selected entity using Entity + ActorComponent.isPlayer
//  (players + humans share EntityType.human, zombies are EntityType.zombie)

import Foundation

extension GameVM {

    func attackSelectedEntity() {
        guard let target = selectedEntity else {
            pushCombat(GameStrings.combatNoTargetSelected)
            return
        }

        // Must be on my tile (melee for now)
        guard let myPos = myPos,
              let targetPos = target.pos,
              myPos == targetPos else {
            pushCombat("Target is too far away.")
            return
        }

        // Drive hit animation when attacking any actor (human or zombie)
        if target.isActor {
            zombieHitTick &+= 1
        }

        // Backend targetType:
        // - zombie -> "zombie"
        // - human actors:
        //    - if isPlayer == true  -> "player"  (docs in players/)
        //    - else                 -> "human"   (docs in humans/)
        // - item -> "item"
        let targetType: String = {
            switch target.type {
            case .zombie:
                return "zombie"

            case .human:
                if target.actor?.isPlayer == true {
                    return "player"
                } else {
                    return "human"
                }

            case .item:
                return "item"
            }
        }()

        Task { await attackEntity(targetId: target.id, targetType: targetType) }
    }
}
