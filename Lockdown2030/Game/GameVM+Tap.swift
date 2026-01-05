//  GameVM+Tap.swift
//  Lockdown2030
//
//  Entity selection by id (NO “check zombies/players/npcs/items”).

@MainActor
extension GameVM {

    func handleTileTap(pos: Pos) {
        guard let current = myPos else { return }

        if pos == current {
            if isSameTile(interactionPos, pos), interactionKind == .tile {
                clearInteraction()
            } else {
                selectEntity(at: pos, kind: .tile, id: nil)
            }
            return
        }

        let targetCell = renderCellAt(x: pos.x, y: pos.y)
        let targetPos = Pos(
            x: pos.x,
            y: pos.y,
            z: targetCell?.z ?? current.z,
            layer: targetCell?.layer ?? current.layer
        )
        let dx = targetPos.x - current.x
        let dy = targetPos.y - current.y
        let step = max(abs(dx), abs(dy))
        guard step >= 1 else { return }

        let moveDx: Int
        let moveDy: Int

        if abs(dx) == 1 && abs(dy) == 1 {
            moveDx = dx
            moveDy = dy
        } else if abs(dx) > 1 || abs(dy) > 1 {
            if abs(dx) >= abs(dy) {
                moveDx = dx == 0 ? 0 : (dx > 0 ? 1 : -1)
                moveDy = 0
            } else {
                moveDx = 0
                moveDy = dy == 0 ? 0 : (dy > 0 ? 1 : -1)
            }
        } else {
            moveDx = dx
            moveDy = dy
        }

        clearInteraction()
        Task { await move(dx: moveDx, dy: moveDy) }
    }

    func handleEntityTap(entityId: String) {
        guard let e = entitiesById[entityId], let pos = e.pos else {
            clearInteraction()
            return
        }

        guard let distance = distanceFromMe(to: pos) else { return }

        let kind: InteractionKind = {
            switch e.type {
            case .zombie: return .zombie
            case .human:  return .human
            case .item:   return .item
            default:      return .tile
            }
        }()

        if distance == 0 {
            if interactionKind == kind,
               selectedEntityId == entityId,
               isSameTile(interactionPos, pos) {
                clearInteraction()
            } else {
                selectEntity(at: pos, kind: kind, id: entityId)
            }
        } else {
            clearInteraction()
        }
    }

    private func distanceFromMe(to pos: Pos) -> Int? {
        guard let current = myPos else { return nil }
        return abs(current.x - pos.x) + abs(current.y - pos.y)
    }

    private func isSameTile(_ lhs: Pos?, _ rhs: Pos) -> Bool {
        guard let l = lhs else { return false }
        return l.x == rhs.x && l.y == rhs.y
    }
}
