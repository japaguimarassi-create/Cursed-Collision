# Friend Echo + Enemy Skins + Shop Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the Friend Echo social-companion foundation, coherent randomized enemy skins, direct-purchase shop/inventory foundation, and mobile-first HUD integration on top of the verified Collision Battlestar PvE core.

**Architecture:** The server owns friend eligibility, skin selection, Echo loadouts, AI, targets, combat effects, catalog prices, ownership and purchases. The client owns presentation, UI state, input and Roblox invite prompting. Pure rules live in Shared modules; Roblox-dependent services remain thin and focused.

**Tech Stack:** Luau, Roblox Players/SocialService/HumanoidDescription/PathfindingService APIs where applicable, RemoteEvents, Humanoid, Rojo, Luau unit tests, Python source/layout validation, GitHub Actions.

**Spec:** docs/superpowers/specs/2026-09-30-friend-echo-shop-final-design.md

## Global Constraints

- Collision Battlestar remains an action-first PvE wave arena.
- Friend Echo is assistance, not autoplay.
- One active Friend Echo per player in this phase.
- Four initial classes: Vanguard, Striker, Guardian, Support.
- Exact Echo combat parameters are defined in the spec.
- Identity, class, cosmetics and power are separate concepts.
- A real friend joining the server disables every Echo representing that friend UserId for its respective owner.
- Enemy visual themes are server-selected; cosmetics never change enemy stats.
- Eight initial enemy themes: Urban, Tactical, Industrial, Neon, Street, Corrupted, Arctic, Desert.
- Elite always retains a strong red visual identity.
- Server authority decides eligibility, target, damage, skin, price, ownership, rewards and progression.
- Roblox SocialService invite prompts execute on the client after capability checks; the server validates any received launch context.
- No paid random items/gacha in this phase.
- Shop is separated into Catalog, Inventory and Equipment.
- Quick Shop is available only in Intermission/Cleared; Full Shop is an overlay.
- Credits purchases are atomic: a failed ownership grant must not consume currency.
- Pure rules must be testable without Roblox runtime objects.
- Do not reintroduce legacy runtime loaders/watchdogs or duplicate HUD systems.
- Keep the existing server-authoritative M1/Dash/wave core intact unless a task explicitly requires an interface change.
- Performance target: at most 20 active wave enemies plus 1 active Echo per player, bounded AI/pathfinding/FX and no high-frequency continuous gameplay remotes.
- Enemy skin assembly uses at most 14 visible body/gear parts per enemy, excluding required root/label.

## Review Focus

- Invalid or spoofed FriendUserId must never create an Echo or expose non-public account data. Test: rejects a non-friend and self-selection with server-side cached membership.
- An enemy must never receive an invalid theme/tier/profile combination or a cosmetic profile that changes combat stats. Test: profile compatibility and stat independence.
- Friend avatar resolution failure must not break the wave. Test: safe fallback profile is returned and Factory can still construct an Echo.
- An Echo must not attack through walls, exceed combat range/cooldown, damage allies or create an independent reward identity. Test: companion actor requests use the same server combat legality checks.
- Client-supplied commerce price/reward or repeated purchase requests must never be trusted. Test: server resolves ItemId/price and a simulated grant failure leaves Credits unchanged.
- UI must remain usable on small mobile screens and must not duplicate after respawn. Test: HUD contract, single-root ownership, safe-area configuration and contextual Quick Shop visibility.

---

### Task 1: Shared Friend, Echo, Enemy Skin and Shop Rules

**Files:**
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/FriendRules.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/CompanionDefinitions.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/EnemySkinDefinitions.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/EnemySkinRules.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/ShopDefinitions.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/ShopRules.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/InventoryRules.lua
- Modify: tools/tests/run.luau
- Create: tools/tests/FriendRulesSpec.luau
- Create: tools/tests/CompanionRulesSpec.luau
- Create: tools/tests/EnemySkinRulesSpec.luau
- Create: tools/tests/ShopRulesSpec.luau

**Interfaces:**
- FriendRules.isEligible(requestingUserId, friendUserId, friendIds) -> boolean.
- FriendRules.classIsValid(classId) -> boolean.
- CompanionDefinitions exposes exact Vanguard/Striker/Guardian/Support parameters from the spec.
- EnemySkinRules.isValidProfile(profile) -> boolean.
- EnemySkinRules.validProfiles(themeId, tier) -> {Profile}.
- EnemySkinRules.pick(themeId, tier, seed, previousProfileId?) -> Profile.
- ShopRules.canPurchase(credits, price, owned) -> boolean.
- ShopRules.price(itemId, catalog) -> number|nil.
- InventoryRules.canEquip(itemId, owned) -> boolean.

- [ ] **Step 1: Write the failing tests**
Test self/non-friend/valid-friend selection, class validity, exact class parameter bounds, theme/tier compatibility, deterministic profile validity, consecutive-profile avoidance, Elite red identity, authoritative price lookup, insufficient Credits, duplicate ownership and equip validity.

