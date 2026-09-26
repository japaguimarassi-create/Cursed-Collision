# Collision Battlestar — Complete Production Build Plan (No AI)

Checkpoint: 2026-09-26

## 1. Source of truth

Use Rojo as the only source of Roblox runtime code. Keep one server runtime and one client runtime. Build the place from `default.project.json` and validate before publication.

The project must be treated as a continuous urban battleground, not as queued duel rooms.

## 2. Build order

### Stage 01 — Foundation
1. Keep the Rojo manifest stable.
2. Keep the continuous five-district Battle Line.
3. Create all remotes on the server at boot.
4. Load player data before allowing combat.
5. Spawn only after data and world readiness.
6. Keep gameplay independent from external asset availability.
7. Run static validation and Luau parsing before every merge.

### Stage 02 — Movement
1. Walk and sprint.
2. Directional dash.
3. Jump and air-state preservation.
4. Stun and movement locks.
5. Respawn after death.
6. Re-apply movement properties after each respawn.

### Stage 03 — Combat foundation
Use the smallest readable combat vocabulary:
- M1 combo
- Dash
- Block
- Special

Parry is a timing outcome of Block, not a fifth permanent combat button.

Server flow:
1. Client asks for an action.
2. Server rate-limits it.
3. Server checks player state.
4. Server computes the hitbox from server character position.
5. Server validates target type, distance and orientation.
6. Server applies damage, stun and knockback.
7. Server sends presentation feedback.

Do not accept a client-provided victim, damage amount, cooldown result or reward amount.

### Stage 04 — M1 quality

Four hits:
- Hit 1: fast opener.
- Hit 2: continuation.
- Hit 3: heavier confirm.
- Hit 4: finisher.

The finisher has grounded, uppercut and downslam variants. The server decides the variant from movement state before applying the hit.

Use spatial queries for reliable multi-target melee. Roblox documents `GetPartBoundsInBox()` and `GetPartBoundsInRadius()` for this class of query, with `OverlapParams` controlling filtering.

Animation markers can later synchronize authored animation windows with gameplay. Do not make gameplay dependent on an unavailable animation asset.

### Stage 05 — Special system

Specials are data-driven, but each fighter must have a distinct behavior class where appropriate:
- Burst
- Line
- Cone
- Pull
- DashStrike
- Blink
- Heal
- GuardBreak

Every Special has:
- energy cost
- cooldown
- startup
- active result
- recovery
- presentation
- awakening interaction

### Stage 06 — Awakening / Overdrive

1. Build Overdrive from combat.
2. Fill to 100.
3. Activate the fighter's Awakening state.
4. Apply temporary modifiers.
5. Reset meter.
6. End automatically.
7. Never allow Awakening through client-side state injection.

### Stage 07 — Domain

1. Require enough energy.
2. Require a fighter with a Domain.
3. Spawn a bounded domain zone.
4. Apply periodic server-side effects.
5. Detect nearby opposing domains.
6. Enter clash state.
7. Give both players exactly four universal clash moves.
8. Resolve by score.
9. Reset the clash on a draw.
10. Restore or destroy domains safely.

### Stage 08 — Destruction

Destruction must change positioning without permanently breaking the map:
1. Tag only approved breakable geometry.
2. Store MaxHP/HP on the server.
3. Disable collision/query when destroyed.
4. Restore after a bounded interval.
5. Cap the number of dynamic destructibles.
6. Never destroy the core floor or district connectors.

### Stage 09 — City

Keep five districts until combat and travel are stable:
- Origin
- Metro
- Core
- Iron
- Apex

Each district needs:
- a landmark
- a central fight space
- cover
- alternate routes
- some verticality
- selected interior/hero locations
- destruction-aware traversal

Use repeated cheap geometry for filler and reserve detail for hero landmarks.

### Stage 10 — HUD

Permanent combat HUD:
- HP
- energy
- awakening meter
- combo
- four combat actions
- compact location/status

Secondary screens:
- map
- missions
- fighter selection
- shop
- profile
- settings

Mobile:
- safe-area aware
- thumb reachable
- no tiny essential labels
- same server actions as keyboard/gamepad

### Stage 11 — Progression

Persist:
- Credits
- KOs
- XP
- Level
- owned cosmetics
- equipped fighter/title/item
- redeemed codes
- mission period counters

Session:
- current streak
- current combat state
- temporary meters

Use `UpdateAsync()` for writes that must tolerate concurrent server attempts. Use `BindToClose()` to save unsaved state during shutdown.

### Stage 12 — Economy

Credits are earned through gameplay. Keep combat power out of the cosmetic shop.

Content:
- skins
- emotes
- finishers
- kill effects
- banners/titles
- rotating cosmetic offers
- daily/weekly/lifetime missions

Developer Products must grant only server-defined rewards after Roblox purchase receipt processing.

### Stage 13 — QA gates

A build is not ready when the code merely parses. Verify:
1. clean boot
2. clean spawn
3. M1
4. block/parry
5. dash
6. special
7. awakening
8. domain
9. domain clash
10. draw reset
11. destruction/restore
12. respawn
13. shop ownership
14. mission claim
15. data save
16. mobile controls
17. gamepad controls
18. streaming/travel
19. external asset failure fallback
20. low-end mobile performance

## 3. Reference implementation sources

Use official Roblox documentation for engine contracts:
- Client/server security: https://create.roblox.com/docs/scripting/security/client-server-boundary
- Remote events: https://create.roblox.com/docs/scripting/events/remote
- Spatial queries: https://create.roblox.com/docs/reference/engine/classes/WorldRoot
- OverlapParams: https://create.roblox.com/docs/reference/engine/datatypes/OverlapParams
- Data stores: https://create.roblox.com/docs/cloud-services/data-stores
- Streaming: https://create.roblox.com/docs/workspace/streaming
- ScreenInsets: https://create.roblox.com/docs/reference/engine/enums/ScreenInsets
- ContextActionService: https://create.roblox.com/docs/reference/engine/classes/ContextActionService
- AnimationTrack markers: https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
- Performance: https://create.roblox.com/docs/performance-optimization
- MicroProfiler: https://create.roblox.com/docs/performance-optimization/microprofiler
- Creator Store: https://create.roblox.com/docs/production/creator-store

Public codebases useful as architecture references, subject to their licenses; do not copy proprietary game code:
- https://github.com/TeamSwordphin/ShapecastHitbox
- https://github.com/MadStudioRoblox/ProfileStore
- https://github.com/howmanysmall/Janitor
- https://github.com/evaera/roblox-lua-promise

## 4. Performance rules

Design for mobile from the beginning:
- use instance streaming
- avoid unnecessary per-frame server loops
- cap VFX
- cap destructibles
- use client-side presentation for non-authoritative FX
- profile real sessions with MicroProfiler and Script Profiler
- test on low/mid Android before increasing visual density

Roblox recommends using built-in performance tools to identify, improve and monitor frame-time, memory and load-time issues.

## 5. Asset rules

External assets are optional and must not be required for the base game to boot.

For every imported asset:
- verify usable rights
- avoid giant unoptimized packs
- remove unexpected scripts from third-party models
- keep gameplay colliders simple
- prefer a small family of coherent props
- reserve high-detail meshes for hero locations

## 6. Definition of done

Production-ready means:
- clean server boot
- no placeholder-only menu panels
- all core actions work on touch/keyboard/gamepad
- server validates all progression/combat requests
- death always returns the player to gameplay
- destruction restores
- streaming does not strand the player
- external asset failure cannot break gameplay
- low-end mobile remains responsive during a real multi-player fight
- the place can be built reproducibly from the repository
