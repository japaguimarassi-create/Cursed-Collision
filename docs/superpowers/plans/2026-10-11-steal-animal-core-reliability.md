# STEAL AN ANIMAL Core Reliability Implementation Plan

> **For agentic workers:** Execute task by task, test each change, and review the final diff before a release. Keep the implementation on the current main branch unless an isolated branch/worktree is available.

**Goal:** Ensure the public game always exposes an early diagnostic HUD and safe fallback world, loads gameplay services independently, reports actual map/client readiness, and runs animal AI through a bounded, observable module.

**Architecture:** A dependency-free Core Shell establishes replicated boot state, essential remotes, and safe ground/spawn before gameplay imports. A Core Kernel initializes the world and each service with isolated error handling; a MapProbe records truthful server/client readiness; an independent client Bootstrap HUD is created before waiting for gameplay modules. AnimalBrain owns wildlife and guardian decisions while existing profile/economy services remain authoritative.

**Tech Stack:** Roblox Luau, Rojo project mapping, Roblox Creator APIs, Python static regression tests, Luau rule tests and syntax parsing, GitHub Actions publication workflow.

**Spec:** `docs/superpowers/specs/2026-10-11-steal-animal-core-shell-mapprobe-design.md`

## Global Constraints

- Keep the confirmed target unchanged: Universe `5290480963`, Place `15338267657`.
- Preserve DataStore `RoubeUmAnimal_Profile_v1`, profile schema and atomic profile writes.
- Preserve the eight farms, six current biomes, 23 animal IDs, six giant guardians and the no-Strength progression.
- Never create or impersonate a production `Player`; use StudioTestService and Server & Clients for simulated-client tests.
- Never trust static tests or a successful publish API response as proof of live visual rendering.
- Keep the Core Shell independent of gameplay ModuleScripts and DataStores.
- Rate-limit diagnostic remotes and do not expose stack traces, API keys, private profile contents or exploit-sensitive internals to clients.
- Do not overwrite monetization IDs or enable placeholder purchases.
- Do not copy proprietary Steal An Egg map geometry, icons, screenshots or animal artwork.

## File Map

- Create `src/RoubeUmAnimal/ServerScriptService/CoreShell.server.lua`: no gameplay imports; idempotent essential remotes, core state, fallback ground/spawn, client-report receiver and bounded health-report endpoint.
- Create `src/RoubeUmAnimal/ServerScriptService/Services/CoreKernel.lua`: guarded module loader, world build sequence, service registry, recovery policy and existing player lifecycle orchestration.
- Modify `src/RoubeUmAnimal/ServerScriptService/Main.server.lua`: small entry point that calls the kernel safely; must no longer require all gameplay services at file scope.
- Modify `src/RoubeUmAnimal/ServerScriptService/Services/WorldBuilder.lua`: build under a staging root; publish/swap the root only after readiness checks; expose build diagnostics and keep fallback alive until swap.
- Create `src/RoubeUmAnimal/ServerScriptService/Services/MapProbe.lua`: server-side count/readiness probe for root, spawn, farms, biome floors, animal models, guardians, remotes, service states and client reports.
- Create `src/RoubeUmAnimal/ServerScriptService/Services/AnimalBrain.lua`: state machine for wildlife wander/flee and giant-guardian patrol/chase/return behavior.
- Modify `src/RoubeUmAnimal/ServerScriptService/Services/GuardianService.lua`: compatibility adapter forwarding guardian startup to AnimalBrain, avoiding duplicate AI loops.
- Create `src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/BootHUD.client.lua`: minimal diagnostic ScreenGui created before any remote wait or gameplay require.
- Modify `src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua`: wait with timeouts where safe, report completion at the true end of initialization, and do not replace the boot diagnostic on partial failure.
- Create `tools/tests/test_core_reliability.py`: regressions for boot ordering, fallback, staging, HUD marker, diagnostic rate limits and AI ownership.
- Modify `tools/validate_roube_animal.py` and `.github/workflows/validate.yml` only to enforce concrete reliability invariants and run the new test suite.

The existing `default.project.json` maps the complete ServerScriptService and StarterPlayerScripts source folders; confirm the new files are included by Rojo without introducing a competing project mapping.

## Review Focus

- Bootstrap starts even when a gameplay ModuleScript cannot be required.
- HUD still appears if the main client UI errors or a gameplay RemoteEvent is missing.
- Partial map-build errors leave a visible safe floor/spawn and a report naming the failed step.
- Staging maps never become active until all required counts and spawn checks pass.
- Re-running boot code does not duplicate remotes, event connections, NPC AI loops or fallback geometry.
- The client probe reports only client-observed facts and cannot mark the server world ready.
- Wild-animal movement leaves each animal inside its home biome and does not break capture prompts/respawn.
- Guardian AI must preserve server-owned catch checks, have a path failure fallback, and avoid unbounded repath loops.
- Diagnostic requests from any client are rate-limited and cannot change economy, profiles or world state.
- Mobile HUD status remains within safe areas and readable at narrow viewports.