- [ ] **Step 2: Run tests to verify RED**
Run: `luau tools/tests/run.luau`
Expected: the new specs fail because the new rule modules are not present.

- [ ] **Step 3: Implement the shared rule modules**
Keep them pure and Roblox-independent. Catalog entries use stable ItemId/category/price fields. Enemy profiles contain palette and visual-variant metadata only; they never modify combat stats.

- [ ] **Step 4: Run tests to verify GREEN**
Run: `luau tools/tests/run.luau`
Expected: all existing and new tests pass.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add social skin and shop rules"`

### Task 2: Procedural Enemy Skin Factory

**Files:**
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Enemies/SkinFactory.lua
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Enemies/EnemyFactory.lua
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Enemies/Service.lua
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Waves/Service.lua
- Create: tools/tests/EnemySkinFactorySpec.luau

**Interfaces:**
- SkinFactory.Apply(model, profile) -> boolean.
- EnemyFactory.Create(tier, spawnCFrame, skinProfile?) -> Model.
- Enemy Service requests a server-owned skin profile for every spawned enemy.

- [ ] **Step 1: Write the failing tests**
Test that applying a valid profile changes visual composition, does not change enemy combat attributes, respects the 14-part budget, and always gives Elite a red identity. Test that wave spawning passes theme/profile data from the server.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: skin factory tests fail because the new appearance pipeline does not exist.

- [ ] **Step 3: Implement**
Replace the current single-color block look with bounded procedural visual variants. Each wave selects one theme; each enemy selects a compatible tier profile through EnemySkinRules. Preserve the current Humanoid/root contract.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: complete Luau suite passes.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add coherent randomized enemy skins"`

### Task 3: Friend Resolver, Cache and Safe Avatar Profiles

**Files:**
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Friends/Service.lua
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Companions/AvatarResolver.lua
- Create: src/CollisionBattlestar/ServerScriptService/Foundation/Companions/VisualProfile.lua
- Create: tools/tests/FriendResolutionSpec.luau
- Modify: tools/validate_project.py

**Interfaces:**
- FriendService:IsFriend(player, friendUserId) -> boolean.
- FriendService:ResolveFriends(player) -> {FriendProfile}.
- FriendService cache refreshes only when stale or explicitly requested.
- AvatarResolver:Resolve(friendUserId, classId) -> AvatarResult.
- VisualProfile.fallback(classId, variantSeed) -> Profile.

- [ ] **Step 1: Write failing tests**
Cover valid/invalid friend IDs, self rejection, cached membership, deterministic fallback profile shape and the guarantee that avatar failure still returns a spawnable fallback.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: the new resolution tests fail because the modules do not exist.

- [ ] **Step 3: Implement**
Use Players:GetFriendsAsync and supported avatar APIs only inside the service/resolver boundary. Wrap network calls safely. Cache public friend-profile data for a bounded interval. Never use avatar appearance to choose combat stats.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: full Luau suite passes.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add safe friend resolution and avatar fallback"`

### Task 4: Echo Factory, AI and Real-Player Substitution

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
Cover class target priorities, valid state transitions, owner-safe positioning, one active Echo, and disabling all matching Echoes when the represented friend is present.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: new companion tests fail on missing modules/behavior.

- [ ] **Step 3: Implement**
Use bounded AI updates. The brain supports Follow, Acquire, Position, Attack, Protect, Support, Retreat, Recover, Stunned and Disabled. Pathfinding recovers from blocked routes. Factory uses non-blocking ally geometry.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: companion tests and existing suite pass.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add friend echo ai and spawning"`

### Task 5: Shared Combat Integration and Client Invite Prompt

**Files:**
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Combat/Service.lua
- Create: src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/SocialInvite.lua
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/NetworkRules.lua
- Create: tools/tests/CompanionCombatSpec.luau

**Interfaces:**
- CompanionCombat actor requests use the existing server combat validation path.
- SocialInvite.CanInvite(player) -> boolean.
- SocialInvite.PromptInvite(player, friendUserId?) -> boolean.

- [ ] **Step 1: Write failing tests**
Test that an Echo cannot hit invalid targets, cannot damage allies, cannot bypass cooldown/range/LOS rules, cannot heal above MaxHealth, and cannot generate an independent reward identity. Test action payload boundaries for summon/command operations.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: companion-combat tests fail before integration.

- [ ] **Step 3: Implement**
Refactor only enough of CombatService to accept a server-owned actor context without giving the Echo a privileged path. Implement SocialInvite as a client-only wrapper around SocialService:CanSendGameInviteAsync and PromptGameInvite. The server never attempts to display the invite prompt.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: complete suite passes.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: integrate friend echoes with combat and invites"`

### Task 6: Inventory, Catalog and Atomic Credits Shop Service

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
Test known-price purchase, insufficient Credits, duplicate ownership, unknown ItemId, malformed ItemId, client price tampering, and simulated grant failure leaving the original Credits balance unchanged.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: new inventory/shop tests fail before implementation.

- [ ] **Step 3: Implement**
Use ItemId as the only client-supplied commerce identifier. Resolve all prices, requirements and rewards server-side. Validate before mutation and perform currency+ownership as one logical transaction.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: all tests pass.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add server-authoritative shop inventory"`

