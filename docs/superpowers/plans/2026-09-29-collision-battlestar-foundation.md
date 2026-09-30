# Collision Battlestar Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy multi-loader PvE/PvP runtime on `rebuild/collision-battlestar-foundation` with one tested, mobile-first Phase A loop: Join → Spawn → Fight → Kill → Earn → Elite → Clear Wave → Upgrade → Next Wave.

**Architecture:** Use thin Roblox adapters around small, pure Luau rules modules so combat, wave progression, economy, and security decisions can be tested without Roblox Studio. The runtime has one server bootstrap, one service registry, one client bootstrap, one HUD root, three explicit RemoteEvents (`Combat`, `State`, `FX`), and server-owned state. The legacy systems are removed from the active source tree rather than migrated piecemeal.

**Tech Stack:** Roblox Luau; Rojo 7.6.0; Luau 0.739; RemoteEvents; PathfindingService; UserInputService/ContextActionService; procedural Parts/UI; Python stdlib validation.

**Spec:** `docs/superpowers/specs/2026-09-29-collision-battlestar-foundation-design.md`

## Global Constraints

- Product identity: `Collision Battlestar`; repository name remains `Cursed-Collision`.
- Branch: `rebuild/collision-battlestar-foundation`; `main` is not modified.
- Roblox Universe: `5290480963`.
- Roblox Place: `15338267657`.
- Toolchain: Rojo `7.6.0`; Luau `0.739`.
- Phase A contains only the gameplay loop and support required by the approved specification.
- No DataStore persistence, companions, full inventory, full shop, monetization catalog, gamepasses, PvP systems, missions, boss roster, large city, awakening/domain systems, or AI self-repair are implemented in Phase A.
- Exactly three initial RemoteEvents exist: `Combat`, `State`, `FX`.
- Client requests are never treated as authoritative outcomes.
- Exactly one client bootstrap and one active HUD root exist.
- No HUD watchdog, fallback loader, duplicate combat implementation, or indefinite loading gate is allowed.
- Core gameplay contains no unverified third-party gameplay scripts or arbitrary dynamic `require`/code loading.
- New production systems follow TDD: failing test → minimal implementation → passing test → static validation → Rojo build → available runtime verification.
- The future Cursed Collision identity remains possible because product naming is isolated to `GameIdentity` and user-facing presentation.
- Mobile is the primary target. Interactive HUD uses `CoreUISafeInsets`, avoids Roblox reserved thumb-control zones, and uses responsive sizing/constraints. Roblox documents `CoreUISafeInsets` as the recommended inset for important interactive UI and recommends avoiding bottom-left/bottom-right mobile control zones. Source: https://create.roblox.com/docs/reference/engine/enums/ScreenInsets and https://create.roblox.com/docs/ui/position-and-size
- Server security follows Roblox's current client-server boundary guidance: validate type/structure, context/permission, value/range, timing/rate, instance location/class, and state before acting. Source: https://create.roblox.com/docs/scripting/security/client-server-boundary
- Pathfinding uses `PathfindingService:CreatePath()`; Phase A caps recomputation at 2 Hz per active enemy and recomputes early only when the current path becomes blocked or invalid. Source: https://create.roblox.com/docs/reference/engine/classes/PathfindingService/CreatePath
- Phase A performance budget: 20 active enemies maximum, 24 concurrently tracked FX instances maximum, no per-frame gameplay RemoteEvent, state broadcasts only on authoritative changes, one AI update loop at 10 Hz, path recomputation at ≤2 Hz per enemy.
- Phase A combat constants are fixed for the first playable evaluation: player base health 100; M1 damage 25/30/35 by combo step; combo window 0.8 s; M1 minimum interval 0.38 s; hit range 8 studs; dash cooldown 0.9 s; dash speed 70 studs/s; dash duration 0.12 s.
- Phase A enemy definitions are fixed initially: Tier1 60 HP / 8 damage / 5 Credits; Tier2 110 HP / 12 damage / 8 Credits; Tier3 180 HP / 18 damage / 12 Credits; Elite 350 HP / 28 damage / 30 Credits.
- Phase A waves start at 6 enemies and add 2 enemies per wave up to the 20-enemy cap; one and only one Elite is spawned in every active wave; Elite is always the highest configured HP and damage tier in that wave.
- Wave-clear reward is `25 * waveNumber` Credits.
- Basic upgrade is Damage: each level adds 5 base M1 damage; first purchase costs 50 Credits, and cost doubles each level.
- Upgrade interaction is a server-side ProximityPrompt, not a client-owned economy remote.
- Source-generated arena is compact and procedural; no third-party model is required for the core loop.

