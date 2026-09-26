# Collision Battlestar — Rebuild 2026 Research Specification

Research checkpoint: 2026-09-26

## Product target

Collision Battlestar is being rebuilt as a mobile-first Roblox urban action battleground with a continuous world, very short time-to-action, readable combat, strong cosmetic progression and live-ops capacity.

The objective is not to clone another experience. Public games are used to identify proven interaction patterns, failure modes and production constraints; the final game keeps its own combat identity, fiction, art direction and systems.

## What the current Roblox market shows

A current Roblox popular-games snapshot shows that very large experiences can belong to completely different genres, but successful experiences repeatedly combine a clear fantasy, an immediately understandable loop and persistent reasons to return.

- Blox Fruits currently lists 359k active players, 64.3B+ visits, a level cap of 2450, recurring fruit availability and boss/combat exploration. The current page was updated 2026-09-10. Source: https://www.roblox.com/pt/games/2753915549/Blox-Fruits
- Steal a Brainrot currently lists 125k active players, 73.5B+ visits, a tiny 8-player server and a loop based on buying, stealing, generating money and rebirthing. The current page was updated 2026-09-18. Source: https://www.roblox.com/pt/games/109983668079237/Steal-a-Brainrot
- RIVALS currently lists 231k active players and 18.3B+ visits; its official description centers on short 1v1-5v5 rounds, unlocking weapons/skins, contracts and win streaks, with PC/mobile/tablet/Xbox/PS5 support. Source: https://www.roblox.com/pt/games/17625359962/RIVALS
- Jujutsu Shenanigans currently lists about 133k active players and 7.1B+ visits; its official loop is a battleground structure with M1, four skills, dash, block, special and awakening, while its map is strongly associated with destruction. Source: https://www.roblox.com/games/9391468976/Jujutsu-Shenanigans
- Blade Ball currently lists about 21k active players and 6.4B+ visits; its loop is instantly legible: deflect the homing ball, use abilities, progress ranks and collect cosmetics. Source: https://www.roblox.com/games/13772394625/Blade-Ball
- The Strongest Battlegrounds remains an important combat reference because its public controls emphasize a compact action vocabulary: punch, dash, block, ultimate, ragdoll cancel/evasive and movement. Source: https://www.roblox.com/games/10449761463/The-Strongest-Battlegrounds

These numbers are point-in-time Roblox listing data, not forecasts.

## Combat lessons

The strongest reusable idea across battleground references is a small action language that can be understood without a tutorial wall.

Collision Battlestar therefore uses four core combat inputs:
- M1: primary attack/combo
- Dash: reposition / evade
- Block: defensive state
- Special: character/system-defining attack

Parry can exist as a timing result of defensive play instead of another permanent HUD button. Overdrive/Awakening can be a state layered over the four core actions.

Design rule: every action must communicate startup, active window, hit result, cooldown and recovery with animation/VFX/sound. The player should understand why a hit succeeded or failed.

Community discussions repeatedly mention complaints around ping-sensitive combos, inconsistent hit registration, excessive cutscene locks, unclear map/spawn situations and balance around long-range characters. These are community opinions, not objective measurements, but they are useful failure-mode hypotheses to test.

Examples:
- TSB community complaints about hit registration, ping dependence and long cutscene moves: https://www.reddit.com/r/StrongestBattleground/
- JJS community complaints about map borders/spawns and requests for more readable map detail: https://www.reddit.com/r/JujutsuShenanigans/

## Core game loop

The intended loop is:

1. Spawn directly into the city.
2. Reach combat immediately.
3. Fight players or a repeatable PvE activity.
4. Earn Credits + XP from meaningful combat actions.
5. Build streaks / complete missions.
6. Unlock cosmetics, emotes, finishers, banners and presentation options.
7. Trigger temporary world events.
8. Return for another short session.

The player should never have to queue into a separate 1v1/2v2/3v3 arena just to access the main game.

## Map direction

The current procedural Battle Line is retained as the reliable gameplay foundation. It should evolve toward a denser landmark-driven city without making gameplay depend on third-party models.

Required map properties:
- one continuous traversable place;
- recognizable landmarks visible from multiple streets;
- multiple elevation opportunities;
- interiors in selected hero locations;
- alternate routes around damaged structures;
- cover that supports close combat without making targets disappear;
- destruction that changes sightlines but does not permanently break traversal;
- streamed distant content and bounded decorative density.

