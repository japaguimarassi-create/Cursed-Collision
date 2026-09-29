# Collision Battlestar Foundation Rebuild — Design Specification

**Date:** 2026-09-29
**Branch:** `rebuild/collision-battlestar-foundation`
**Current repository:** `japaguimarassi-create/Cursed-Collision`
**Roblox Universe:** `5290480963`
**Roblox Place:** `15338267657`

## 1. Decision

The project will be rebuilt in two deliberate layers:

1. **Playable Core:** a small, complete gameplay loop that is easy to test and understand.
2. **Advanced Systems:** progression, persistence, content breadth, PvP, monetization, analytics, and other long-term systems added only after the core loop is stable.

The repository history remains intact. The current `main` branch is not modified during the foundation rebuild.

The game identity is separated from the repository name. The current product identity is **Collision Battlestar**, while the repository may continue to be named `Cursed-Collision`. A future decision to restore the **Cursed Collision** identity must be possible without rewriting gameplay architecture.

## 2. Product Goal

The first playable build must answer one question:

> Can a new player join, immediately understand the objective, fight enemies, defeat a red Elite, earn Credits, and start another wave without encountering loading deadlocks or broken controls?

The first build is not intended to contain every planned system.

## 3. Phase A — Playable Core

### Required gameplay

- Player spawn and respawn.
- One combat arena.
- Automatic wave lifecycle.
- Increasing enemy difficulty.
- Multiple enemy tiers.
- One strongest enemy per active wave marked clearly in red as the Elite.
- Server-authoritative M1 attack with a short combo chain.
- Server-authoritative directional dash.
- Damage, hit validation, cooldowns, knockback and death handling.
- Credits for valid enemy defeats.
- Wave-clear reward.
- One basic upgrade path sufficient to prove progression plumbing.
- Minimal mobile-first HUD.
- Keyboard/controller input support without creating a second gameplay implementation.
- Basic combat feedback: hit reaction, impact feedback and dash feedback.

### Explicitly deferred from Phase A

- Full inventory.
- Full persistence economy.
- Companions.
- Large skin catalog.
- Full Shop.
- Robux product catalog.
- GamePass catalog.
- PvP matchmaking or advanced PvP rules.
- Missions/dailies/weeklies.
- Large multi-district city.
- Boss roster.
- Complex events.
- Awakening/domain/special ability systems.
- AI self-repair.
- Multiple competing HUD loaders/watchdogs.
- Large UI navigation tree.

These features may have architectural interfaces, but their production implementations are not part of the first playable core.

## 4. Phase B — Advanced Systems

After Phase A passes runtime validation, the following systems may be introduced one at a time:

1. Versioned player profile and safe persistence.
2. Damage/Defense/Speed progression.
3. Companion system.
4. Skin ownership/equipment.
5. Full Shop and monetization.
6. Separate distant PvP battleground.
7. Owner-only Admin controls.
8. Missions and long-term objectives.
9. Larger world/content packages.
10. Bosses, events and additional enemy behaviors.
11. Runtime analytics/telemetry and production tuning.

Each item receives its own design boundary and tests before implementation.

## 5. Architecture

The foundation uses one responsibility per module.

### Shared

`ReplicatedStorage/Shared`

- `Constants`: immutable runtime constants.
- `Definitions`: enemy, wave and gameplay definitions.
- `Config`: validated configuration exposed to client/server as appropriate.
- `Types`: shared Luau type definitions.
- `GameIdentity`: display name, repository-independent identity and version metadata.

### Remotes

`ReplicatedStorage/Remotes`

Only explicitly defined remote contracts exist here.

Initial contracts:

- `Combat`
- `State`
- `FX`

A client request never represents a final game outcome.

### Server

`ServerScriptService/CollisionBattlestar/`

- `Bootstrap`
- `Core/ServiceRegistry`
- `Core/RuntimeState`
- `Core/PlayerState`
- `Combat`
- `Waves`
- `Enemies`
- `Economy`
- `World`
- `Security`

Later systems extend the same boundaries rather than replacing them.

### Client

`StarterPlayer/StarterPlayerScripts/CollisionBattlestar/`

- `ClientBootstrap`
- `Input`
- `HUD`
- `CombatFX`
- `Camera`

There is exactly one client bootstrap and one active HUD root.

No recovery script, watchdog or fallback system is allowed to silently become a second gameplay implementation.

## 6. Runtime Data Flow

### Join

`Join → Profile/PlayerState initialize → Character ready → World ready → HUD ready → gameplay enabled`

The HUD must not block the game with an indefinite loading state.

### Combat

`Input → Combat request → Server validation → Hitbox calculation → Damage/Knockback → State broadcast → Client presentation`

The client may predict visual responsiveness but never grants itself damage, currency, kills or progression.

### Wave

`Wave start → Spawn → Active combat → Enemy deaths → Elite defeated → Wave clear → Reward → Intermission → Next wave`

The wave state is owned by the server.

## 7. Enemy Model

Phase A supports:

- Tier 1.
- Tier 2.
- Tier 3.
- Elite.

The Elite is the strongest enemy of the wave and receives a visually unambiguous red threat treatment.

