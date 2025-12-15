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

        let dx = pos.x - current.x
        let dy = pos.y - current.y
        let step = max(abs(dx), abs(dy))
        guard step == 1 else { return }

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
        return abs(current.x - pos.x) + abs(current.y - pos.y)
    }

    private func isSameTile(_ lhs: Pos?, _ rhs: Pos) -> Bool {
        guard let l = lhs else { return false }
        return l.x == rhs.x && l.y == rhs.y
    }
}
