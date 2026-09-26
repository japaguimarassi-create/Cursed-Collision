# Collision Battlestar — Evolution Plan

The project is intentionally rebuilt as a playable Tag game first. Each later stage adds a new system without replacing the stable world, networking, UI foundation, or persistence boundary.

## Stage 1 — Tag

Core loop:
- one player becomes the tagger;
- the tagger is visibly marked red;
- the server owns role changes;
- contact/proximity transfers the role;
- short intermission and timed rounds;
- dense procedural arena with streets, buildings, towers, cover, ramps, containers, a central plaza and an elevated bridge.

Acceptance criteria:
- a player can join, spawn, run and understand the role immediately;
- the red marker survives normal character respawns;
- tag transfer is server-controlled;
- the map provides multiple escape routes and vertical options;
- no gameplay depends on external assets.

## Stage 2 — Tag + Combat

Introduce:
- M1;
- dash;
- block;
- one Special;
- server-side hit validation;
- combat VFX and animation hooks.

The Tag role remains the easy-to-understand mode while combat becomes an optional layer.

## Stage 3 — PvE Conversion

The tagger role becomes the enemy role.

Wave structure:
1. spawn a small group of weak NPCs;
2. every wave increases health, damage, speed, behavior complexity or composition;
3. the strongest NPC in the wave receives the red marker;
4. defeating the red elite ends the threat for that wave;
5. clearing a wave awards currency and upgrade materials.

The transition is intentionally gradual: the existing red-marker system becomes the elite-marker system instead of being thrown away.

## Stage 4 — Equipment Progression

Currency is used for:
- weapon upgrades;
- defensive upgrades;
- movement upgrades;
- ability upgrades;
- equipment rarity and variant paths.

Server owns all purchases and final stats.

## Stage 5 — Companion NPCs

Players can recruit increasingly capable NPC allies.

Companion progression:
- basic helper;
- ranged helper;
- melee helper;
- support helper;
- elite helper;
- specialist helpers unlocked through milestones.

Companions use server-owned targeting, pathfinding and combat state.

## Stage 6 — Long-Term Game

Add:
- persistent progression;
- missions;
- daily/weekly objectives;
- multiple maps;
- boss waves;
- free cosmetic skins;
- optional game passes/developer products that do not control core combat fairness.

## Stage 7 — Content Expansion

Add characters, weapons, bosses, visual effects and animation sets one controlled package at a time.

The rule for every future change is:

Research → design boundary → implement one system → static validation → build validation → live Roblox test → inspect → only then add the next system.
