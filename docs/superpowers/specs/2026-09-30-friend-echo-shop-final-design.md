# Collision Battlestar Friend Echo + Shop Rebuild — Design Specification

**Date:** 2026-09-30  
**Project:** Collision Battlestar (repository remains Cursed-Collision for compatibility)  
**Status:** Design frozen for implementation review

## Goal

Add a social companion system in which a selected Roblox friend can be represented by an AI-controlled Friend Echo, and add a direct-purchase shop/inventory foundation that integrates with the existing PvE wave loop without replacing the player's agency.

## Product principle

Collision Battlestar remains an action-first PvE wave arena.

The hierarchy is:

**Player > Friend Echo > Wave pressure > Progression > Cosmetics.**

The player must remain the primary combat agent. Friend Echo is assistance, not autoplay. Shop is progression and personalization, not a shortcut that invalidates combat.

## Scope

### Included

- Friend discovery and selection.
- Friend Echo identity data.
- Avatar-based visual representation with safe fallback.
- Four initial Echo classes: Vanguard, Striker, Guardian, Support.
- One active Echo per player.
- Server-authoritative Echo spawning and AI.
- Shared combat rules between player and Echo where practical.
- Echo follow, target acquisition, attack, protection/support, retreat and stuck recovery states.
- Real-player substitution: an Echo representing a friend is disabled when that friend is present in the same server for that owner.
- Roblox game invite entry point.
- Shop catalog definitions.
- Quick Shop.
- Full Shop.
- Inventory ownership model.
- Equip/unequip model.
- Direct Credits purchases.
- Shop ownership validation on the server.
- HUD integration for Echo and shop states.
- Data contracts designed for later persistence.
- TDD coverage for pure rules and contracts.
- Performance budgets.

### Deferred

- DataStore persistence implementation.
- Trading.
- Player-to-player marketplace.
- Paid random items/gacha.
- Multiple simultaneous Echo slots.
- Friend Echo breeding/merging.
- Clans/guilds.
- Seasonal pass.
- Large-world social hub.
- Full Premium implementation beyond architectural interfaces.
- Dynamic wave director.

## Non-goals

- Do not turn Friend Echo into a generic percentage-stat pet.
- Do not allow the client to choose damage, ownership, item price or reward.
- Do not copy code or assets from referenced games.
- Do not make companions able to use impossible combat behavior.
- Do not make the shop permanently cover the combat HUD.

## Friend Echo data model

Identity and gameplay are separate.

FriendProfile:
- UserId: number
- DisplayName: string
- Username: string
- AvatarReady: boolean

EchoLoadout:
- FriendUserId: number
- ClassId: string
- Level: number
- Bond: number
- CosmeticIds: {string}
- Equipped: boolean

The server is authoritative for the effective loadout. Client state is presentation only.

## Friend selection rules

A friend may be selected only if:
- the user exists in the player's actual Roblox friend list;
- the UserId is structurally valid;
- the selected friend is not the requesting player;
- a valid Echo class is selected;
- the request is rate-limited.

The system must support a safe fallback when friend resolution or avatar description retrieval fails. The Echo should still spawn with a valid game-owned visual profile rather than failing the match.

## Friend Echo visual system

Avatar identity is resolved separately from combat class.

Preferred path:
- resolve the friend's avatar description through supported Roblox avatar APIs;
- construct a safe Echo model;
- apply owned Echo cosmetics afterward.

Fallback path:
- use a game-owned procedural humanoid visual profile derived from the selected Echo class.

The visual system must never use the friend's appearance to determine combat power.

## Echo classes

### Vanguard

Short-range protector and pressure fighter.

Priority:
1. enemies attacking the owner;
2. nearby enemies;
3. Elite within reasonable reach.

### Striker

Damage-oriented attacker.

Priority:
1. Elite;
2. strongest current enemy;
3. nearest threat.

### Guardian

Defensive interceptor.

Priority:
1. enemies closing on owner;
2. enemies targeting owner;
3. nearby threats.

### Support

Position-preserving support.

Priority:
1. owner health/support need;
2. owner safety;
3. low-risk enemy contribution.

Each class must have the same fundamental constraints as other actors: server-side state, legal movement, target validation, cooldowns and bounded effects.

## Echo AI state machine

Initial states:
- Follow
- Acquire
- Position
- Attack
- Protect
- Support
- Retreat
- Recover
- Stunned
- Disabled

State transitions are evaluated at a bounded rate, not on a 0.01-second polling loop.

Target selection is distance/context based and must re-acquire when:
- the target dies;
- the target leaves the allowed zone;
- the target becomes invalid;
- path becomes unusable.

Pathfinding should use Roblox pathfinding where needed and must react to blocked paths instead of repeatedly walking into the same obstacle.

Echo movement must avoid:
- overlapping the owner;
- blocking the owner's camera;
- pushing the owner;
- occupying the exact same position as another ally;
- permanent teleports.

## Real-player substitution

When a friend represented by an Echo joins the same server:
- the corresponding owner's Echo is disabled;
- the real player is never controlled by the Echo system;
- the owner can reselect another friend after a safe state transition.

If the real friend leaves, the owner may summon the Echo again subject to normal selection/rate limits.

## Social invite

A client-visible Invite action may use Roblox SocialService after capability checks.

The server must not trust client-provided friend identity merely because the client shows a friend picker.

Launch data, if used, is convenience context only and is not proof of ownership or permission.

## Combat integration

The Echo uses a dedicated server-side actor interface that calls shared combat rules.