### Task 7: Quick Shop, Full Shop, Friend Panel and HUD

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
Cover required HUD elements, unique root ownership, shop categories, friend/role selection states, owned/equipped visual states, purchase feedback, contextual Echo information, and Quick Shop visibility only in Intermission/Cleared.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: new HUD contract assertions fail for missing social/shop elements.

- [ ] **Step 3: Implement**
Use ScreenInsets = CoreUISafeInsets, responsive layouts, ScrollingFrame/UIGridLayout for catalog content, and one client bootstrap. Keep Full Shop modal and Quick Shop compact. Keep combat controls outside native mobile control areas.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: all unit tests pass.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add mobile friend and shop hud"`

### Task 8: Commerce and Friend Action Networking Security

**Files:**
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Bootstrap.server.lua
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Security/Service.lua
- Create: tools/tests/CommerceSecuritySpec.luau

**Interfaces:**
- Commerce RemoteEvent accepts only a whitelist such as PurchaseCreditsItem, EquipItem and UnequipItem.
- Action RemoteEvent accepts only existing combat actions plus explicitly defined friend/companion actions.
- Security service exposes bounded request/rate validation for commerce and friend actions.

- [ ] **Step 1: Write failing tests**
Cover unknown action, wrong payload type, missing/oversized ItemId, repeated purchase spam, non-friend UserId, invalid class and summon requests when a player already has an Echo.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: commerce/security tests fail before hardened validation exists.

- [ ] **Step 3: Implement**
Add Commerce remote creation, strict payload validation and rate limiting while preserving Action/State/FX responsibilities. Do not accept client-provided prices, rewards or ownership states.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: complete suite passes.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: harden friend and commerce remotes"`

### Task 9: Persistence-Ready State Contract

**Files:**
- Create: src/CollisionBattlestar/ReplicatedStorage/Shared/ProfileSchema.lua
- Modify: src/CollisionBattlestar/ServerScriptService/Foundation/Core/PlayerState.lua
- Create: tools/tests/ProfileSchemaSpec.luau

**Interfaces:**
- ProfileSchema.default() -> serializable profile.
- ProfileSchema.sanitize(profile) -> sanitized profile.

- [ ] **Step 1: Write failing tests**
Cover default profile shape, unknown-field removal, and stable serialization of Credits, inventory, equipment, Echo loadout, Bond/Level, enemy-skin presentation choices where persistence is appropriate, and upgrades.

- [ ] **Step 2: Run RED**
Run: `luau tools/tests/run.luau`
Expected: schema tests fail before the profile contract exists.

- [ ] **Step 3: Implement**
Keep DataStore calls out of this phase. PlayerState consumes the schema and remains in-memory while exposing persistence-ready plain data. Enemy wave skin choice itself remains runtime state unless future progression requires a saved cosmetic unlock.

- [ ] **Step 4: Run GREEN**
Run: `luau tools/tests/run.luau`
Expected: complete suite passes.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "feat: add persistence-ready player profile schema"`

### Task 10: Runtime Validation, Documentation and Final Review

**Files:**
- Create: tools/tests/test_validation_requirements.py
- Modify: tools/validate_project.py
- Modify: README.md
- Modify: docs/FRIEND_ECHO_SHOP_RESEARCH_2026-09-30.md

**Interfaces:**
- Validation must require all social/shop/skin runtime modules, new HUD modules, ProfileSchema and exactly the intended bootstrap path.

- [ ] **Step 1: Write the failing validation test**
Create test_validation_requirements.py that reads tools/validate_project.py and asserts it contains the required social/shop/skin runtime paths. It must fail before validator changes because those requirements are not yet listed.

- [ ] **Step 2: Run RED**
Run: `python3 tools/tests/test_validation_requirements.py`
Expected: FAIL because the validator does not yet require the new runtime paths.

- [ ] **Step 3: Implement validation/documentation**
Add the new required paths and explicit runtime structure checks. Document the final player loop and development commands.

- [ ] **Step 4: Run GREEN and the full gate**
Run: `python3 tools/tests/test_validation_requirements.py && luau tools/tests/run.luau && python3 tools/tests/test_map_layout.py && python3 tools/validate_project.py && rojo build default.project.json --output build/CollisionBattlestar.rbxl`
Expected: every command exits 0 and the Rojo build file exists and is non-empty.

- [ ] **Step 5: Commit**
`git add ... && git commit -m "chore: validate final friend echo skin shop rebuild"`

## Branch Completion Gate

Before merge or publish:

1. Read the full diff against main.
2. Run the entire validation command again from a clean working tree.
3. Perform a separate whole-branch code review.
4. Any Critical/Important finding requires a failing regression test, fix, full-suite green run and commit.
5. Minor findings are recorded explicitly rather than silently changing scope.
6. Do not publish to Roblox until the human explicitly authorizes the external side effect.
7. A successful Rojo build/CI run is not a substitute for an observed Roblox client playtest.
