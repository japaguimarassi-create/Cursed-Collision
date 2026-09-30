# Friend Echo + Shop Research Synthesis — 2026-09-30

## Scope

This document closes the research stage for the Collision Battlestar social-companion and shop rebuild. Research covered the evolution of wave/horde games, cooperative companions, AI-controlled allies, Roblox social systems, shop/economy architecture, mobile UI, server-authoritative networking, and public implementation tutorials/videos.

## Historical design patterns

### Horde and wave lineage

Wave progression has roots in arcade games where repeated formations escalate pressure. Later co-op systems such as Gauntlet established the value of complementary player roles. Gears of War Horde made persistent cooperative wave survival a major mode, while Killing Floor established the strong combat -> reward -> buy/preparation -> next wave rhythm. Call of Duty Zombies reinforced the value of escalating threat and special enemies. Left 4 Dead demonstrated that pacing and encounter composition are more important than merely multiplying enemy HP.

### Companion lineage

Dragon's Dogma, SWTOR and similar RPGs show that a companion becomes meaningful when identity and role are separated: the companion can look like a character while its combat role remains a gameplay choice.

Vermintide 2's bot design is particularly relevant: bots should use understandable rules, help fill cooperative gaps, avoid obstructing players, and operate under the same broad combat expectations as human players.

Deep Rock Galactic's Bosco demonstrates a second useful pattern: a solo player can receive meaningful help without the helper replacing the player.

Ghost of Tsushima: Legends demonstrates complementary classes in a cooperative action environment.

### Roblox patterns

Zombie Attack combines waves, bosses, weapons, pets and playing with friends. Tower Defense Simulator combines wave pressure, co-op, units, progression and skins. Bee Swarm Simulator demonstrates how a roster of helpers can have identity and behavior rather than being only stat multipliers. Pet Simulator demonstrates the strength of collection and cosmetic progression, but its high-volume pet model is not appropriate as the primary combat model for Collision Battlestar.

## Video/code research

Public Roblox implementation videos were reviewed for patterns and pitfalls.

### NPC follow

A 2026 NPC follow tutorial demonstrates dynamic nearest-player targeting and real-time retargeting. The useful concept is target selection and reacquisition. The polling frequency used in a tutorial is not appropriate for a production system with many NPCs and companions, so Collision Battlestar will use throttled state evaluation.

### Enemy spawning

A public enemy spawner tutorial demonstrates a basic clone -> position -> parent flow. It also highlights a common mistake where NPCs damage one another. Collision Battlestar must instead use explicit team/faction ownership and server-side target filtering.

### Combat

A public combat tutorial demonstrates the common RemoteEvent + client animation + server damage pattern, but also shows why tutorial code should not be adopted verbatim: client timing, touch-based damage and loosely validated input are not sufficient for a server-authoritative action game.

### UI

Roblox Developer Academy's UI tutorial reinforces that StarterGui is a template copied into PlayerGui, that client UI code belongs in a persistent client script location, and that server/client communication should use remotes rather than assuming synchronous replication of client UI state.

## Current Roblox platform constraints

- Friend discovery should use Roblox's current Players/SocialService capabilities.
- Avatar identity can be resolved through Roblox avatar APIs when permitted.
- Server-side validation remains authoritative for combat, purchases, ownership and progression.
- A game-pass purchase is a one-time entitlement; Developer Products are repeatable purchases and require correct server-side receipt handling.
- Paid random items have additional policy requirements and will not be part of this rebuild.
- Mobile UI must respect safe areas and native control zones.

## Consolidated conclusions

1. Friend Echo is an AI ally representing a friend's identity, not a generic pet and not a replacement for a real player.
2. Identity, class, cosmetics and power must be separate data concepts.
3. One Echo per player is the initial active limit.
4. A real friend joining the same server disables that friend's Echo for the corresponding player.
5. Echoes must use the shared combat rules rather than privileged cheat-like combat.
6. The shop is a product catalog plus ownership/equipment layer, not the inventory itself.
7. Quick Shop and Full Shop serve different contexts.
8. Direct-known-price purchases are preferred for the first shop; paid random items are excluded.
9. Persistent inventory requires a clear data contract before the system is treated as production-complete.
10. The architecture should permit later wave pacing and encounter composition changes without rewriting companions or the shop.

## Selected reference classes

Historical / non-Roblox: arcade wave shooters, Gauntlet, Gears of War Horde, Killing Floor, Call of Duty Zombies, Left 4 Dead, Risk of Rain 2, Dragon's Dogma, SWTOR, Vermintide 2, Deep Rock Galactic, Ghost of Tsushima: Legends.

Roblox: Zombie Attack, Tower Defense Simulator, Bee Swarm Simulator, Pet Simulator 99, Anime Vanguards, Survive The Swarm and current Roblox social/monetization systems.

## Web references

- Roblox UI/UX design: https://create.roblox.com/docs/production/game-design/ui-ux-design
- Roblox client/server security: https://create.roblox.com/docs/scripting/security/client-server-boundary
- Roblox Players API: https://create.roblox.com/docs/reference/engine/classes/Players
- Roblox SocialService: https://create.roblox.com/docs/reference/engine/classes/SocialService
- Roblox HumanoidDescription: https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription
- Roblox monetization: https://create.roblox.com/docs/production/monetization
- Roblox paid random items: https://create.roblox.com/docs/production/monetization/paid-random-items
- Roblox Developer Products: https://create.roblox.com/docs/production/monetization/developer-products
- Roblox MicroProfiler/performance: https://create.roblox.com/docs/performance-optimization/microprofiler
- Vermintide 2 bots: https://www.vermintide.com/news/2018/12/17/dev-blog-how-bots-work-in-vermintide-2
- Ghost of Tsushima: Legends: https://www.playstation.com/pt-br/games/ghost-of-tsushima/legends/
- Killing Floor history: https://killingfloor.net/en/archive/killing-floor/development-history/
- Zombie Attack: https://www.roblox.com/pt/games/1240123653/Zombie-Attack
- Tower Defense Simulator: https://www.roblox.com/games/3260590327/PURSUIT-Tower-Defense-Simulator
- Roblox Developer Academy UI video: https://www.youtube.com/watch?v=KryCvM_-ug4
- NPC follow video: https://www.youtube.com/watch?v=FWU943xjtT8
- Enemy spawner video: https://www.youtube.com/watch?v=Slu138pQSMc
- Combat video: https://www.youtube.com/watch?v=zZmuuRhdUgQ