---

### Task 1: Add the independent Core Shell and boot HUD

**Files:**
- Create: `src/RoubeUmAnimal/ServerScriptService/CoreShell.server.lua`
- Create: `src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/BootHUD.client.lua`
- Test: `tools/tests/test_core_reliability.py`

**Interfaces:**
- Core Shell exposes a `ReplicatedStorage.StealAnimalCore` folder with attributes `BootState`, `WorldState`, `BuildTag`, `BootStartedAt`, `ServiceStatusJson`, and `LastFailure`.
- Core Shell creates `StealAnimalCore.ClientProbeReport` (RemoteEvent) and `StealAnimalCore.RequestHealthReport` (RemoteFunction) idempotently.
- Core Shell ensures `ReplicatedStorage.RoubeAnimalRemotes` and all existing remote names are present before the main script can stall on WaitForChild.
- BootHUD creates `StealAnimalBootstrapHUD` before waiting for ReplicatedStorage objects; it displays a minimal loading/degraded/ready state and reports client-observed state through ClientProbeReport.

- [ ] Write assertions that the Core Shell has no gameplay `require`, creates remotes before any dependency on other modules, creates a safe fallback, and rate-limits ClientProbeReport.
- [ ] Run `python3 tools/tests/test_core_reliability.py`; the new assertions must fail before implementation.
- [ ] Implement idempotent remote/folder construction and one safe fallback plane/spawn, tagged by attributes for later cleanup. Bound report sizes and requests per player.
- [ ] Implement the boot HUD with no gameplay requires and no indefinite wait before it becomes visible; use timeouts, safe-area positioning, and a visible degraded state.
- [ ] Mark the existing gameplay HUD complete only after its initialization reaches the final success path.
- [ ] Re-run the test; then parse all Luau sources and build with Rojo.

### Task 2: Introduce CoreKernel and remove top-level service dependency failures

**Files:**
- Create: `src/RoubeUmAnimal/ServerScriptService/Services/CoreKernel.lua`
- Modify: `src/RoubeUmAnimal/ServerScriptService/Main.server.lua`
- Test: `tools/tests/test_core_reliability.py`

**Interfaces:**
- `CoreKernel.Start()` returns structured startup status and populates `StealAnimalCore.ServiceStatusJson`.
- `CoreKernel.SafeRequire(name)` returns module or error without terminating the boot path.
- `CoreKernel.SetServiceState(name, state, detail)` accepts only the known states `Loading`, `Ready`, `Degraded`, and `Failed`; client-visible detail is short and sanitized.
- Existing gameplay service entry points keep their current method signatures where possible.

- [ ] Add a regression asserting Main has no file-scope `require(Services:WaitForChild(...))` chain and that boot objects are initialized before service loading.
- [ ] Run the regression to verify it fails against the current Main.
- [ ] Move service loading behind CoreKernel. Load required modules one at a time inside `pcall`; register each state and error without leaking stack traces to clients.
- [ ] Build the world after bootstrap. Start dependent systems only when the world is marked ready; in degraded mode keep the player in the fallback area and keep diagnostics reachable without issuing coins, captures or profile mutation through missing systems.
- [ ] Preserve ProfileService's existing session locks, atomic writes, autosave and player leave cleanup. Register each player lifecycle connection once.
- [ ] Re-run static tests, existing gameplay assertions, Luau parse and Rojo build.

### Task 3: Make map construction staged and observable

**Files:**
- Modify: `src/RoubeUmAnimal/ServerScriptService/Services/WorldBuilder.lua`
- Modify: `src/RoubeUmAnimal/ServerScriptService/CoreShell.server.lua`
- Create/modify: `src/RoubeUmAnimal/ServerScriptService/Services/MapProbe.lua`
- Test: `tools/tests/test_core_reliability.py`, `tools/tests/test_map_layout.py`

**Interfaces:**
- `WorldBuilder.Build()` returns the active root only when required readiness checks pass; otherwise it returns a degraded status/root without deleting the fallback.
- Staging root name: `StealAnAnimal_Staging`; active root name remains `StealAnAnimal`.
- `MapProbe.CollectServerReport()` returns a bounded table containing timestamp, build tag, active/staging root status, spawn presence, farm/biome/animal/guardian counts, core remotes, module health, and latest client-probe results.
- The Shell cleans the fallback only after the active root has `MapReady == true` and all required counts pass.

- [ ] Add tests that require staging creation and require the fallback-cleanup condition to use validated `MapReady`, not just the presence of a folder.
- [ ] Run the tests to confirm current immediate-destroy map construction fails the new guard.
- [ ] Build under a staging root and validate spawn plus exactly 8 farms, 6 biome floors, all 23 catalogue spawns and 6 guardians before swapping to `workspace.StealAnAnimal`.
- [ ] If any step fails, retain fallback ground/spawn, set `WorldState = Degraded`, expose safe counts and the failed step, and do not falsely set MapReady true.
- [ ] Make the probe distinguish active, staging and absent roots. Include a client report only if a connected client actually submitted it; never infer viewport rendering from a server-only count.
- [ ] Test successful build, one missing biome, one missing spawn and a failed staged build; then run existing map layout assertions.

