# Steal An Animal — Studio QA bots

## What the bots are

This repository uses Roblox's supported **StudioTestService** to run two simulated clients and a server inside Roblox Studio. The client audit scripts use **VirtualInput** to try the HUD's Shop, Index, More, and Rebirth panels as simulated input. They are Studio test clients, not alternate accounts, and they never join a public server.

Official references:
- Studio testing and multi-client simulation: https://create.roblox.com/docs/studio/testing-modes
- StudioTestService API: https://create.roblox.com/docs/reference/engine/classes/StudioTestService
- VirtualInput API: https://create.roblox.com/docs/reference/engine/classes/VirtualInput
- Mobile UI and safe areas: https://create.roblox.com/docs/ui/position-and-size

## Files

- `src/StealAnAnimal/ServerScriptService/StudioAudit.server.lua`: world, farm, prompt, guardian, remote, catalog, gameplay-rule, and player-profile checks; collects client reports and returns a JSON summary.
- `src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/StudioAudit.client.lua`: tests HUD structure, bounds, overlap, touch-area placement, and simulated button presses; reports viewport and touch capability.
- `tools/studio-tests/StealAnAnimalAudit.plugin.lua`: adds the Studio toolbar button that starts two clients and prints the report.
- `tools/tests/test_studio_audit.py`: CI checks that the harness remains gated, isolated, and non-destructive.

Both runtime audit scripts exit unless `RunService:IsStudio()` is true and the Workspace attribute `EnableStealAnimalAudit` is explicitly enabled. In a published server the QA bots do not run.

## Running the bots in Roblox Studio

1. Open a local build of the latest `main` branch, with the two `StudioAudit` scripts included. Use the Rojo project in the repository or the latest build artifact from GitHub Actions.
2. Install `tools/studio-tests/StealAnAnimalAudit.plugin.lua` as a local Studio plugin. On desktop Roblox Studio, put the file in the user's local Plugins folder or create a local plugin from the script, then restart Studio.
3. Before running, select a Phone profile in Studio's Device Simulator. Check each client's `touchEnabled` and `viewport` fields in the report; if `TouchEnabled=false`, the run did not emulate mobile input and the report will mark that part as a warning.
4. Open the place in Studio and select **Steal An Animal QA → Run Studio Audit** from the toolbar.
5. Wait until the plugin finishes. It launches two simulated clients. The report includes server tests and separate client UI results.
6. Open the Studio **Output** panel and copy the complete line beginning with `[STEAL_ANIMAL_AUDIT_REPORT]`. Paste the JSON back into the development conversation so the reported failures can be corrected precisely.

The plugin may report a setup warning if the Studio session does not start both clients, or if local player profiles cannot load. Persistent-profile checks require **Enable Studio Access to API Services** in Studio. The game config routes all Studio profile requests to the distinct `StealAnAnimal_StudioSandbox_v1` DataStore name, not the published `StealAnAnimal_FreshProfile_v1` store. This avoids changing live player saves during Studio testing. Keep the sandbox separate and do not switch the Studio config back to the live store.

## What it checks

- Shared Config, animal catalog, and gameplay rules load successfully.
- Eight sequential biomes have catalog entries; the catalog retains at least 28 species.
- Runtime map builds eight farms and eight guardians, with active wildlife and scenery.
- Every farm has six slots, a treadmill, and deposit/collect prompts with the expected interaction attributes.
- Required gameplay remotes exist.
- Simulated players are assigned distinct farms and expose profile attributes when data services are available.
- HUD resources, objective, menu buttons, rebirth access, viewport bounds, safe-inset setting, overlap, and bottom touch-area clearance.
- Virtual-input opens and closes More, Index, Shop, and Rebirth panels. It does not buy upgrades or execute a rebirth.
- The server gathers results and returns machine-readable JSON.

## Limits

Roblox Studio is not available to execute inside GitHub Actions. CI can lint/parse the Luau scripts, run game-rule and structural checks, build the place, and validate the RBXL file; the Studio plugin is what performs the actual simulated-client runtime checks. This harness does not claim success until a real Studio run returns its report. Device-simulator sweeps, network-latency sweeps, and a real mobile-device playtest remain separate follow-up validations.

The tests do not publish the experience, access public servers, create accounts, invoke purchases, change rebirths, or intentionally mutate a player's coins.
