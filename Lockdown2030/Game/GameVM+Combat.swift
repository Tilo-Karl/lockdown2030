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

    // Pick the first alive zombie on this tile.
    let zombiesHere = zombies.filter { z in
      z.alive && z.pos.x == pos.x && z.pos.y == pos.y
    }

    guard let target = zombiesHere.first else {
      pushCombat(GameStrings.combatNoZombieHere)
      return
    }

    // Fire off the engine attack.
    Task {
      await self.attackZombie(zombieId: target.id)
    }
  }
}
