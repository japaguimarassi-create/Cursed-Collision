# Collision Battlestar — Modern Roblox HUD Research

Date: 2026-09-26

## Market observations

A September 2026 live snapshot showed large Roblox experiences spanning roleplay/avatar simulation, RPG, shooter, survival, action and simulation. Current live trackers put Brookhaven, Blox Fruits, Murder Mystery 2, RIVALS, Ride A Pet, Jujutsu Shenanigans, Slayers 2, 99 Nights in the Forest and other high-concurrency experiences near the top, while another hourly tracker listed Brookhaven, Blox Fruits, RIVALS, 99 Nights in the Forest, Murder Mystery 2, Adopt Me, Fish It!, Jujutsu Shenanigans, Pet Simulator 99 and Fisch among the leading experiences.

Sources:
- https://rokoala.com/roblox-player-count/
- https://robipedia.com/topic/most-players
- https://www.bloxquiz.gg/stats/most-played

## HUD design decisions

Collision Battlestar is an open combat experience, so the HUD borrows only broad current Roblox interaction conventions rather than the visual language of any single game.

Permanent layer:
- compact player identity card
- HP and CE meters
- current district and server-verification status
- KO count and market/menu controls
- small ping indicator
- one active mission chip
- compact combat feed
- four core combat actions
- awakening/domain controls

Secondary layer:
- fighters
- map
- missions
- profile
- market
- server player list
- settings

No emote UI is active in the build.

## Mobile rules

Roblox documentation states that mobile has the least available screen space, that reserved zones exist around default controls, and that frequently used controls should remain within comfortable thumb zones. The new HUD therefore keeps essential actions clustered on the right-middle/lower-right while avoiding the extreme corner occupied by core Roblox controls.

References:
- https://create.roblox.com/docs/pt-br/input/mobile
- https://create.roblox.com/docs/pt-br/ui/on-screen-containers
- https://create.roblox.com/docs/pt-br/position-and-size
- https://create.roblox.com/docs/reference/engine/enums/ScreenInsets

## Visual system

The HUD intentionally avoids recreating JJS or TSB. It uses a neutral dark card system with:
- rounded surfaces
- sparse strokes
- compact typography
- information hierarchy
- icon-like text tokens instead of external icon dependencies
- responsive UIScale
- safe-area positioning
- contextual panels instead of permanent menu clutter

Roblox's UI/UX documentation emphasizes that UI should communicate essential information and that context-based UI is useful when screen space is constrained.

Reference:
- https://create.roblox.com/docs/production/game-design/ui-ux-design
- https://create.roblox.com/docs/tutorials/use-case-tutorials/ui/create-hud-meters

## Scope

The HUD is a full replacement of the previous v4 layout. The gameplay action vocabulary remains:
M1, Dash, Block, Special, Awakening and Domain.

Emotes are intentionally removed from the active catalog and interface.
