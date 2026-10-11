# STEAL AN ANIMAL — Core Shell, Core Kernel, Animal Brain & MapProbe Design

**Date:** 2026-10-11  
**Repository:** `japaguimarassi-create/Cursed-Collision`  
**Baseline:** `217ea1a238d049936e2e0a5604c1573580d5759c`  
**Target place:** `15338267657` / universe `5290480963`

## Goal

Make the published game resilient when any gameplay service fails to initialize, guarantee that a useful loading/status interface can appear independently of the full HUD, and provide a diagnostic agent that returns verifiable map/client readiness information. Keep the original STEAL AN ANIMAL loop and existing player data compatible.

## Research scope and evidence

The broad search pass returned 623 result entries across grouped queries; 45 distinct pages were successfully fetched and read in a focused research run across eight domains. These are not 623 fully read pages. High-confidence primary references are listed below.

Gameplay/map/UI references:
- Official experience: https://www.roblox.com/games/107778070777162/Steal-An-Egg
- Biome progression and visual guides: https://www.ign.com/wikis/steal-an-egg-roblox/All_Biomes
- Gameplay loop and map: https://www.mmoexp.com/News/roblox-steal-an-egg-guide-best-eggs-pets-speed-biomes-and-beginner-tips.html
- Pet index/map reference: https://www.eldorado.gg/blog/steal-an-egg/steal-an-egg-all-pets-index/
- Screenshot/creature hierarchy: https://timesaver.gg/blog/steal-an-egg-best-pets
- Roblox UI Kit reference: https://zxgly.itch.io/free-cartoony-roblox-ui-pack
- Roblox Creator Store: https://create.roblox.com/docs/production/creator-store

Official Roblox implementation references:
- Player lifecycle: https://create.roblox.com/docs/reference/engine/classes/Player
- Players service (Not Creatable): https://create.roblox.com/docs/reference/engine/classes/Players
- Studio test modes and simulated clients: https://create.roblox.com/docs/studio/testing-modes
- StudioTestService: https://create.roblox.com/docs/reference/engine/classes/StudioTestService
- ScreenGui: https://create.roblox.com/docs/reference/engine/classes/ScreenGui
- Loading screens/ReplicatedFirst: https://create.roblox.com/docs/players/loading-screens
- Client/server model: https://create.roblox.com/docs/projects/client-server
- Remote events: https://create.roblox.com/docs/scripting/events/remote
- Server/client security: https://create.roblox.com/docs/scripting/security/client-server-boundary
- Modules: https://create.roblox.com/docs/scripting/module
- Instance streaming: https://create.roblox.com/docs/workspace/streaming
- Streaming-safe code: https://create.roblox.com/docs/workspace/streaming/techniques
- Pathfinding: https://create.roblox.com/docs/characters/pathfinding
- Performance: https://create.roblox.com/docs/performance-optimization/identify
- Mobile hardware testing: https://create.roblox.com/docs/performance-optimization/test-on-hardware
- On-screen UI and safe areas: https://create.roblox.com/docs/ui/on-screen-containers
- Mobile input: https://create.roblox.com/docs/input/mobile

## Diagnosis from the current source

The current source has a startup-order weakness:
1. `Main.server.lua` requires all service modules before creating `ReplicatedStorage.RoubeAnimalRemotes` and before calling `WorldBuilder.Build()`.
2. `GameClient.client.lua` waits for the entire remote set and requires shared modules before creating `StealAnAnimalHUD`.
3. `WorldBuilder.Build()` deletes any existing `workspace.StealAnAnimal` before the replacement map has been built and validated.

Therefore, a module-load error or an unresolved dependency before the server creates remotes can leave both map and main HUD absent. The exact runtime exception that triggered the reported live failure is not yet observed; the release pipeline previously checked syntax, static wiring, rules, and build/publish, but did not run an interactive Studio/device playtest. The implementation must add diagnostics to confirm or disprove this hypothesis instead of presenting it as a known live exception.

The uploaded `Steal an egg.zip` contains only 16 ZIP entries and 4,042 bytes of uncompressed data. Its internal manifest identifies `CursedCollision`; its client is a small stub and it lacks the complete service set. It is not the full source project for the official Steal An Egg.

## Architecture

### 1. Core Shell — independent safety boundary

A small, self-contained server Script that does not require the other game modules at boot.
- Creates the remote folder and the complete required RemoteEvent/RemoteFunction names idempotently.
- Creates a visibly safe fallback ground and spawn only when the active game root is missing.
- Records build tag, boot timestamp, core state, service health, last error, map counts and most recent client probe reports.
- Runs a throttled watchdog that repairs only essential missing bootstrap objects; it must never duplicate or overwrite a healthy world.
- Keeps bounded diagnostic history; no unbounded logs, loops, or data-store writes.
- Does not grant coins, award gamepasses, or alter profile data.

### 2. Core Kernel — controlled organ loader

