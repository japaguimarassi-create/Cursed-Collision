# Collision Battlestar V2 — Zero Runtime Rebuild

Date: 2026-10-08

## Objective

Replace the fragile runtime architecture with a small, explicit, server-authoritative runtime built around two cores:

1. Mechanics Heart: owns lifecycle, service registration, runtime state, watchdogs, snapshots, and coordinated recovery.
2. AI Heart: owns one bounded scheduler for up to 16 NPC agents; every NPC has independent memory and a wave-adaptive profile.

The old CollisionBattlestar tree is not reused by the V2 project mapping. V2 is a new runtime tree.

## Research decisions

- Use RunService only where frame-level work is actually necessary; periodic game logic is scheduled with task.* and bounded loops.
- Keep client input untrusted. Every state/progression/combat request is validated on the server.
- Use UpdateAsync for persistent player profile writes and session locking.
- Use OrderedDataStore + GetSortedAsync for persistent score ranking.
- Use WorldRoot collision groups instead of legacy PhysicsService APIs.
- Use lightweight ParticleEmitter bursts and short-lived parts for effects; keep particle counts deliberately small.
- Keep audio configurable. No unknown or invented audio asset IDs are hard-coded.
- Use one AI scheduler instead of one coroutine/loop per NPC.
- Keep V2 geometry procedural and small so low-end mobile devices do not inherit the previous runtime's duplicated content.

Primary references:
- https://create.roblox.com/docs/reference/engine/classes/RunService
- https://create.roblox.com/docs/performance-optimization/microprofiler/task-scheduler
- https://create.roblox.com/docs/performance-optimization/improve
- https://create.roblox.com/docs/scripting/security/client-server-boundary
- https://create.roblox.com/docs/reference/engine/classes/RemoteEvent
- https://create.roblox.com/docs/cloud-services/data-stores
- https://create.roblox.com/docs/reference/engine/classes/OrderedDataStore
- https://create.roblox.com/docs/reference/engine/classes/WorldRoot
- https://create.roblox.com/docs/reference/engine/classes/BasePart
- https://create.roblox.com/docs/pt-br/effects/particle-emitters
- https://create.roblox.com/docs/reference/engine/classes/SoundService

## Runtime shape

Server:
Main -> Mechanics Heart -> services
                         -> World
                         -> Persistence
                         -> Players
                         -> Score
                         -> Combat
                         -> Enemies -> AI Heart -> NPC Agents
                         -> Waves
                         -> Missions
                         -> Shop
                         -> Echo
                         -> PvP

Client:
Client -> HUD
       -> Input
       -> FX
       -> Audio

## Failure model

1. Bootstrap creates remotes before optional systems.
2. World has a procedural fallback.
3. Every core service Start/Stop/Reload is independently protected.
4. Mechanics Heart periodically checks world, waves, enemy count and player characters.
5. A runtime exception triggers one coordinated reload, guarded by a generation ID.
6. Reload clears stale NPCs, resets PvP/Echo runtime state, recreates the world, repairs characters, and resumes the current wave.
7. Repeated recovery failures stop automatic retries and expose a clear runtime error instead of leaving an invisible/broken state.

## Gameplay baseline

- PvE wave combat, 16 NPC cap.
- 3-hit M1 combo + dash.
- Elites and Boss waves.
- Adaptive NPC AI.
- Score -> Level progression.
- Credits + upgrade shop.
- Persistent missions.
- Friend Echo companion, one active per player.
- Explicit PvP arena.
- Global ranking with server fallback.
- Lightweight VFX.
- Configurable audio.

## Performance budget

- 16 active NPC maximum.
- One AI scheduler.
- Target cache refreshed periodically, not every NPC.
- World uses a small number of anchored parts.
- Decorative parts do not cast shadows.
- No per-frame UI polling.
- No workspace-wide GetDescendants scans inside combat/AI loops.
- Effects are short-lived and capped.
