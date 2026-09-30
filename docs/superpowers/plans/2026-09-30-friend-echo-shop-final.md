# Friend Echo + Shop Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the Friend Echo social-companion foundation, direct-purchase shop/inventory foundation, and their mobile-first HUD integration on top of the verified Collision Battlestar PvE core.

**Architecture:** The server owns friend eligibility, Echo loadouts, AI, targets, combat effects, catalog prices, ownership and purchases. The client owns presentation, input and UI state. Pure rules live in Shared modules; Roblox-dependent services remain thin and focused.

**Tech Stack:** Luau, Roblox Players/SocialService/MarketplaceService APIs where applicable, RemoteEvents, Humanoid/PathfindingService, Rojo, Luau unit tests, Python source/layout validation, GitHub Actions.

**Spec:** docs/superpowers/specs/2026-09-30-friend-echo-shop-final-design.md

## Global Constraints

- Collision Battlestar remains an action-first PvE wave arena.
- Friend Echo is assistance, not autoplay.
- One active Friend Echo per player in this phase.
- Four initial classes: Vanguard, Striker, Guardian, Support.
- Identity, class, cosmetics and power are separate concepts.
- A real friend joining the server disables the corresponding owner's Echo.
- Server authority decides eligibility, target, damage, price, ownership, rewards and progression.
- No paid random items/gacha in this phase.
- Shop is separated into Catalog, Inventory and Equipment.
- Quick Shop is contextual; Full Shop is an overlay.
- Pure rules must be testable without Roblox runtime objects.
- Do not reintroduce legacy runtime loaders/watchdogs or duplicate HUD systems.
- Keep the existing server-authoritative M1/Dash/wave core intact unless a task explicitly requires an interface change.
- Performance target: at most 20 active wave enemies plus 1 active Echo per player, bounded AI/pathfinding/FX and no high-frequency continuous gameplay remotes.

## Review Focus

- Invalid or spoofed FriendUserId must never create an Echo or reveal private friend state. Test: rejects a non-friend and self-selection.
- Friend avatar resolution failure must not break the wave. Test: fallback profile is selected and Echo remains spawnable.
- An Echo must not attack through walls, exceed combat range/cooldown, damage allies or grant itself rewards. Test: class actor requests pass through shared combat validation.
- Client-supplied commerce price or reward must never be trusted. Test: server resolves ItemId and authoritative price and rejects modified payloads.
- UI must remain usable on small mobile screens and must not duplicate after respawn. Test: HUD contract plus single-root creation and safe-area layout rules.

---

### Task 1: Shared Friend, Echo and Shop Rules

**Files:**
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/FriendRules.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/CompanionDefinitions.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/ShopDefinitions.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/ShopRules.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/InventoryRules.lua
- Modify: tools/tests/run.luau
- Create: tools/tests/FriendRulesSpec.luau
- Create: tools/tests/CompanionRulesSpec.luau
- Create: tools/tests/ShopRulesSpec.luau

**Interfaces:**
- Produces FriendRules.isEligible(requestingUserId, friendUserId, friendIds) -> boolean.
- Produces FriendRules.classIsValid(classId) -> boolean.
- Produces CompanionDefinitions for Vanguard, Striker, Guardian and Support.
- Produces ShopRules.canPurchase(credits, price, owned) -> boolean.
- Produces ShopRules.price(itemId, catalog) -> number|nil.
- Produces InventoryRules.canEquip(itemId, owned) -> boolean.

- [ ] **Step 1: Write the failing tests**
Test self-selection rejection, non-friend rejection, valid friend acceptance, invalid class rejection, server price lookup, insufficient credits, duplicate ownership rejection and equip validity.

- [ ] **Step 2: Run tests to verify RED**
Run: `luau tools/tests/run.luau`
Expected: the new specs fail because the new rule modules are not present.

- [ ] **Step 3: Implement the shared rule modules**
Keep them pure and Roblox-independent. Catalog entries contain stable ItemId, Category, PriceType, CreditsPrice and requirements.

- [ ] **Step 4: Run tests to verify GREEN**
Run: `luau tools/tests/run.luau`
Expected: all existing and new tests pass.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add friend echo and shop rules"`

### Task 2: Friend Resolver and Safe Avatar Profiles

