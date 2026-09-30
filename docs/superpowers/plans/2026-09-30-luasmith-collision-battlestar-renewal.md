# LuaSmith + Collision Battlestar Renewal Implementation Plan

> For agentic workers: use superpowers:executing-plans to implement this plan task-by-task.

Goal: Renovate LuaSmith and Collision Battlestar into a repository-aware, tested, persistent, socially playable PvE experience with an owner-only Test Lab and protected update pipeline.
Architecture: Keep Collision Battlestar server-authoritative and Rojo-based. Add pure shared rules first, then persistence/shop/social/skin systems, then Test Lab and analytics, and finally upgrade LuaSmith and CI/release automation.
Tech Stack: Luau, Roblox APIs, Rojo, GitHub Actions, Node.js, Python, JavaScript, Roblox Open Cloud where credentials/configuration permit.
Spec: docs/superpowers/specs/2026-09-30-luasmith-engineering-agent-design.md

Global Constraints:
- Collision Battlestar remains an action-first PvE wave arena.
- Server owns combat, progression, economy, persistence, companion behavior and Test Lab authorization.
- One active Friend Echo per player.
- Elite keeps a strong red visual identity.
- Cosmetics never modify combat stats.
- No paid random-item/gacha system.
- Production publication is separate from development/test behavior.
- No autonomous delete operation.
- No secrets in repository files.
- Mobile-safe HUD remains mandatory.
- Existing M1/Dash/wave interfaces are preserved unless integration requires change.
- Active-wave budget remains 20 enemies plus at most one Echo per player.
- Every gameplay mutation gets a regression test.

Tasks:
1. Shared rules: add FriendRules, CompanionDefinitions, EnemySkinDefinitions/Rules, ShopDefinitions/Rules, InventoryRules, ProgressionRules and AnalyticsRules plus RED/GREEN tests.
2. Persistence: add DataStore-backed migration-safe PlayerProfile with bounded retries and in-memory fallback plus RED/GREEN tests.
3. Enemy identity: add procedural themed skins, Elite red identity, visual-part budget and wave theme selection plus tests.
4. Friend Echo: add friend cache/resolver, avatar fallback, factory, bounded AI, real-player substitution and invite wrapper plus tests.
5. Shop/inventory: add server-authoritative catalog, purchase, ownership and equipment with atomic logical balance handling plus tests.
6. HUD/onboarding: add Quick Shop, Full Shop, Echo panel, first-session guidance and mobile-safe integration plus tests.
7. Test Lab: add owner-only server authorization, deterministic commands/scenarios and runtime diagnostics plus tests.
8. Analytics/live tuning: add server-side stable event vocabulary, three custom fields, feature flags and configuration boundaries plus tests.
9. LuaSmith 4: repair module-system startup, add provider router, provenance reference engine, repository index, structured operation validator and audit log plus Node tests.
10. CI/CD: add branch-aware release protection, optional Roblox Luau Execution test-place hooks, artifacts and release audit.
11. Final gate: full tests, source validation, map tests, Node tests, Rojo build, review, merge to main and verify production publication.

Verification:
- luau tools/tests/run.luau
- python3 tools/tests/test_map_layout.py
- python3 tools/validate_project.py
- git diff --check
- rojo build default.project.json --output build/CollisionBattlestar.rbxl
- npm test

Release policy: production deployment occurs only from validated main and the configured production universe/place. No native client playtest is claimed unless an actual Studio/device runner is available.