The current source tree already has five Battle Line districts. Do not expand the district count until the five-zone travel/build/streaming path is reliable. More districts are an art/content expansion, not a substitute for a polished combat loop.

Jujutsu Shenanigans is a useful map reference because community and guide sources repeatedly highlight its destructible environment and landmark-based city layout. The important lesson for Collision Battlestar is not the franchise setting; it is the gameplay effect of destruction on positioning and route choice.

## Art direction

Target:
- stylized modern city at dusk/night;
- dark neutral architecture with controlled accent lighting;
- strong silhouettes around combat zones;
- restrained emissive signage;
- few high-detail hero landmarks;
- inexpensive repeated props;
- readable ground materials and road markings.

Avoid:
- giant piles of generic free models;
- unlicensed franchise characters;
- walls of neon that flatten combat readability;
- excessive particles that hide hitboxes;
- high-poly props repeated hundreds of times.

## Asset sources

### Roblox Creator Store

The current project already has a verified low-cost prop set:
- Bench — 400850371
- Dumpster — 42942436
- Small Blocky Car — 282662596
- Bus Stop — 4987899016
- Bus Stop Sign — 8673868211
- Bus Stop Pole — 18143058886

Runtime policy:
- only use assets with explicit usable-rights evidence;
- sanitize loaded models;
- never make the base map depend on external asset loading;
- treat large/high-poly assets as source references unless optimized.

Roblox Creator Store: https://create.roblox.com/store

### Kenney / CC0

Good source for custom-imported city and UI building blocks:
- City Kit Commercial: https://kenney.nl/assets/city-kit-commercial
- City Kit Industrial: https://kenney.nl/assets/city-kit-industrial
- City Kit Roads: https://kenney.nl/assets/city-kit-roads
- UI Pack: https://kenney.nl/assets/ui-pack
- UI Pack Sci-Fi: https://kenney.nl/assets/ui-pack-sci-fi

Kenney's listed packs are CC0, which makes them useful source material for adaptation rather than a reason to ship giant unoptimized packs directly.

### Icons / 2D

Game-icons.net provides thousands of SVG/PNG icons under CC BY 3.0: https://game-icons.net/

For the game HUD, prefer a coherent icon family and custom compositions over mixing unrelated Creator Store images.

## Public Roblox development repositories

Repositories worth studying for architecture patterns, not copying proprietary game code:
- Sleitnick/Knit — lightweight Roblox game framework, MIT: https://github.com/Sleitnick/Knit
- dphfox/Fusion — reactive Luau UI/state framework, MIT: https://github.com/dphfox/Fusion
- Sleitnick/RbxUtil — reusable Roblox utility modules, MIT: https://github.com/Sleitnick/RbxUtil
- Quenty/NevermoreEngine — reusable server/client modules, MIT: https://github.com/Quenty/NevermoreEngine
- At1laas/roblox-luau-combat-system — public combat-system reference: https://github.com/At1laas/roblox-luau-combat-system
- Synphrax/roblox-combat-system — public combat-system reference: https://github.com/Synphrax/roblox-combat-system

Use these for architecture ideas, validation patterns, utility abstractions and API usage. Collision Battlestar remains its own codebase.

## HUD / UX direction

The HUD must answer these questions within one glance:
- Where am I?
- How much HP do I have?
- What resource is relevant right now?
- Is my Special ready?
- Am I blocking / stunned / in an event?
- What can I press on this device?

The main combat screen should stay sparse.

Permanent combat HUD:
- player status;
- HP;
- Energy/secondary resource;
- Awakening/Overdrive meter;
- four action controls;
- compact location/streak information.

Secondary UI:
- map;
- missions;
- progression;
- shop;
- settings.

Mobile rules:
- respect safe areas;
- keep thumb-reachable actions clear of Core UI;
- never require tiny text;
- touch controls must have the same authoritative game actions as keyboard/gamepad.

Official references:
- https://create.roblox.com/docs/production/game-design/ui-ux-design
- https://create.roblox.com/docs/ui/scale-properties
- https://create.roblox.com/docs/reference/engine/classes/GuiService

## Retention without pay-to-win