**Files:**
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Friends/Service.lua
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Companions/AvatarResolver.lua
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Companions/VisualProfile.lua
- Create: tools/tests/FriendResolutionSpec.luau
- Modify: tools/validate_project.py

**Interfaces:**
- FriendService:IsFriend(player, friendUserId) -> boolean.
- FriendService:ResolveFriends(player) -> {FriendProfile}.
- AvatarResolver:Resolve(friendUserId, classId) -> AvatarResult.
- VisualProfile.fallback(classId, variantSeed) -> Profile.

- [ ] **Step 1: Write failing tests**
Cover valid/invalid friend IDs, self rejection, deterministic fallback profile shape and the guarantee that avatar failure still returns a spawnable fallback.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: the new resolution tests fail because the modules do not exist.

- [ ] **Step 3: Implement**
Use Roblox friend/Avatar APIs only inside the service/resolver boundary. Never use avatar appearance to choose combat stats. Sanitize API failures into a game-owned fallback visual profile.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: full Luau suite passes.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add safe friend resolution and avatar fallback"`

### Task 3: Echo Factory, AI and Real-Player Substitution

**Files:**
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Companions/Factory.lua
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Companions/Brain.lua
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Companions/Service.lua
- Create: tools/tests/CompanionBrainSpec.luau

**Interfaces:**
- Factory.Create(loadout, avatarResult, spawnCFrame) -> Model.
- Brain.new(actorContext) -> BrainState.
- Brain.step(state, snapshot, now) -> nextState, command.
- CompanionService:Summon(player, friendUserId, classId) -> result.
- CompanionService:Despawn(player, reason).

- [ ] **Step 1: Write failing tests**
Cover class target priorities, valid state transitions, owner-safe positioning, one active Echo, and disabling an Echo when its represented friend is present.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: new companion tests fail on missing modules/behavior.

- [ ] **Step 3: Implement**
Use bounded AI updates. The brain must support Follow, Acquire, Position, Attack, Protect, Support, Retreat, Recover, Stunned and Disabled. Pathfinding must recover from blocked paths rather than repeat a dead route.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: companion tests and existing suite pass.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add friend echo ai and spawning"`

### Task 4: Shared Combat Integration and Social Invite

**Files:**
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Combat/Service.lua
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Friends/SocialService.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/NetworkRules.lua
- Create: tools/tests/CompanionCombatSpec.luau

**Interfaces:**
- CompanionCombat actor requests use the existing server combat validation path.
- SocialService:CanInvite(player) -> boolean.
- SocialService:PromptInvite(player).

- [ ] **Step 1: Write failing tests**
Test that an Echo cannot hit invalid targets, cannot damage allies, cannot bypass cooldown/range/LOS rules and cannot generate an independent reward identity.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: companion-combat tests fail before integration.

- [ ] **Step 3: Implement**
Refactor only enough of CombatService to accept a server-owned actor context without giving the Echo a privileged path. Add SocialService capability checks and invite dispatch on the client-facing edge.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: complete suite passes.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: integrate friend echoes with combat and invites"`

### Task 5: Inventory, Catalog and Credits Shop Service

**Files:**
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Shop/Service.lua
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Shop/InventoryService.lua
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Economy/Service.lua
- Create: tools/tests/InventoryServiceSpec.luau

**Interfaces:**
- InventoryService:Owns(player, itemId) -> boolean.
- InventoryService:Grant(player, itemId) -> boolean.
- InventoryService:Equip(player, itemId) -> boolean.
- InventoryService:Unequip(player, itemId) -> boolean.
- ShopService:PurchaseCreditsItem(player, itemId) -> PurchaseResult.

- [ ] **Step 1: Write failing tests**
Test known-price purchase, insufficient Credits, duplicate ownership, unknown ItemId, malformed ItemId and client price tampering.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: new inventory/shop tests fail before implementation.

- [ ] **Step 3: Implement**
Use ItemId as the only client-supplied commerce identifier. Resolve all prices, requirements and rewards server-side. Inventory remains plain serializable data.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: all tests pass.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add server-authoritative shop inventory"`

### Task 6: Quick Shop and Full Shop HUD