A ModuleScript owned by the main server entry point:
- Loads each gameplay service in an isolated `pcall` and records `Loaded / Started / Degraded / Failed`.
- Ensures bootstrap remotes and fallback exist before requiring service modules.
- Builds the complete world transactionally: keep the safe fallback until the staged world passes readiness checks, then swap roots and set `MapReady=true`.
- Starts dependent services only after the world is ready; if the world is not ready, preserve fallback, skip unsafe gameplay startup, and expose a clear diagnostic.
- Registers player lifecycle exactly once; all state-changing gameplay remains server-authoritative.
- Includes a controlled recovery policy (bounded retry for transient initialization only; no infinite restart loops or duplicate event connections).

### 3. Animal Brain — bounded AI decisions

A ModuleScript for NPC decision-making, isolated from economy/profile services:
- Shared finite states: `Idle`, `Wander`, `Patrol`, `Chase`, `Flee`, `Return`, `Disabled`.
- Guardian policy: patrol within assigned biome, acquire eligible real players carrying an animal, chase using PathfindingService, re-path on movement/blockage or a limited cadence, catch only after server-side distance/state validation, and return to patrol after timeout.
- Wild-animal policy: lightweight idle/wander/flee decisions within a home radius. Do not let wild AI alter inventory or currencies.
- Add per-NPC think/repath limits and distance-based throttling; avoid parallel Luau until profiling demonstrates a need.
- Preserve the existing six giant guardians and animal catalogue.

### 4. Virtual Player / MapProbe — diagnostics agent

The user-facing term “virtual player” describes an audit agent, not a fake Roblox Player instance.
- Checks root/map readiness, spawn, 8 farms, 6 biome floors, 23 species, 6 guardians, remotes, error attributes, module states and server boot elapsed time.
- Returns structured status through a restricted diagnostic RemoteFunction and writes bounded server Output entries.
- A separate lightweight client probe creates a minimal status/loading ScreenGui before waiting for gameplay modules, inspects client-visible root/remotes/HUD, and reports facts through a rate-limited RemoteEvent.
- It reports only observations it can actually make; a server audit cannot claim it verified a client's rendered pixels.
- Do not create `Instance.new("Player")` or spoof a network identity. Official simulated clients must use Studio Test / Server & Clients / StudioTestService, which do not run as a production fake-player service.

## HUD and visual direction

Create an unmistakable early status screen with version/build tag and one of:
- `CORE BOOTING`
- `WORLD BUILDING`
- `WORLD READY — farms/biomes/animals counts`
- `WORLD DEGRADED — safe fallback active`
- `CLIENT REPORTING — HUD READY`

Keep this diagnostic unobtrusive after success. Rework the main mobile HUD after bootstrap reliability is fixed: top status for coins/income/carry state; primary touch-safe actions; secondary screens for Barn, Animals/Index, Shop, Quests, Daily, Stats, Settings and Rebirth; consistent safe-area sizing and responsive layout. Use the user-provided Zxgly pack as visual inspiration only. Recreate original styles in Luau; do not claim binary assets from the pack were imported.

For original world visual design, preserve the linear risk/reward path because that matches the high-level genre loop; improve zone readability with large original landmarks, safe green travel lanes, unmistakable gates, biome-specific terrain colors/vegetation, well-spaced farms and a clear return-to-barn route. Do not copy proprietary screenshots, exact geometry, icons, pet names or artwork from Steal An Egg.

## Data and compatibility constraints

- Keep DataStore name `RoubeUmAnimal_Profile_v1`, current schema version and atomic profile logic unchanged unless a separate migration is explicitly needed.
- Core modules must not initialize DataStores independently; ProfileService remains the owner.
- Keep existing RemoteEvent names compatible; new diagnostics endpoints must be separate and rate limited.
- No fabricated gamepass/product IDs, no unapproved purchases or economy changes.
- Publish only to the previously confirmed universe/place pair, and only after tests/build pass.

## Acceptance tests

1. A simulated missing/failed service cannot prevent bootstrap remotes and fallback map from appearing.
2. Client probe creates a visible minimal status GUI before waiting for remotes or gameplay modules.
3. Full map is swapped into place only after all readiness checks pass; failed staging leaves fallback and records the failed step.
4. Health report truthfully counts roots/farms/biomes/species/guardians/remotes and identifies missing components.
5. Client probe report confirms whether the root/remotes/HUD are visible to that connected client; server must not fabricate the client status.
6. All current gameplay tests, Luau parse checks, map coverage, monetization tests, and Rojo build pass.
7. Studio Test plus Server & Clients is used for live behavior when a Studio session is available; device testing is needed for visual verification. The final report must clearly separate automated evidence from unperformed real-device/Studio checks.
8. Publish workflow logs must report the returned Roblox published version number before a release is called published.

## Risks and boundaries

- A real Roblox Player is an engine-managed connected client. A production script cannot make a supported fake Player that consumes a real client session.
- The map not appearing has a confirmed risky initialization order but no captured production stack trace yet; diagnostics will identify the actual failing boundary.
- A passed Rojo build or API publish response confirms artifact/build submission, not that the public game visually rendered correctly.
- Game title/description metadata is managed separately from uploading a place file.
