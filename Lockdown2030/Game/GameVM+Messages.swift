//
//  GameVM+Messages.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-08.
//

import Foundation

extension GameVM {
    /// Lightweight message type for the unified log (system, combat, radio, etc.).
    struct GameMessage: Identifiable {
        enum Kind {
            case system   // generic system/info
            case combat   // attacks, damage, etc.
            case radio    // player / NPC speech
        }

        let id = UUID()
        let kind: Kind
        let text: String
    }

    /// Core entry point for adding a message to the unified log.
    /// Appends into `messageLog` and keeps `lastEventMessage` in sync
    /// for any legacy UI that still reads it.
    func pushMessage(_ text: String, kind: GameMessage.Kind) {
        DispatchQueue.main.async {
            let msg = GameMessage(kind: kind, text: text)
            self.messageLog.append(msg)
            self.lastEventMessage = text
            self.log.info("Message[\(String(describing: kind))]: \(text, privacy: .public)")
        }
    }

    /// Convenience wrappers for different kinds of messages.
    func pushSystem(_ text: String) {
        pushMessage(text, kind: .system)
    }

    func pushCombat(_ text: String) {
        pushMessage(text, kind: .combat)
    }

    func pushRadio(_ text: String) {
        pushMessage(text, kind: .radio)
    }

    // MARK: - High-level message helpers

    /// Called when the player successfully joins a game.
    func showJoinSuccess(x: Int, y: Int) {
        pushSystem("Joined game at (\(x), \(y)).")
    }

    /// Called when joining a game fails for some reason.
    func showJoinFailed(reason: String) {
        pushSystem("Join failed: \(reason)")
    }

    /// Called when a move attempt is rejected or blocked.
    func showMoveBlocked(reason: String) {
        pushSystem("You can't move there: \(reason)")
    }

    /// Called when sign-in / auth succeeds and we know the UID.
    func showSignedIn(uid: String) {
        pushSystem("Signed in as \(uid).")
    }
}
