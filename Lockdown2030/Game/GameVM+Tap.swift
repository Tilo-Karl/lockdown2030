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
        guard dx != 0 || dy != 0 else { return }

        clearInteraction()
        Task { await move(dx: dx, dy: dy) }
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
        guard current.z == pos.z, current.layer == pos.layer else { return nil }
        return abs(current.x - pos.x) + abs(current.y - pos.y)
    }

    private func isSameTile(_ lhs: Pos?, _ rhs: Pos) -> Bool {
        guard let l = lhs else { return false }
        return l.x == rhs.x && l.y == rhs.y && l.z == rhs.z && l.layer == rhs.layer
    }
}
