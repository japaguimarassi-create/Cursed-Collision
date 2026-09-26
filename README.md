# COLLISION BATTLESTAR

Where Worlds Collide.

Collision Battlestar is the active Roblox project in this repository. The Rojo manifest points exclusively to the Collision Battlestar runtime.

## Current vertical slice

- Battle Line continuous urban world with five connected districts
- M1, Dash, Block, Parry, Special and Overdrive
- server-authoritative combat, travel, rewards and persistence
- mobile, keyboard and gamepad input
- responsive combat HUD with cooldowns and resource meters
- procedural combat animation fallback plus real AnimationTrack profiles
- priority-based animation blending with deterministic per-player style sets
- bounded combat VFX with impact waves and camera feedback
- public Creator Store hero props loaded on a best-effort sanitized path

## Animation pass

The runtime now contains two small animation sets rather than replacing every movement state at once.

The Vanguard set uses three public battleground combo clip IDs and an official Roblox kick example for the Special slot:
- 18576726303
- 18576729183
- 18576731629
- 2515090838

The Impact set mixes a publicly posted punch clip with the battleground combo clips and the same official kick example:
- 17866759652
- 18576729183
- 18576731629
- 2515090838

Animation loading is guarded with PreloadAsync and pcall. If Roblox denies or cannot load an external animation asset, the track is discarded and the existing procedural pose fallback takes over. Action tracks use higher AnimationPriority than locomotion, and equal-priority blending is supported through AnimationTrack weight controls.

## Asset policy

No copyrighted franchise characters, techniques or copied proprietary runtime assets are included.

External animation IDs are treated as optional runtime candidates, not as guaranteed permissions. Any animation that cannot be loaded by Roblox in the experience automatically falls back to the procedural system.

## Build pipeline

The project uses a Rojo source-of-truth manifest, GitHub Actions validation and a manual Roblox publication workflow. Static validation and Roblox acceptance do not replace live device testing for visual quality, combat feel, animation compatibility, streaming behavior or sustained mobile frame rate.
