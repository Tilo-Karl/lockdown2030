//
//  GameStrings.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-08.
//

import Foundation

enum GameStrings {
    // MARK: - Combat messages
    
    /// "You hit the zombie for %d HP (now %d HP)."
    static let combatHitWithRemainingHp = "You hit the zombie for %d HP (now %d HP)."
    
    /// "You swing at the zombie."
    static let combatSwingAtZombie = "You swing at the zombie."
    
    /// "The zombie hits you back for %d HP (you now at %d HP)."
    static let combatZombieHitsYouWithRemainingHp = "The zombie hits you back for %d HP (you now at %d HP)."
    
    /// "The zombie hits you back for %d HP."
    static let combatZombieHitsYou = "The zombie hits you back for %d HP."
    
    /// "The zombie collapses and stops moving."
    static let combatZombieDies = "The zombie collapses and stops moving."
    
    /// "No target selected."
    static let combatNoTargetSelected = "No target selected."
    
    /// "You can't attack that."
    static let combatCantAttackThat = "You can't attack that."
    
    /// "Attack failed: network error"
    static let combatAttackFailedNetwork = "Attack failed: network error"
    
    /// "Attack failed: %@"
    static let combatAttackFailedReason = "Attack failed: %@"
    
    /// "The zombie is too far away to attack."
    static let combatZombieTooFar = "The zombie is too far away to attack."
    
    /// "There is no zombie here."
    static let combatNoZombieHere = "There is no zombie here."
    
    /// "You don't know where you are."
    static let combatDontKnowWhereYouAre = "You don't know where you are."
    
    // MARK: - System / join / move messages
    
    /// "Joined game at (%d, %d)."
    static let systemJoinSuccess = "Joined game at (%d, %d)."
    
    /// "Join failed: %@"
    static let systemJoinFailedReason = "Join failed: %@"
    
    /// "Join failed: network error"
    static let systemJoinFailedNetwork = "Join failed: network error"
    
    /// "Move ok to (%d, %d)."
    static let systemMoveOkTo = "Move ok to (%d, %d)."
    
    /// "Move failed: %@"
    static let systemMoveFailedReason = "Move failed: %@"
    
    // MARK: - Chat / UI placeholders
    
    /// "[System] Chat coming soon…"
    static let chatPlaceholder = "[System] Chat coming soon…"
}