Required guarantees:
- Echo cannot deal damage outside valid target/range/context rules.
- Echo attacks obey cooldowns.
- Echo cannot damage allies/itself.
- Echo cannot grant itself rewards.
- Echo cannot bypass Elite or wave rules.
- Echo rewards remain attributed to the player only through the server's existing reward path.

The player remains responsible for the majority of combat interaction; the Echo is a helper, not an automated victory mechanism.

## Shop architecture

Shop is divided into three concepts:

Catalog
- what exists for sale.

Inventory
- what the player owns.

Equipment
- what the player currently has equipped.

The shop must never use the Inventory object as its source of truth for price.

## Initial catalog

### Skins
- player visual skins;
- attack/finisher visual cosmetics;
- Echo cosmetics;
- Elite cosmetic variants.

### Companions

This category contains Echo cosmetics and Echo presentation, not ownership of real friends.

### Upgrades
- Damage;
- Max Health;
- Dash;
- Critical;
- Recovery.

Upgrade costs are server-calculated.

### Premium

Reserved architecture for Game Passes and Developer Products. No production purchase handlers are included in this phase until product identifiers are configured.

## Shop purchase rules

Credits purchase:

1. client requests ItemId;
2. server resolves catalog item;
3. server checks item is active and purchasable;
4. server checks requirements;
5. server checks current ownership;
6. server computes authoritative price;
7. server verifies balance;
8. server removes Credits;
9. server grants Inventory ownership;
10. server sends result state to client.

The client never supplies price or reward payload.

Unknown items, malformed identifiers, repeated purchase requests and insufficient balances are rejected safely.

## Quick Shop

Quick Shop is available during safe combat windows.

It contains only high-frequency actions:
- current upgrades;
- current equipped Echo;
- selected fast cosmetics.

It must close cleanly without losing combat state.

## Full Shop

Full Shop is an overlay with:
- categories;
- item grid;
- owned/equipped status;
- authoritative price display;
- preview;
- purchase/equip actions;
- close button.

The UI uses responsive layout and safe-area constraints rather than fixed screen coordinates.

## Economy boundaries

Credits remain an in-game currency.

No paid-random-item system is included.

Premium purchases, when added, must be processed by Roblox's server-side marketplace/receipt flow and must not be simulated through client UI.

## Inventory and persistence boundary

Inventory interfaces must be persistence-ready.

For this phase, session memory is acceptable, but the data structures must not depend on UI instances and must be serializable as plain data.

The later DataStore layer will persist:
- Credits;
- owned item IDs;
- equipped item IDs;
- Friend Echo loadouts;
- Echo Bond/Level;
- permanent upgrades.

## HUD requirements

The HUD must expose:
- compact player HP;
- Credits;
- Wave/hostile count;
- active Echo identity/class;
- Echo state when meaningful;
- Shop button;
- Shop open/close state;
- purchase/equip feedback.

Echo information is contextual. It should not permanently occupy the center of the screen.

During Elite encounters, Elite information remains higher priority than companion detail.

## Networking

Remote channels are responsibility based:
- Action: combat and gameplay input requests.
- State: authoritative state updates.
- FX: presentation-only events.
- Commerce: shop/inventory/purchase requests and results.

All server-bound requests validate:
- action;
- payload structure;
- player state;
- permission;
- zone;
- cooldown/rate;
- target/item existence;
- distance/context where applicable.

No remote sends gameplay-authoritative results from client to server.

## Performance budget

Initial target:
- at most 20 active wave enemies;
- at most 1 active Friend Echo per player;
- bounded AI update frequency;
- bounded path recomputation;
- bounded FX count;
- no unbounded per-NPC polling;
- no high-frequency RemoteEvent spam for continuous movement.

The system should prefer a small number of focused models and effects over large numbers of decorative instances.

## Testing requirements

Pure rules must be testable without Roblox runtime objects.

Required tests:
- friend selection eligibility;
- rejecting self as friend;
- class validity;
- fallback profile selection;
- no repeated exact skin/profile assignment beyond configured anti-repeat rule;
- Echo state transition validity;
- target priority per class;
- real-player substitution;
- shop catalog item validation;
- server price authority;
- purchase balance check;
- duplicate ownership rejection;
- equip/unequip invariants;
- malformed commerce request rejection;
- HUD contract completeness.

Integration/source validation must continue to run:
- Luau tests;
- map/layout tests;
- source validation;
- Rojo build.

A Roblox client runtime playtest is not considered verified unless an actual client session can be executed and observed.

## Success criteria

A successful implementation allows a player to:
1. open the social/companion UI;
2. choose a valid friend;
3. receive a server-owned Echo representation with a coherent visual profile;
4. choose one of four roles;
5. fight waves while the Echo follows, assists and obeys legal combat rules;
6. have the Echo disappear appropriately when the real friend joins;
7. earn Credits through the existing wave/economy loop;
8. open Quick Shop or Full Shop;
9. inspect a known-price item;
10. buy it with Credits when affordable;
11. see ownership/equipment reflected in HUD/UI;
12. do all of this without duplicate HUDs, stuck loading screens, client-authoritative rewards or malformed remote requests.

## Reference basis

The design is informed by the final research synthesis in docs/FRIEND_ECHO_SHOP_RESEARCH_2026-09-30.md.

Roblox platform references:
- https://create.roblox.com/docs/production/game-design/ui-ux-design
- https://create.roblox.com/docs/scripting/security/client-server-boundary
- https://create.roblox.com/docs/reference/engine/classes/Players
- https://create.roblox.com/docs/reference/engine/classes/SocialService
- https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription
- https://create.roblox.com/docs/production/monetization
- https://create.roblox.com/docs/production/monetization/paid-random-items
- https://create.roblox.com/docs/production/monetization/developer-products