Use progression for return motivation, not power sales.

Recommended:
- Credits from kills / activities;
- XP and levels;
- daily/weekly/general missions;
- streak milestones;
- emotes;
- skins;
- finishers;
- kill effects;
- profile/banner customization;
- limited-time cosmetic drops;
- rotating city events.

Do not sell direct combat advantage.

Blox Fruits demonstrates the power of persistent progression and recurring content; RIVALS demonstrates a short repeatable match structure with unlocks; Steal a Brainrot demonstrates extremely simple verbs plus repeatable progression and rebirth. Collision Battlestar combines the retention principles without copying their genres.

## Performance budget

Mobile is a first-class target.

Rules:
- enable instance streaming for the continuous city;
- keep repeated props cheap;
- cap dynamic VFX;
- use client-side presentation for non-authoritative effects;
- avoid unnecessary per-frame server work;
- keep destruction bounded and restorable;
- avoid hundreds of active lights;
- preload only what is needed for the next local combat state;
- test on low/mid Android hardware before adding visual density.

Official references:
- https://create.roblox.com/docs/workspace/streaming
- https://create.roblox.com/docs/performance-optimization
- https://create.roblox.com/docs/microprofiler

## Discovery / packaging

Roblox's own discovery documentation emphasizes accurate metadata, original imagery and the relationship between packaging, engagement and retention.

Collision Battlestar needs:
- a readable icon at tiny size;
- a thumbnail with one clear combat subject;
- one hero city landmark;
- one immediately understandable combat moment;
- no cluttered UI screenshots as the primary thumbnail;
- consistent title/description/tags.

Official references:
- https://create.roblox.com/docs/discovery
- https://create.roblox.com/docs/production/game-design/discovery

## Video research

Useful public video topics found during research:
- JJS custom map building demonstrates the importance of fast environment iteration and readable map construction: https://www.youtube.com/watch?v=Vf6tq2n3n1I
- JJS custom maps/movesets content shows the demand for creator-driven variation: https://www.youtube.com/watch?v=4mF6a6vG2mM
- Strongest Battlegrounds competitive guides emphasize movement, side-dashing, counter-dashing, combo execution and punishment rather than adding more buttons: https://www.youtube.com/watch?v=I0e9oK4E7gc

Video titles, dates and public engagement can change; the links are references for study, not evidence that a particular mechanic is universally preferred.

## Production roadmap

### Phase A — Foundation
- fix source-of-truth inconsistencies;
- turn streaming on;
- verify boot/map/HUD contracts;
- keep five districts;
- make M1/Dash/Block/Special airtight;
- make mobile and gamepad actions map to the same server contracts;
- test respawn, travel, combat and destruction.

### Phase B — Combat polish
- authored animation set;
- hit-stop and camera response;
- impact sound variations;
- stronger hit reaction states;
- combo readability;
- anti-spam / anti-exploit validation;
- low-FX mode.

### Phase C — Retention
- daily/weekly/general missions;
- streak rewards;
- Credits economy;
- emote/skin inventory;
- cosmetic shop;
- rotating event schedule.

### Phase D — Social / live ops
- party/friend flow;
- private server configuration;
- creator map ecosystem;
- limited-time city events;
- seasonal cosmetic content;
- analytics-driven balancing.

## Ship gates

A build should not be treated as production-ready until:
- the map loads from a clean server;
- the HUD has no placeholder-only panels;
- all four core actions work on touch, keyboard and gamepad;
- no combat-critical client value is trusted by the server;
- destruction restores safely;
- streaming does not strand the player;
- a low-end mobile test stays responsive during a real multi-player fight;
- external assets failing to load do not break gameplay;
- the icon/thumbnail/description communicate the game without explanation.

## Current repo notes

The repository already has a useful foundation: Rojo source-of-truth, server-authoritative services, procedural Battle Line generation, optional low-cost Creator Store props, validation workflow, client HUD bootstrap and animation fallback.

The most important immediate technical inconsistency found in the audit is that the Rojo project file currently sets Workspace.StreamingEnabled=false while the research/runtime documentation describes the map as streamed. This rebuild pass resolves that mismatch first.

Sources used for this research include Roblox Creator Hub, official Roblox experience pages, public community discussions, public GitHub repositories and permissively licensed asset libraries.
