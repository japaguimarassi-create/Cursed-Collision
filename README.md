# Collision Battlestar

Where Worlds Collide

Collision Battlestar is an action-first PvE wave arena built around readable combat, a red Elite target, persistent progression, social Friend Echo companions, recurring content, and owner-controlled QA.

The repository name remains Cursed-Collision for history compatibility.

## Player loop

Join -> Spawn -> Fight -> Defeat enemies -> Earn Credits -> Defeat the red Elite -> Clear the wave -> Upgrade -> Survive a harder wave -> Repeat.

Each wave uses a visual theme and exactly one red Elite. Enemy cosmetics do not change combat statistics.

## Systems

- Server-authoritative M1, Dash, waves, damage, rewards and economy.
- Persistent player progression with migration-safe profiles.
- Enemy themes and deterministic visual variants.
- Friend Echo companions with Vanguard, Striker, Guardian and Support classes.
- Server-validated friend eligibility and real-player substitution.
- Credits Shop with authoritative price and ownership checks.
- Mobile-first HUD with Shop, Echo, onboarding and Test Lab entry.
- Owner-only personal Test Lab at runtime.
- Analytics hooks for session, wave, combat, economy, upgrade, shop, companion and social events.
- Six runtime RemoteEvents: Combat, State, FX, Commerce, Companion, TestLab.
- Procedural arena geometry with no third-party gameplay scripts.

## Controls

Mobile: on-screen M1 and Dash buttons.

Keyboard: Left Click = M1, Q = Dash.

Controller: R2 = M1, B = Dash.

## Test Lab

The Test Lab is available only to the experience owner in supported user-owned experiences.

It provides controlled runtime actions such as:

- Full heal
- +1000 Credits
- Spawn Elite
- Clear Arena
- Next Wave
- Return to Arena

The Test Lab does not grant production authority to clients and is never used as a publication mechanism.

## LuaSmith 4

LuaSmith 4 is the repository-aware engineering agent.

Capabilities:

- repository index and dependency context
- provenance-aware Roblox references
- provider routing for Ollama, OpenAI, Gemini, Hugging Face and offline mode
- fail-closed file operation policy
- no autonomous delete operation
- validation and Rojo build hooks
- audit log and local backups
- scheduled reference maintenance

Commands:

`npm test`
`npm run validate`
`node luasmith-v4.js --web 3000`
`node luasmith-v4.js --sync-refs 24`
`node luasmith-v4.js --repair "describe the concrete defect"`

## Development verification

`python3 tools/validate_project.py`

`luau tools/tests/run.luau`

`python3 tools/tests/test_map_layout.py`

`rojo build default.project.json --output build/CollisionBattlestar.rbxl`

`npm test`

Production publication is isolated to the main branch by the release workflow. Scheduled LuaSmith maintenance produces a PR and never publishes the production Roblox place.

## Documentation

- `docs/superpowers/specs/2026-09-30-luasmith-engineering-agent-design.md`
- `docs/superpowers/plans/2026-09-30-luasmith-collision-battlestar-renewal.md`
- `tools/luasmith/references.json`
