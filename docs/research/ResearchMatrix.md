# Collision Battlestar — Research Matrix

| System | Source | Current implementation | Status |
|---|---|---|---|
| Combat | Roblox client-server security + spatial-query docs | Server-authoritative requests, cooldowns, state validation, spatial hitboxes | Implemented |
| Animation | AnimationTrack + animation publishing docs | Cached tracks, cross-fade, runtime rig detection, procedural Motor6D fallback | Implemented with public-ID limitation |
| Input | UserInputService / GuiService docs | Keyboard, touch and gamepad-compatible action requests | Implemented |
| HUD | UI/UX + safe-area docs | Responsive HUD, safe-area placement, route map, shop, progression | Implemented foundation |
| Audio | Roblox Audio assets + Sound docs | Positional free Creator Store impact sound | Implemented; one verified runtime ID |
| Map | Streaming docs | Seven-zone Battle Line, one-place fast travel | Implemented |
| Map assets | Creator Store free listings | Optional hero props via AssetService with procedural fallback | Implemented |
| VFX | Client presentation architecture | Bounded bursts, impact waves, blade beams, Reality Break environment pulse | Implemented |
| Camera | RunService/camera presentation | Event-light FOV adaptation | Implemented foundation |
| Persistence | DataStore docs | Session lock, normalization, autosave, release | Implemented foundation |
| Missions | Server event + persistence architecture | First Response quest | Implemented foundation |
| Battle Streak | Server-authoritative enemy ownership | Wave loop, dynamic Apex center, rewards | Implemented |
| Reality Break | WorldState + presentation separation | World state drives presentation; event sequence remains server-owned | Implemented |
| Game passes | Roblox Game Pass APIs | Server ownership checks and purchase prompts | Implemented |
| Domain systems | Internal design plan | No external-franchise implementation | Future gameplay scope |