## Review Focus

1. Malformed or spoofed `Combat` requests must be rejected without damage, movement, currency, or progression changes — covered by `SecurityRulesSpec.rejectsMalformedCombatPayload`.
2. Duplicate or spammed attack/dash requests must not bypass cooldowns or create duplicate hits — covered by `CombatRulesSpec.enforcesAttackAndDashRateLimits`.
3. Simultaneous last-enemy deaths must produce exactly one wave clear and one wave reward — covered by `WaveRulesSpec.isIdempotentDuringWaveClear`.
4. Player respawn during or immediately after a wave must restore a valid character without resetting server wave state — covered by `PlayerStateSpec.respawnPreservesSessionState`.
5. Extreme mobile aspect ratios must preserve interactive button reachability and safe-area placement — covered by `HUDSpec.usesSafeAreaAndThumbZones`.

---

### Task 1: Establish the Phase A test harness and clean runtime boundary

**Files:**
- Create: `tests/CollisionBattlestar/TestRunner.luau`
- Create: `tests/CollisionBattlestar/CombatRulesSpec.luau`
- Create: `tests/CollisionBattlestar/WaveRulesSpec.luau`
- Create: `tests/CollisionBattlestar/EconomyRulesSpec.luau`
- Create: `tests/CollisionBattlestar/SecurityRulesSpec.luau`
- Create: `tests/CollisionBattlestar/PlayerStateSpec.luau`
- Create: `tests/CollisionBattlestar/HUDSpec.luau`
- Create: `tools/run_tests.py`
- Modify: `tools/validate_project.py`
- Modify: `.github/workflows/validate.yml`
- Delete: legacy active runtime files under `src/CollisionBattlestar/ServerScriptService/Systems/`
- Delete: `src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua`
- Delete: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/CameraFX.client.lua`
- Delete: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua`
- Delete: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/CombatFX.client.lua`
- Delete: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/HUDWatchdog.client.lua`
- Delete: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/InputController.client.lua`
- Delete: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/MenuSystem.client.lua`
- Delete: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/UIController.client.lua`
- Delete: all legacy modules under `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/HUD/`
- Retain: `default.project.json`, `rokit.toml`, repository docs, manifests, and Git history.

**Interfaces:**
- Produces the test entrypoint `tools/run_tests.py`, which invokes the installed `luau` executable on `tests/CollisionBattlestar/TestRunner.luau`.
- Produces pure-module test contracts that later tasks must satisfy.
- The validation script must reject any legacy runtime file listed above and must require the new Phase A tree instead.

- [ ] **Step 1: Write failing test contracts** for the five Review Focus cases plus the Phase A acceptance invariants.
- [ ] **Step 2: Run `python3 tools/run_tests.py`** and verify the suite fails because the new rules modules do not exist.
- [ ] **Step 3: Implement the test runner and update validation only**, without implementing gameplay rules yet. The runner must return non-zero when any assertion fails and print the failing spec name.
- [ ] **Step 4: Run the targeted tests again** and verify the harness itself runs while the rules remain failing.
- [ ] **Step 5: Update CI** so validation runs on `main`, `rebuild/**`, and pull requests targeting `main`; run `python3 tools/validate_project.py` and `python3 tools/run_tests.py` before the Rojo build.
- [ ] **Step 6: Commit** with `test: establish collision battlestar phase a harness`.

---

### Task 2: Implement shared contracts, constants, definitions, and identity

**Files:**
- Create: `src/CollisionBattlestar/ReplicatedStorage/Shared/Constants.lua`
- Create: `src/CollisionBattlestar/ReplicatedStorage/Shared/Definitions.lua`
- Create: `src/CollisionBattlestar/ReplicatedStorage/Shared/Types.lua`
- Create: `src/CollisionBattlestar/ReplicatedStorage/Shared/GameIdentity.lua`
- Replace: `src/CollisionBattlestar/ReplicatedStorage/Shared/Config.lua`
- Create: `src/CollisionBattlestar/ReplicatedStorage/Remotes/.keep` or equivalent Rojo folder representation if needed
- Modify: `tests/CollisionBattlestar/CombatRulesSpec.luau`
- Modify: `tests/CollisionBattlestar/WaveRulesSpec.luau`
- Modify: `tests/CollisionBattlestar/EconomyRulesSpec.luau`

**Interfaces:**
- `Constants` exports the exact Phase A combat, wave, AI, arena, reward, and performance constants from the Global Constraints.
- `Definitions` exports `EnemyTiers` and `WaveRules`; each enemy definition contains `Id`, `MaxHealth`, `Damage`, `Reward`, `WalkSpeed`, `AttackRange`, and `IsElite`.
- `Types` exports `CombatAction`, `CombatRequest`, `GameSnapshot`, `EnemyState`, and `WaveState`.
- `GameIdentity` exports `DisplayName = "Collision Battlestar"`, `ProductId = "collision-battlestar"`, and a semantic `Version` string without embedding the display name into gameplay keys.
- `Config` returns a validated aggregate of these shared values and does not require a legacy `GameProgram`.

- [ ] **Step 1: Extend the failing specs** to assert the exact constants, four enemy tiers, one Elite per wave, reward values, and identity separation.
- [ ] **Step 2: Run the shared specs** and verify failure on missing modules/values.
- [ ] **Step 3: Implement the four modules** with no `game` access so they remain standalone-testable.
- [ ] **Step 4: Run `python3 tools/run_tests.py`** and verify all shared/rules assertions owned by this task pass.
- [ ] **Step 5: Run `python3 tools/validate_project.py`** and verify no merge markers, dynamic loading, or legacy configuration remains.
- [ ] **Step 6: Commit** with `feat: define phase a shared contracts`.

---

### Task 3: Implement pure combat and security rules

**Files:**
- Create: `src/CollisionBattlestar/ReplicatedStorage/Shared/CombatRules.lua`
- Create: `src/CollisionBattlestar/ReplicatedStorage/Shared/SecurityRules.lua`
- Modify: `tests/CollisionBattlestar/CombatRulesSpec.luau`
- Modify: `tests/CollisionBattlestar/SecurityRulesSpec.luau`

**Interfaces:**
- `CombatRules.newPlayerCombatState(now) -> CombatState`
- `CombatRules.canAttack(state, now) -> (boolean, reason)`
- `CombatRules.registerAttack(state, now) -> AttackResult`
- `CombatRules.computeComboDamage(comboStep, baseDamage) -> number`
- `CombatRules.canDash(state, now) -> (boolean, reason)`
- `CombatRules.registerDash(state, now) -> ()`
- `CombatRules.sanitizeDirection(direction) -> Vector3-like normalized horizontal direction or nil`
- `SecurityRules.validateCombatRequest(request) -> (boolean, reason)`
- `SecurityRules.validateTarget(targetRecord, attackerPosition, maxRange) -> (boolean, reason)`
- `SecurityRules.validateZone(zone) -> boolean`

- [ ] **Step 1: Write/extend failing tests** for combo progression, combo timeout reset, attack interval, dash cooldown, zero/NaN-like invalid directions represented by the test harness, vertical direction rejection, range checks, wrong action types, oversized request tables, and invalid zone values.
- [ ] **Step 2: Run the combat/security specs** and verify failure.
- [ ] **Step 3: Implement the minimum pure rules**. Combo advancement is server-clock based; client timestamps are ignored. Direction is normalized from horizontal X/Z components and rejected when its magnitude is effectively zero.
- [ ] **Step 4: Run the focused specs** and verify PASS.
- [ ] **Step 5: Run the full test suite** and verify PASS.
- [ ] **Step 6: Commit** with `feat: add authoritative combat rules`.

---

### Task 4: Implement server core state, player state, and remote contracts

**Files:**
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Core/ServiceRegistry.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Core/RuntimeState.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Core/PlayerState.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Security/Service.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Bootstrap.server.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Combat/Service.lua`
- Create: `src/CollisionBattlestar/ReplicatedStorage/Shared/RemoteContracts.lua`
- Modify: `tests/CollisionBattlestar/PlayerStateSpec.luau`
- Modify: `tools/validate_project.py`

**Interfaces:**
- `RuntimeState:create() -> RuntimeState`
- `RuntimeState:GetWave() -> WaveState`
- `RuntimeState:SetWave(state) -> ()`
- `RuntimeState:GetEnemiesRemaining() -> number`
- `RuntimeState:SetEnemiesRemaining(count) -> ()`
- `RuntimeState:IsWaveActive() -> boolean`
- `RuntimeState:SetWaveActive(active) -> ()`
- `PlayerState:InitPlayer(player) -> PlayerSession`
- `PlayerState:Get(player) -> PlayerSession?`
- `PlayerState:Remove(player) -> ()`
- `PlayerState:GetCredits(player) -> number`
- `PlayerState:AddCredits(player, amount, reason) -> boolean`
- `PlayerState:GetUpgradeLevel(player, "Damage") -> number`
- `PlayerState:ApplyDamageUpgrade(player) -> (boolean, reason, newLevel)`
- `PlayerState:OnCharacterReady(player, character) -> ()`
- `ServiceRegistry:Register(name, service) -> ()`
- `ServiceRegistry:Get(name) -> service?`
- `RemoteContracts.ensure(remotesFolder) -> {Combat, State, FX}`
- `Combat.Service:Init(context) -> ()`
- `Combat.Service:HandleRequest(player, request) -> ()`

- [ ] **Step 1: Write failing tests** for session initialization, zero starting Credits, upgrade pricing, successful purchase, insufficient Credits, reward ownership, and respawn preserving Credits/upgrade/wave state.
- [ ] **Step 2: Run `PlayerStateSpec`** and verify failure.
- [ ] **Step 3: Implement pure session bookkeeping** inside `PlayerState` with session-only state; do not use DataStore.
- [ ] **Step 4: Implement `ServiceRegistry`, `RuntimeState`, and `RemoteContracts`** with explicit service dependencies and no dynamic service discovery.
- [ ] **Step 5: Implement `Bootstrap.server.lua`** to initialize exactly the three remotes, disable legacy systems by their absence, register services, attach PlayerAdded/Removing/CharacterAdded, and never yield on HUD state.
- [ ] **Step 6: Run tests and static validation** and verify the new bootstrap tree is the only server entrypoint.
- [ ] **Step 7: Commit** with `feat: build phase a server core`.

---

### Task 5: Implement the procedural arena and player spawn/respawn flow

**Files:**
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/World/Service.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/World/ArenaBuilder.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/World/SpawnController.lua`
- Modify: `tests/CollisionBattlestar/PlayerStateSpec.luau`

**Interfaces:**
- `ArenaBuilder.build() -> Model`
- `ArenaBuilder.getPlayerSpawn() -> SpawnLocation|BasePart`
- `ArenaBuilder.getEnemySpawnPoints() -> {BasePart}`
- `SpawnController:Init(world, playerState) -> ()`
- `SpawnController:ConfigurePlayer(player) -> ()`
- `SpawnController:RespawnAtSafeSpawn(player, character) -> ()`
- `World.Service:Init(context) -> ()`
- `World.Service:GetArena() -> Model`
- `World.Service:IsInsideArena(position) -> boolean`

- [ ] **Step 1: Add failing assertions** for a compact arena, one safe player spawn, multiple enemy spawn points, world-boundary detection, and respawn preserving session state.
- [ ] **Step 2: Run the world/spawn assertions** and verify failure.
- [ ] **Step 3: Implement `ArenaBuilder`** as procedural anchored Parts: a ~160×120 combat floor, four cover clusters, clear center, perimeter barriers, one safe player spawn, and six enemy spawn points.
- [ ] **Step 4: Implement `SpawnController`** with server-owned spawn/respawn and no dependency on streamed decorative content.
- [ ] **Step 5: Run static validation and a Rojo build** and verify the generated place is non-empty.
- [ ] **Step 6: Commit** with `feat: add phase a arena and respawn`.

---

### Task 6: Implement enemy definitions, AI, Elite presentation, and waves

**Files:**
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Enemies/Service.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Enemies/EnemyFactory.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Enemies/EnemyBrain.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Enemies/Navigation.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Waves/Service.lua`
- Create: `src/CollisionBattlestar/ReplicatedStorage/Shared/WaveRules.lua`
- Modify: `tests/CollisionBattlestar/WaveRulesSpec.luau`

**Interfaces:**
- `WaveRules.enemyCount(waveNumber) -> number`
- `WaveRules.buildComposition(waveNumber) -> {tierIds}`
- `WaveRules.selectEliteTier(composition, definitions) -> tierId`
- `WaveRules.isClear(enemiesAlive) -> boolean`
- `WaveRules.beginNextWave(currentWave) -> number`
- `WaveRules.calculateClearReward(waveNumber) -> number`
- `Enemies.Service:Init(context) -> ()`
- `Enemies.Service:SpawnEnemy(tierId, spawnPoint, isElite) -> Model`
- `Enemies.Service:DamageEnemy(enemy, amount, attacker) -> DamageResult`
- `Enemies.Service:RemoveEnemy(enemy, reason) -> ()`
- `Enemies.Service:GetActiveCount() -> number`
- `Enemies.Service:GetActiveEnemies() -> {Model}`
- `EnemyBrain.new(enemy, definition, context) -> Brain`
- `EnemyBrain:Step(now) -> ()`
- `Navigation.new(enemy, context) -> Navigator`
- `Navigation:MoveToward(targetPosition, now) -> ()`
- `Waves.Service:Init(context) -> ()`
- `Waves.Service:StartWave(waveNumber) -> ()`
- `Waves.Service:HandleEnemyDeath(enemy) -> ()`
- `Waves.Service:IsActive() -> boolean`
- `Waves.Service:GetSnapshot() -> WaveState`

- [ ] **Step 1: Write failing tests** for wave counts, composition scaling, exactly one Elite, Elite dominance, clear idempotence, reward math, and progression from wave N to N+1.
- [ ] **Step 2: Run the wave specs** and verify failure.
- [ ] **Step 3: Implement pure `WaveRules`** using the fixed 6→8→10…→20 enemy cap and guaranteed Elite.
- [ ] **Step 4: Implement `EnemyFactory`** with procedural Roblox NPC models built from Parts/Humanoid/HumanoidRootPart; no external gameplay scripts.
- [ ] **Step 5: Implement `Navigation`** with `PathfindingService:CreatePath()`, agent parameters matched to the generated NPC dimensions, 2 Hz maximum path recomputation, and recomputation on blocked/invalid paths.
- [ ] **Step 6: Implement `EnemyBrain`** with the exact Phase A state sequence `Acquire target → Move → Attack → Recover`, attack range validation, attack cooldown, and server damage to the player Humanoid.
- [ ] **Step 7: Implement `Waves.Service`** to own wave lifecycle, spawn order, Elite flagging, enemy death notifications, one-time clear reward, intermission, and next-wave scheduling.
- [ ] **Step 8: Add Elite presentation** using a red Highlight plus BillboardGui threat label generated by the factory/service and cleaned with the enemy model.
- [ ] **Step 9: Run full tests, static validation, and Rojo build**. Record any runtime-only limitations instead of treating the source build as runtime proof.
- [ ] **Step 10: Commit** with `feat: implement phase a enemies and waves`.

---

### Task 7: Implement authoritative M1, dash, rewards, upgrade interaction, and FX events

**Files:**
- Modify: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Combat/Service.lua`
- Create: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Economy/Service.lua`
- Modify: `src/CollisionBattlestar/ReplicatedStorage/Shared/RemoteContracts.lua`
- Modify: `tests/CollisionBattlestar/CombatRulesSpec.luau`
- Modify: `tests/CollisionBattlestar/EconomyRulesSpec.luau`
- Modify: `tests/CollisionBattlestar/SecurityRulesSpec.luau`

**Interfaces:**
- `Combat.Service:Init(context) -> ()`
- `Combat.Service:OnCombatRequest(player, request) -> ()`
- `Combat.Service:PerformM1(player) -> CombatResult`
- `Combat.Service:PerformDash(player, direction) -> boolean`
- `Combat.Service:FindHits(player) -> {Model}`
- `Economy.Service:Init(context) -> ()`
- `Economy.Service:AwardKill(player, enemyDefinitionId) -> boolean`
- `Economy.Service:AwardWaveClear(player, waveNumber) -> boolean`
- `Economy.Service:CreateUpgradePrompt(parent) -> ProximityPrompt`
- `Economy.Service:HandleUpgradePrompt(player) -> (boolean, reason)`

- [ ] **Step 1: Add failing tests** for M1 hitbox eligibility, combo damage, invalid target rejection, out-of-range rejection, duplicate hit suppression within one action, dash direction normalization, dash cooldown, kill reward, wave reward, and upgrade purchase.
- [ ] **Step 2: Run the focused tests** and verify failure.
- [ ] **Step 3: Implement server M1** using an overlap/raycast-based hit calculation centered on the server's character facing and range; do not consume a target supplied by the client. Apply 25/30/35 base damage before future upgrades.
- [ ] **Step 4: Implement server dash** using the sanitized horizontal direction and server-controlled movement; reject invalid direction, dead characters, non-PvE zones, and cooldown violations.
- [ ] **Step 5: Integrate enemy death rewards** so only the server's death handler can award kill Credits.
- [ ] **Step 6: Implement the physical Damage upgrade prompt** with price doubling, server-side balance checks, and authoritative stat update.
- [ ] **Step 7: Broadcast `State` snapshots only after authoritative changes** and send `FX` messages for accepted hit, hit reaction, dash, Elite death, and wave transition effects.
- [ ] **Step 8: Run tests, static validation, and Rojo build** and verify all non-runtime acceptance contracts pass.
- [ ] **Step 9: Commit** with `feat: connect authoritative combat and economy`.

---

### Task 8: Implement one client input path, mobile-first HUD, combat FX, and camera

**Files:**
- Create: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/CollisionBattlestar/ClientBootstrap.client.lua`
- Create: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/CollisionBattlestar/Input/Controller.lua`
- Create: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/CollisionBattlestar/HUD/Root.lua`
- Create: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/CollisionBattlestar/HUD/Widgets.lua`
- Create: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/CollisionBattlestar/CombatFX/Service.lua`
- Create: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/CollisionBattlestar/Camera/Service.lua`
- Modify: `tests/CollisionBattlestar/HUDSpec.luau`

**Interfaces:**
- `Input.Controller:Init(remotes, hud) -> ()`
- `Input.Controller:RequestM1() -> ()`
- `Input.Controller:RequestDash(direction) -> ()`
- `HUD.Root.new(playerGui) -> HUDRoot`
- `HUDRoot:SetSnapshot(snapshot) -> ()`
- `HUDRoot:SetNotice(text) -> ()`
- `HUDRoot:SetActionEnabled(action, enabled) -> ()`
- `HUDRoot:Destroy() -> ()`
- `CombatFX.Service:Init(remotes) -> ()`
- `Camera.Service:Init() -> ()`

- [ ] **Step 1: Write failing HUD tests** for one ScreenGui root, `CoreUISafeInsets`, health/Credits/wave/enemy/Elite text fields, M1/Dash buttons in thumb zones, one Menu entry, and no loading gate.
- [ ] **Step 2: Run `HUDSpec`** and verify failure.
- [ ] **Step 3: Implement `HUD.Root`** as the only gameplay HUD. Use safe-area insets, scale-based sizing plus constraints, and a sparse layout that leaves the combat center open.
- [ ] **Step 4: Implement `Input.Controller`** so keyboard, gamepad, and touch controls call the same `RequestM1`/`RequestDash` methods. Bind keyboard/gamepad through `ContextActionService`; touch buttons call the same methods rather than bypassing them.
- [ ] **Step 5: Implement `ClientBootstrap.client.lua`** as the only client entrypoint. It creates HUD immediately, subscribes to `State`/ `FX`, and never waits on a remote response before enabling gameplay input.
- [ ] **Step 6: Implement `CombatFX.Service`** for hit reaction, impact feedback, dash feedback, Elite threat emphasis, and compact camera shake; effects are client-only and bounded by the Phase A FX budget.
- [ ] **Step 7: Implement `Camera.Service`** with a readable third-person combat camera and no separate camera script.
- [ ] **Step 8: Run HUD tests, full tests, static validation, and Rojo build** and verify exactly one client bootstrap and one HUD root remain.
- [ ] **Step 9: Commit** with `feat: add unified mobile-first client foundation`.

---

### Task 9: Integrate the complete Phase A loop and harden validation

**Files:**
- Modify: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Bootstrap.server.lua`
- Modify: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Core/RuntimeState.lua`
- Modify: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Waves/Service.lua`
- Modify: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Enemies/Service.lua`
- Modify: `src/CollisionBattlestar/ServerScriptService/CollisionBattlestar/Economy/Service.lua`
- Modify: `src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/CollisionBattlestar/ClientBootstrap.client.lua`
- Modify: `tools/validate_project.py`
- Modify: `README.md`
- Create: `docs/PHASE_A_RUNTIME_CHECKLIST.md`
- Modify: `tests/CollisionBattlestar/` specs as needed for integration contracts

**Interfaces:**
- `RuntimeState:Snapshot() -> GameSnapshot`
- `Waves.Service:PublishSnapshot() -> ()`
- `Economy.Service:PublishPlayerSnapshot(player) -> ()`
- Client HUD consumes only the declared `GameSnapshot` shape.

- [ ] **Step 1: Write failing integration contracts** for Join → Spawn → Wave 1, attack → kill → reward, Elite spawn/defeat, wave clear → reward → intermission → next wave, upgrade purchase, and respawn.
- [ ] **Step 2: Run the integration suite** and verify failure in at least one end-to-end contract before the final wiring changes.
- [ ] **Step 3: Implement the final server orchestration** so startup order is deterministic: shared config → remotes → core state/player state → world → security → enemies → combat → economy → waves.
- [ ] **Step 4: Implement authoritative snapshots** with a stable schema covering health, max health, Credits, wave, enemies remaining, Elite presence, upgrade level, and gameplay-ready state.
- [ ] **Step 5: Implement lifecycle guards** so no wave can clear twice, no reward can be duplicated, no dead player can attack/dash, and no stale enemy death event can advance a finished wave.
- [ ] **Step 6: Harden validation** to require the final source tree, reject any old Systems/Client/HUD runtime modules, reject dynamic code loading, and validate exactly one client bootstrap plus exactly three remote contracts.
- [ ] **Step 7: Update README and create the runtime checklist** with manual Roblox verification steps for mobile, keyboard, and controller.
- [ ] **Step 8: Run the complete local gate**:
  `python3 tools/run_tests.py`
  `python3 tools/validate_project.py`
  `rojo build default.project.json --output build/CollisionBattlestar.rbxl`
  and verify the output file is non-empty.
- [ ] **Step 9: Run CI for the foundation branch** and record the run URL/commit SHA. Do not equate CI success with runtime success.
- [ ] **Step 10: Run the available Roblox runtime verification**. Confirm the actual acceptance loop in a live Roblox session when a Roblox runtime/device bridge is available; otherwise record runtime verification as not available and leave the branch unmerged.
- [ ] **Step 11: Perform a final architectural review** against the approved specification, including the five Review Focus cases and all 17 specification sections.
- [ ] **Step 12: Commit** with `test: verify phase a foundation loop`.

---

## Final Phase A Acceptance Matrix

| Acceptance | Owning task | Evidence required |
| --- | --- | --- |
| Player can spawn | Task 5 | runtime checklist |
| Player can attack | Tasks 3, 7, 8 | unit tests + runtime |
| Attack damages valid enemy | Tasks 3, 7 | unit tests + runtime |
| Invalid attack requests cannot grant damage | Tasks 3, 7 | security tests |
| Dash moves player through valid direction | Tasks 3, 7, 8 | unit tests + runtime |
| Wave spawns correctly | Tasks 6, 9 | wave tests + runtime |
| Enemies target and attack players | Task 6 | runtime |
| Elite is strongest configured enemy | Tasks 2, 6 | definition/wave tests |
| Elite receives red presentation | Task 6 | runtime screenshot/observation |
| Enemy death grants correct server reward | Tasks 4, 7 | economy tests + runtime |
| Clearing a wave advances state | Tasks 6, 9 | wave/integration tests + runtime |
| HUD shows authoritative state | Tasks 4, 8, 9 | snapshot tests + runtime |
| Respawn preserves loop | Tasks 4, 5, 9 | player-state/integration tests + runtime |
| No duplicate HUD/controller | Tasks 1, 8, 9 | static validation |
| No indefinite loading deadlock | Tasks 1, 8, 9 | static validation + runtime observation |
| No client-authoritative progression | Tasks 3, 4, 7, 9 | security review + runtime |
| No unverified third-party gameplay scripts | Tasks 1, 6, 9 | source-tree validation |

## Spec Coverage and Self-Review

- **Decision/Product goal:** Tasks 1 and 9 preserve `main`, keep the rebuild on the foundation branch, and target the exact continuous first-time-player loop.
- **Phase A/deferred scope:** Global Constraints plus Tasks 1–9 explicitly implement only the Phase A requirements and leave Phase B production systems out.
- **Architecture/data flow:** Tasks 2, 4, 6, 7, and 8 establish Shared/Remotes/Server/Client boundaries and the Join/Combat/Wave flows.
- **Enemy/world/HUD:** Tasks 5, 6, and 8 cover the compact arena, four enemy tiers, Elite presentation, AI state loop, and mobile HUD.
- **Security:** Tasks 3, 4, and 7 implement and test server validation before state changes.
- **Assets/visual research:** No third-party core gameplay asset is required; procedural arena/NPC/UI/VFX satisfy the approved sourcing hierarchy while keeping visual references out of runtime.
- **Performance:** Global budgets constrain NPC count, AI frequency, pathfinding frequency, FX concurrency, and remote traffic before content expansion.
- **Testing/Git/compatibility:** Every task ends with a test/build/validation gate and commit; naming is isolated to `GameIdentity`; final merge remains blocked until runtime evidence is available.
- **Step scan:** Each task uses one-action steps with exact paths, interfaces, tests, and commands; no step is intentionally left as a placeholder.
- **Type consistency:** Shared contracts are defined in Task 2 and reused in Tasks 3–9.
- **Review Focus coverage:** All five uncovered failure modes are pinned to named tests and owning tasks.
- **Proportion:** The plan fixes interfaces, values, file boundaries, test contracts, and gates without transcribing production function bodies.

## Execution Gate

After this plan is approved, execute it **natively in this session** with the executing-plans skill, one task at a time, while keeping the existing foundation branch isolated from `main`. The user's chosen workflow is one full implementation pass followed by their review; after that review, any incorrect subsystem can be rebuilt from zero without restoring the legacy implementation.
