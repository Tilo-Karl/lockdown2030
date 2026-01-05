# Repo Map

## Folder Tree (Top 2–3 Levels)

```
.
├── Lockdown2030
│   ├── Assets.xcassets
│   ├── Constants
│   ├── Game
│   ├── Grid
│   ├── Models
│   ├── Networking
│   ├── ContentView.swift
│   └── Lockdown2030App.swift
├── Lockdown2030.xcodeproj
├── Lockdown2030Tests
└── Lockdown2030UITests
```

## Key Entry Points

- App bootstrap: `Lockdown2030/Lockdown2030App.swift`
- Root UI: `Lockdown2030/ContentView.swift`
- Game state + auth bootstrap: `Lockdown2030/Game/GameVM.swift`, `Lockdown2030/Game/GameVM+Sign.swift`
- Firestore listeners + decoding:
  - Game doc + collections: `Lockdown2030/Game/GameVM+Firestore.swift`
  - My player doc: `Lockdown2030/Game/GameVM+Player.swift`
- Grid rendering:
  - Viewport and layout: `Lockdown2030/Grid/GridView.swift`, `Lockdown2030/Grid/GridViewport.swift`
  - Cell rendering + input: `Lockdown2030/Grid/GridCellView.swift`, `Lockdown2030/Grid/GridCellView+EntityTap.swift`
  - Config: `Lockdown2030/Grid/GridConfig.swift`

## Data Flow (CloudAPI + Firestore)

### CloudAPI endpoints and usage

- `POST /join-game` via `CloudAPI.join` in `Lockdown2030/Game/GameVM+Engine.swift` (joinGame)
- `POST /move-player` via `CloudAPI.move` in `Lockdown2030/Game/GameVM+Engine.swift` (move)
- `POST /attack-entity` via `CloudAPI.attackEntity` in `Lockdown2030/Game/GameVM+Engine+Attack.swift` (attackEntity)
- `POST /tick-game` via `CloudAPI.tickGame` in `Lockdown2030/Game/GameVM+Tick.swift` (tickGame)
- `CloudAPI.equipItem` and `CloudAPI.unequipItem` are defined in `Lockdown2030/Networking/CloudAPI.swift` but not referenced elsewhere.

### Firestore collections watched and where

- Game doc: `games/{gameId}` watched in `Lockdown2030/Game/GameVM+Firestore.swift` (startGameDocListener)
  - map/meta fields: `gridsize`, `name`, `mapId`, `mapMeta`
- Players: `games/{gameId}/players` watched in `Lockdown2030/Game/GameVM+Firestore.swift` (startPlayersListener)
- Humans: `games/{gameId}/humans` watched in `Lockdown2030/Game/GameVM+Firestore.swift` (startHumansListener)
- Zombies: `games/{gameId}/zombies` watched in `Lockdown2030/Game/GameVM+Firestore.swift` (startZombiesListener)
- Items: `games/{gameId}/items` watched in `Lockdown2030/Game/GameVM+Firestore.swift` (startItemsListener)
- My player doc: `games/{gameId}/players/{uid}` watched in `Lockdown2030/Game/GameVM+Player.swift` (startMyPlayerListener)

Listeners are started after auth in `Lockdown2030/Game/GameVM+Sign.swift` (signInAndLoad) and the per-player listener is started on successful join in `Lockdown2030/Game/GameVM+Engine.swift` (joinGame).
