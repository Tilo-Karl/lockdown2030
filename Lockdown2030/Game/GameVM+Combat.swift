//
//  GameVM+Combat.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-08.
//

import Foundation

extension GameVM {

  /// High-level combat entry point used by the UI.
  /// Uses the current interactionKind / interactionPos to decide what to attack.
  @MainActor
  func attackSelected() {
    guard let kind = interactionKind, let pos = interactionPos else {
      pushCombat(GameStrings.combatNoTargetSelected)
      return
    }

    switch kind {
    case .zombie:
      // Bump the hit tick so the selected zombie tile can animate (shake) in the UI.
      zombieHitTick &+= 1
      attackZombieOnTile(pos: pos)
    case .tile, .human, .item:
      pushCombat(GameStrings.combatCantAttackThat)
    }
  }

  /// Find a zombie on the given tile and send an attack to the engine.
  @MainActor
  private func attackZombieOnTile(pos: Pos) {
    // Must know where we are.
    guard let myPos = myPos else {
      pushCombat(GameStrings.combatDontKnowWhereYouAre)
      return
    }

    // For now, only allow attacks on your own tile.
    guard myPos.x == pos.x && myPos.y == pos.y else {
      pushCombat(GameStrings.combatZombieTooFar)
      return
    }

    // Try to use a specifically selected zombie first, if we have one.
    let target: Zombie?
    if let selectedId = selectedZombieId {
        if let z = zombies.first(where: { $0.id == selectedId && $0.alive }) {
            // Ensure it is still on this tile.
            if z.pos.x == pos.x && z.pos.y == pos.y {
                target = z
            } else {
                target = nil
            }
        } else {
            target = nil
        }
    } else {
        target = nil
    }

    // If no specific zombie is selected or it is no longer valid, fall back to first alive on this tile.
    let finalTarget: Zombie?
    if let t = target {
        finalTarget = t
    } else {
        let zombiesHere = zombies.filter { z in
            z.alive && z.pos.x == pos.x && z.pos.y == pos.y
        }
        finalTarget = zombiesHere.first
    }

    guard let target = finalTarget else {
      pushCombat(GameStrings.combatNoZombieHere)
      return
    }

    // Fire off the engine attack.
    Task {
      await self.attackZombie(zombieId: target.id)
    }
  }
}
