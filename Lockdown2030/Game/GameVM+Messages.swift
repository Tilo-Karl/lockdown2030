import Foundation

extension GameVM {

    func pushMessage(_ text: String, kind: GameMessage.Kind) {
        DispatchQueue.main.async {
            let msg = GameMessage(kind: kind, text: text)
            self.messageLog.append(msg)
        }
    }

    func pushSystem(_ text: String) {
        pushMessage(text, kind: .system)
    }

    func pushCombat(_ text: String) {
        pushMessage(text, kind: .combat)
    }

    func pushRadio(_ text: String) {
        pushMessage(text, kind: .radio)
    }

    func showJoinSuccess(x: Int, y: Int) {
        pushSystem("Joined game at (\(x), \(y)).")
    }

    func showJoinFailed(reason: String) {
        pushSystem("Join failed: \(reason)")
    }

    func showMoveBlocked(reason: String) {
        pushSystem("You can't move there: \(reason)")
    }
}