**Files:**
- Create: src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/HUD/Shop.lua
- Create: src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/HUD/CompanionPanel.lua
- Create: src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/HUD/Notifications.lua
- Modify: src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/HUD/Root.lua
- Modify: src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/ClientBootstrap.client.lua
- Modify: src/CollisionBattlestar/ReplicatedStorage/Shared/HUDContract.lua
- Create: tools/tests/HUDSocialShopSpec.luau

**Interfaces:**
- ShopUI.Create(parent, contract) -> controller.
- CompanionPanel.Create(parent, contract) -> controller.
- Notifications.Push(kind, payload).

- [ ] **Step 1: Write failing tests**
Cover the required HUD elements, unique root ownership, shop categories, owned/equipped visual states, purchase feedback and contextual Echo information.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: new HUD contract assertions fail for missing social/shop elements.

- [ ] **Step 3: Implement**
Use CoreUISafeInsets, responsive layouts, ScrollingFrame/UIGridLayout for catalog content, and one client bootstrap. Do not place game logic inside UI modules.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: all unit tests pass.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add mobile friend and shop hud"`

### Task 7: Commerce Networking and Remote Validation

**Files:**
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Bootstrap.server.lua
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Security/Service.lua
- Create: tools/tests/CommerceSecuritySpec.luau

**Interfaces:**
- Commerce RemoteEvent accepts only a whitelisted action shape.
- Security service exposes bounded request/rate validation for commerce and friend actions.

- [ ] **Step 1: Write failing tests**
Cover unknown action, wrong payload type, missing ItemId, oversized ItemId, repeated purchase spam, non-friend UserId and invalid class.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: commerce security tests fail before hardened validation exists.

- [ ] **Step 3: Implement**
Add Commerce remote creation, strict payload validation and rate limiting while preserving the existing Action/State/FX responsibilities.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: complete suite passes.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: harden friend and commerce remotes"`

### Task 8: Persistence-Ready State Contract

**Files:**
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/ProfileSchema.lua
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Core/PlayerState.lua
- Create: tools/tests/ProfileSchemaSpec.luau

**Interfaces:**
- ProfileSchema.default() -> serializable profile.
- ProfileSchema.sanitize(profile) -> sanitized profile.

- [ ] **Step 1: Write failing tests**
Cover default profile shape, unknown field removal and stable serialization of Credits, inventory, equipment, Echo loadout and upgrades.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: schema tests fail before the profile contract exists.

- [ ] **Step 3: Implement**
Keep DataStore calls out of this phase. PlayerState consumes the schema and remains in-memory while exposing persistence-ready plain data.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: complete suite passes.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add persistence-ready player profile schema"`

### Task 9: Runtime Validation, Documentation and Final Review

**Files:**
- Modify: tools/validate_project.py
- Modify: README.md
- Modify: docs/FRIEND_ECHO_SHOP_RESEARCH_2026-09-30.md

**Interfaces:**
- Validation must require all social/shop runtime modules and exactly the intended bootstrap path.

- [ ] **Step 1: Write failing validation gates**
Require Friends/Companions/Shop files, Commerce remote, the new HUD modules and profile schema.

- [ ] **Step 2: Run RED**
Run: `python3 tools/validate_project.py`
Expected: validation fails until the new files/contracts exist.

- [ ] **Step 3: Implement validation/documentation**
Add explicit checks for missing new runtime paths and document the final player loop and development commands.

- [ ] **Step 4: Run the full gate**
Run: `luau tools/tests/run.luau && python3 tools/tests/test_map_layout.py && python3 tools/validate_project.py && rojo build default.project.json --output build/CollisionBattlestar.rbxl`
Expected: all commands exit 0 and the Rojo build file exists and is non-empty.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "chore: validate final friend echo shop rebuild"`

## Branch Completion Gate

Before merge or publish:

1. Read the full diff against main.
2. Run the entire validation command again from a clean working tree.
3. Perform a separate whole-branch code review.
4. Any Critical/Important finding requires a failing regression test, fix, full-suite green run and commit.
5. Minor findings are recorded explicitly rather than silently changing scope.
6. Do not publish to Roblox until the human explicitly authorizes the external side effect.
7. A successful Rojo build/CI run is not a substitute for an observed Roblox client playtest.
