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
- Cached friend-list resolution with server-side eligibility checks.
- Friend Echo identity data.
- Avatar-based visual representation with safe fallback.
- Four initial Echo classes: Vanguard, Striker, Guardian, Support.
- One active Echo per player.
- Server-authoritative Echo spawning and AI.
- Shared combat rules between player and Echo where practical.
- Echo follow, target acquisition, attack, protection/support, retreat and stuck recovery states.
- Real-player substitution: every active Echo representing a friend UserId is disabled for its owner when that real friend is present in the same server.
- Client-side Roblox game invite entry point with capability checks.
- Shop catalog definitions.
- Quick Shop during non-combat-safe phases.
- Full Shop overlay.
- Inventory ownership model.
- Equip/unequip model.
- Direct Credits purchases.
- Atomic server-side purchase transaction.
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
- Production Premium purchase handlers until real product identifiers are configured.
- Dynamic wave director.

## Non-goals

- Do not turn Friend Echo into a generic percentage-stat pet.
- Do not allow the client to choose damage, ownership, item price or reward.
- Do not copy code or assets from referenced games.
- Do not make companions able to use impossible combat behavior.
- Do not make the shop permanently cover the combat HUD.
- Do not perform friend discovery continuously or every frame.

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
- the UserId is a finite positive integer;
- the user appears in the server-resolved friend list for the requesting player;
- the selected friend is not the requesting player;
- a valid Echo class is selected;
- the selection request is rate-limited.

Friend-list resolution uses a bounded cache per player. A selection request may refresh the cache when it is stale; it must not call the friends API on every UI frame or button repaint.

Only public fields returned by Roblox's friend/avatar APIs are stored for this system. No unrelated account information is collected.

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

Initial behavior:
- preferred distance: close;
- attack priority: enemies attacking owner, then nearby threats;
- lower damage than Striker but stronger close-range pressure.

### Striker

Damage-oriented attacker.

Initial behavior:
- preferred distance: medium;
- attack priority: Elite, strongest threat, then nearest valid target;
- highest Echo damage contribution.

### Guardian

Defensive interceptor.

Initial behavior:
- preferred distance: close-to-owner;
- attack priority: enemies approaching or targeting owner;
- favors interception over chasing distant targets.

### Support

Position-preserving support.

Initial behavior:
- preferred distance: medium;
- prioritizes owner safety and recovery;
- performs a small bounded heal/support action on a cooldown;
- contributes lower direct damage than Vanguard/Striker.

Support must use the same server authority and target validation rules as every other Echo.

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
- every active Echo representing that friend's UserId is disabled for its respective owner;
- the real player is never controlled by the Echo system;
- the owner can select another valid friend after a safe state transition.

When that friend leaves, the owner may summon the Echo again subject to normal validation and rate limits.

## Social invite

The invite prompt is a client-side operation using Roblox SocialService.

The client:
1. checks CanSendGameInviteAsync with pcall;
2. opens PromptGameInvite when permitted;
3. may use ExperienceInviteOptions for a specific friend or launch data.

The server never trusts invite UI state as proof of identity or authorization. Any launch data received by the server through Player:GetJoinData is treated as convenience context only and is validated before use.

## Combat integration

The Echo uses a dedicated server-side actor interface that calls shared combat rules.

Required guarantees:
- Echo cannot deal damage outside valid target/range/context rules.
- Echo attacks obey cooldowns.
- Echo cannot damage allies/itself.
- Echo cannot grant itself rewards.
- Echo cannot bypass Elite or wave rules.
- Echo rewards remain attributed to the player only through the server's existing reward path.

The player remains the primary combat agent; the Echo is a helper, not an automated victory mechanism.

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

This category contains Echo cosmetics and presentation, not ownership of real friends.

### Upgrades

- Damage;
- Max Health;
- Dash;
- Critical;
- Recovery.

Upgrade costs are server-calculated.

### Premium

Reserved architecture for Game Passes and Developer Products. No production purchase handlers are included in this phase until real product identifiers are configured.

## Shop purchase rules

Credits purchase must be atomic.

Flow:

1. client requests ItemId;
2. server validates request structure;
3. server resolves catalog item;
4. server checks item is active and purchasable;
5. server checks requirements;
6. server checks current ownership;
7. server computes authoritative price;
8. server verifies balance;
9. server applies inventory grant and currency deduction as one logical transaction;
10. server sends result state to client.

If the ownership grant cannot be completed, the currency deduction must not commit.

The client never supplies price, Credits reward, ownership state or grant payload.

Unknown items, malformed identifiers, repeated purchase requests and insufficient balances are rejected safely.

## Quick Shop

Quick Shop is available only during safe shop phases:
- Intermission;
- Cleared.

It contains:
- current upgrades;
- current equipped Echo;
- selected fast cosmetics.

It is not an unrestricted mid-combat marketplace.

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

Premium purchases, when added, must use Roblox's server-side marketplace/receipt architecture and must not be simulated through client UI.

## Inventory and persistence boundary

Inventory interfaces must be persistence-ready.

For this phase, session memory is acceptable, but the data structures must not depend on UI Instances and must be serializable as plain data.

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
- Friends/Companion entry;
- Invite action when supported;
- Shop open/close state;
- purchase/equip feedback.

Echo information is contextual. It should not permanently occupy the center of the screen.

During Elite encounters, Elite information remains higher priority than companion detail.

## Networking

Remote channels are responsibility based:

- Action: combat and gameplay input requests.
- State: authoritative state updates.
- FX: presentation-only events.
- Commerce: shop/inventory request and result messages.

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
- cached/bounded friend-list requests;
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
- rejecting non-friend;
- class validity;
- fallback profile selection;
- support action bounds;
- no repeated exact visual profile beyond configured anti-repeat rule;
- Echo state transition validity;
- target priority per class;
- one active Echo invariant;
- real-player substitution;
- shop catalog item validation;
- server price authority;
- atomic purchase behavior;
- insufficient Credits;
- duplicate ownership rejection;
- equip/unequip invariants;
- malformed commerce request rejection;
- HUD contract completeness;
- Quick Shop availability only in safe phases.

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
3. receive a server-owned Echo representation with a coherent visual profile or safe fallback;
4. choose one of four roles;
5. fight waves while the Echo follows and assists under legal combat rules;
6. have all Echoes representing a real friend UserId disable when that friend joins;
7. earn Credits through the existing wave/economy loop;
8. open Quick Shop during a safe phase or Full Shop;
9. inspect a known-price item;
10. buy it with Credits when affordable;
11. see ownership/equipment reflected in HUD/UI;
12. invite a friend through the Roblox invite prompt when supported;
13. do all of this without duplicate HUDs, stuck loading screens, client-authoritative rewards or malformed remote requests.

## Reference basis

The design is informed by docs/FRIEND_ECHO_SHOP_RESEARCH_2026-09-30.md.

Roblox platform references:
- https://create.roblox.com/docs/production/game-design/ui-ux-design
- https://create.roblox.com/docs/scripting/security/client-server-boundary
- https://create.roblox.com/docs/reference/engine/classes/Players
- https://create.roblox.com/docs/reference/engine/classes/SocialService
- https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription
- https://create.roblox.com/docs/production/monetization
- https://create.roblox.com/docs/production/monetization/paid-random-items
- https://create.roblox.com/docs/production/monetization/developer-products