### Task 4: Implement AnimalBrain for wildlife and guardians

**Files:**
- Create: `src/RoubeUmAnimal/ServerScriptService/Services/AnimalBrain.lua`
- Modify: `src/RoubeUmAnimal/ServerScriptService/Services/GuardianService.lua`
- Modify if required: `src/RoubeUmAnimal/ServerScriptService/Services/WorldBuilder.lua`
- Test: `tools/tests/test_core_reliability.py`, `tools/tests/run.luau`

**Interfaces:**
- `AnimalBrain.StartWildlife(builder, config)`
- `AnimalBrain.StartGuardians(builder, animalService, notify)`
- Explicit states are `Idle`, `Wander`, `Flee`, `Patrol`, `Chase`, `Return`, and `Disabled`.
- GuardianService remains the public start adapter to avoid changing Main's old contract unexpectedly.

- [ ] Add static/testable decision logic for bounded state transitions, home-radius enforcement, path retry limits and no economy mutation from the AI.
- [ ] Run the test to confirm state/ownership assertions fail before implementation.
- [ ] Move guardian target selection, line-of-sight, pathfinding, catch/lose and patrol scheduling into AnimalBrain. Retain the existing server-side target and catch distance validation.
- [ ] Add lightweight wildlife idle/wander/flee behavior via bounded Model:PivotTo updates, preserving prompt descendants, spawn CFrames and scheduled respawns. Wild AI must never capture, deposit, award money or change player profiles.
- [ ] Add per-NPC randomized scheduling offsets and limits for repath/think rate. If a path fails, use a bounded fallback MoveTo/return behavior instead of retrying every frame.
- [ ] Keep one active loop per model using a registry keyed by Model and clean it when the model is removed.
- [ ] Re-run the state tests and existing gameplay rule tests; parse Luau and build.

### Task 5: Connect the probe, improve HUD fallbacks, and expose a safe status report

**Files:**
- Modify: `src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/BootHUD.client.lua`
- Modify: `src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua`
- Modify: `src/RoubeUmAnimal/ServerScriptService/Services/MapProbe.lua`
- Test: `tools/tests/test_core_reliability.py`

**Interfaces:**
- Client sends one bounded startup report and optional user-triggered refresh; each report includes only `HudPresent`, `MainHudReady`, `ActiveRootPresent`, `MapReady`, `RemoteFolderPresent`, observed count attributes where replicated, client viewport dimensions and a timestamp.
- Server health endpoint returns sanitized status; no profile data, raw exceptions or secrets.
- Main UI announces completion by setting `CoreBootstrapComplete = true` only on the actual success path.

- [ ] Add tests that a partial client initialization leaves the bootstrap HUD enabled and that the completion flag appears only in the success path.
- [ ] Implement a visible loading stage, a concise ready stage and a diagnostic stage with counts and next-step message. Do not make the user close an error overlay just to see the fallback state.
- [ ] Add safe timeout handling for all newly introduced dependency waits; preserve current buttons/screens and server-owned gameplay semantics.
- [ ] Ensure the boot HUD dismisses itself only when the main HUD completion marker is observed, not merely when the main ScreenGui object exists.
- [ ] Re-run static tests and build. Manually review display order, clipping, touch target sizes and safe areas in narrow viewports.

### Task 6: Extend CI reliability gates

**Files:**
- Modify: `tools/validate_roube_animal.py`
- Modify: `.github/workflows/validate.yml`
- Modify: `tools/tests/test_core_reliability.py`

- [ ] Add validator checks for required files, remote names, boot order, staging/swap guard, fallback survival, bounded diagnostic interfaces and AnimalBrain ownership.
- [ ] Add the core reliability test step to validate.yml.
- [ ] Run all workflow checks: project structure, gameplay rule tests, map coverage, monetization separation, core reliability, Luau syntax parse, Rojo build/artifact creation.
- [ ] Inspect complete logs and require zero failing steps; a previous run is not evidence for the new commit.

### Task 7: Release and post-release verification

**Files:**
- Modify only release metadata/marker if needed: `src/RoubeUmAnimal/ReplicatedStorage/Shared/Config.lua` and the workflow trigger commit message.

- [ ] Review the complete diff against the approved spec and confirm no profile/schema or monetization placeholder changes.
- [ ] Confirm validate.yml passes on the exact release SHA.
- [ ] Publish only to the confirmed Universe/Place IDs using the existing guarded workflow and secret; never print or expose the key.
- [ ] Confirm the publish action's response includes a valid `versionNumber`.
- [ ] Fetch and preserve the CI test log, place version, commit SHA and diagnostic output link in the final report.
- [ ] If no Studio session is available, label in-game UI/AI behavior as not yet visually verified. Do not claim a real Player session was simulated by the production MapProbe; recommend Studio Server & Clients for that final runtime pass.