NPC behavior is deliberately limited in the first phase:

`Acquire target → Move → Attack → Recover`

Navigation and combat behavior remain separate modules so more advanced behavior can be added later.

## 8. World

Phase A uses a compact arena designed for:

- unobstructed combat readability;
- several movement routes;
- enough cover for tactical movement;
- clear enemy spawn boundaries;
- safe player spawn;
- a visually distinct Elite presence.

The previous large urban Battle Line concept remains a later content package rather than a requirement for the first playable build.

## 9. HUD

The first HUD is intentionally small.

It must communicate:

- player health;
- Credits;
- current Wave;
- enemies remaining;
- Elite presence;
- M1 action;
- Dash action;
- one Menu entry for future systems.

Mobile controls occupy comfortable thumb zones without covering the combat center.

The HUD is presentation only. It does not own gameplay state.

## 10. Security

Security is designed from the first playable build rather than added later.

For every state-changing remote, the server validates:

- player identity;
- action type;
- current gameplay state;
- zone;
- cooldown;
- character validity;
- target validity;
- distance/range;
- hit context;
- requested direction where relevant;
- ownership/permission where relevant.

No client-supplied value is trusted merely because the client supplied it.

Third-party assets are not allowed to execute arbitrary server logic in the core gameplay path.

## 11. Assets and Visual Research

Visual research is divided into reference groups:

- mobile combat HUDs;
- wave-survival HUDs;
- boss/Elite presentation;
- arena layouts;
- urban combat environments;
- minimalist PvP maps;
- upgrade/shop presentation;
- companion presentation;
- combat VFX and hit feedback;
- onboarding and wave readability.

The research pass uses current Roblox examples and platform documentation as inspiration and evidence, not as a request to copy another game's proprietary interface.

The implementation should prefer:

1. self-authored/procedural assets;
2. Roblox-authored resources;
3. inspected and permitted Creator Store resources;
4. other resources only after explicit license/use verification.

The research pass cannot literally collect thousands of image files in a single search operation. Representative searches are used to establish visual directions, and additional targeted searches are repeated when a concrete visual decision is reached. Reference images are not bundled into the production game unless their rights and intended use are independently verified.

## 12. Performance

Phase A targets mobile first.

Performance budgets are established before content expansion for:

- maximum active NPC count;
- VFX lifetime/count;
- particles;
- animated UI elements;
- expensive spatial queries;
- pathfinding frequency;
- decorative geometry;
- network event frequency.

Streaming can be enabled for larger later worlds, but the first arena should remain small enough that gameplay does not depend on streamed state behaving like a static world.

## 13. Testing Strategy

The project follows TDD for new production systems.

For each core system:

1. Write the failing test/contract.
2. Implement the minimum behavior.
3. Make the test pass.
4. Run static validation.
5. Build with Rojo.
6. Run the runtime test available for the current environment.
7. Inspect results.
8. Only then add the next subsystem.

Phase A acceptance requires at minimum:

- player can spawn;
- player can attack;
- attack can damage a valid enemy;
- invalid attack requests cannot grant damage;
- dash moves the player through a valid direction;
- wave spawns correctly;
- enemies can target and attack players;
- Elite is always the strongest configured enemy in its wave;
- Elite receives the red presentation;
- enemy death grants the correct server-owned reward;
- clearing a wave advances the state correctly;
- HUD shows the authoritative state;
- respawn does not break the gameplay loop.

A successful source build is not considered proof of runtime correctness.

## 14. Git Strategy

Base branch remains:

`main`

Foundation branch:

`rebuild/collision-battlestar-foundation`

All Phase A changes land on the foundation branch first.

The branch is merged only after:

- specification approval;
- implementation plan approval;
- TDD evidence;
- static validation;
- successful Rojo build;
- available runtime verification;
- final architectural review.

The legacy implementation is retained in Git history and may be mined for requirements, but legacy modules are not copied merely to preserve code.

## 15. Return-to-Cursed-Collision Compatibility

A future identity change is permitted.

The implementation must not encode `Collision Battlestar` into gameplay semantics such as:

- combat logic;
- wave logic;
- enemy logic;
- economy;
- persistence schemas;
- remote names;

unless the name is genuinely part of user-facing content.

This permits a future product-level rename or revival of **Cursed Collision** without requiring another architectural rebuild.

## 16. Research-Driven Decision Rule

Important decisions use:

`Question → Evidence → Alternatives → Decision → Test → Result`

Secondary decisions follow the same process when they affect:

- gameplay readability;
- performance;
- security;
- persistence;
- monetization;
- compatibility;
- player onboarding;
- maintainability.

When evidence is insufficient, the design records uncertainty instead of inventing certainty.

## 17. Definition of Done for Phase A

Phase A is complete only when the first-time player loop can be played continuously:

`Join → Spawn → Fight → Kill → Earn → Elite → Clear Wave → Upgrade → Next Wave`

with no permanent loading deadlock, no client-authoritative progression, no duplicate HUD controller, and no dependency on unverified third-party gameplay scripts.

Only after this loop is stable does Phase B begin.
