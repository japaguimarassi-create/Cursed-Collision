# Collision Battlestar — Research Ledger

Research date: 2026-09-26

## Repository and architecture

- The Rojo manifest is the single runtime source of truth and maps only `src/CollisionBattlestar/*`.
- The active tree is franchise-free and contains no character, technique, or brand terms owned by third parties.
- The legacy source tree is removed from the repository in this production pass so it cannot be accidentally added to the manifest.
- Server authority remains the rule for combat, rewards, persistence, destruction, and travel validation.

## Roblox technical sources

### Client-server security
SOURCE: Roblox Creator Hub — Client-server boundary
URL: https://create.roblox.com/docs/scripting/security/client-server-boundary
TYPE: Official
OBSERVATION: Client data must be validated before it affects server-owned game state.
IMPLEMENTATION: CombatRequest, GamePassRequest and MapTravelRequest are validated on the server.

### Remote events
SOURCE: Roblox Creator Hub — Remote events and callbacks
URL: https://create.roblox.com/docs/scripting/events/remote
TYPE: Official
OBSERVATION: RemoteEvents are asynchronous one-way communication; critical gameplay remains on reliable remotes.
IMPLEMENTATION: Combat and travel use RemoteEvents; visual effects remain client presentation.

### Streaming
SOURCE: Roblox Creator Hub — Instance streaming
URL: https://create.roblox.com/docs/workspace/streaming
TYPE: Official
OBSERVATION: Instance streaming dynamically loads/unloads 3D content to reduce memory and load pressure.
IMPLEMENTATION: Battle Line uses StreamingEnabled with a bounded target radius.

SOURCE: Roblox Creator Hub — Player:RequestStreamAroundAsync
URL: https://create.roblox.com/docs/reference/engine/classes/Player
TYPE: Official
OBSERVATION: The server can request that a region around a destination be streamed before moving a character.
IMPLEMENTATION: MapTravelService requests the destination region before PivotTo.

### Pivot and movement
SOURCE: Roblox Creator Hub — PVInstance
URL: https://create.roblox.com/docs/reference/engine/classes/PVInstance
TYPE: Official
OBSERVATION: PivotTo moves a model as a unit.
IMPLEMENTATION: Fast travel uses Character:PivotTo after stream preparation.

### Attributes
SOURCE: Roblox Creator Hub — Attributes
URL: https://create.roblox.com/docs/pt-br/scripting/attributes
TYPE: Official
OBSERVATION: Attributes replicate and are useful for synchronized lightweight state.
IMPLEMENTATION: Momentum, Instability, map node, world state and asset status use attributes.

### Animation
SOURCE: Roblox Creator Hub — AnimationTrack
URL: https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
TYPE: Official
OBSERVATION: AnimationTrack supports Play, AdjustWeight, Priority and marker signals.
IMPLEMENTATION: AnimationClient uses cached tracks with cross-fade and keeps the existing Motor6D procedural fallback.

SOURCE: Roblox Creator Hub — Create character animations
URL: https://create.roblox.com/docs/tutorials/use-case-tutorials/animation/create-an-animation
TYPE: Official
OBSERVATION: Publishing an animation creates the asset ID that scripts can reference.
IMPLEMENTATION: No unknown animation IDs are hard-coded. The 12 slots remain on fallback until a direct public ID is independently verified.

### Rig
SOURCE: Roblox Creator Hub — Rig Generator
URL: https://create.roblox.com/docs/studio/rig-builder
TYPE: Official
OBSERVATION: Roblox supports R6 and R15 rigs; the selected rig changes available joints and motion.
IMPLEMENTATION: The active project does not pin a rig type in source configuration. AnimationClient records Humanoid.RigType at runtime and uses joint-name fallback logic.

### Audio
SOURCE: Roblox Creator Hub — Audio assets
URL: https://create.roblox.com/docs/audio/assets
TYPE: Official
OBSERVATION: The Creator Store contains free-to-use audio; imported audio needs permission and passes moderation.
IMPLEMENTATION: Sound 9075325599 is used because its Creator Store listing is explicitly marked free to use. No unverified SoundIds are added.

SOURCE: Roblox Creator Hub — Sound
URL: https://create.roblox.com/docs/sound
TYPE: Official
OBSERVATION: Sound objects use unique asset IDs and become positional when parented to a 3D object.
IMPLEMENTATION: Combat impact audio is emitted from a temporary invisible 3D source at the reported hit position.

### UI
SOURCE: Roblox Creator Hub — UI and UX design
URL: https://create.roblox.com/docs/production/game-design/ui-ux-design
TYPE: Official
OBSERVATION: Visual hierarchy, consistent states and player feedback improve clarity.
IMPLEMENTATION: Collision Battlestar HUD uses consistent state labels, bounded panels and direct feedback.

## Map and asset research

### Verified free Roblox Creator Store props

1. Bench — asset 400850371
SOURCE: https://create.roblox.com/store/asset/400850371/Bench
LICENSE/RIGHTS: Listing explicitly says it is a free bench model.
SIZE: 228 triangles / 456 vertices.
RUNTIME USE: low-cost seating in Neon Strip and Skyline.

2. Dumpster -Free- — asset 42942436
SOURCE: https://create.roblox.com/store/asset/42942436
LICENSE/RIGHTS: Free designation in the published listing title.
SIZE: 82 triangles / 164 vertices.
RUNTIME USE: alley clutter in Iron Market and Riftworks.

3. Bus Stop [FREE!] — asset 4987899016
SOURCE: https://create.roblox.com/store/asset/4987899016/Bus-Stop-FREE
LICENSE/RIGHTS: Explicit FREE designation in the published listing.
SIZE: 1,432 triangles / 2,372 vertices / 2 decals.
RUNTIME USE: one hero transport stop in Origin Plaza.

4. Bus Stop Sign [FREE] — asset 8673868211
SOURCE: https://create.roblox.com/store/asset/8673868211/Bus-Stop-Sign-FREE
LICENSE/RIGHTS: Explicit FREE designation.
SIZE: 14 triangles / 28 vertices / 1 decal.
RUNTIME USE: route signage near Collision Core.

5. Bus Stop Pole — asset 18143058886
SOURCE: https://create.roblox.com/store/asset/18143058886/Bus-Stop-Pole
LICENSE/RIGHTS: Listing description explicitly says it is free.
SIZE: 648 triangles / 826 vertices / 2 decals.
RUNTIME USE: route signage near Collision Core.

6. [FREE] Car Showcase — asset 5157346970
SOURCE: https://create.roblox.com/store/asset/5157346970/FREE-Car-Showcase
LICENSE/RIGHTS: Explicit FREE designation in the listing title.
SIZE: 2,120 triangles / 3,550 vertices / 4 decals.
RUNTIME USE: two sparse hero parked-car props at map endpoints.

7. Free R6 battleground animations (v7) — model asset 16663903306
SOURCE: https://create.roblox.com/store/asset/16663903306/Free-R6-battleground-animations-v7
LICENSE/RIGHTS: Listing states it is open source, permits use in battleground games and monetization, and prohibits selling the animations themselves.
SIZE: 1,066 triangles / 727 vertices.
CONTENT: 4-hit basic combo, downslam, uppercuts, walk/run and front/back/side dashes.
LIMITATION: The public listing exposes the source model ID, not the individual contained animation asset IDs. The project therefore does not copy unknown numeric IDs into AnimationDefinitions.

### Free animation source outside Roblox

SOURCE: Adobe Mixamo FAQ
URL: https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
LICENSE/RIGHTS: Adobe states Mixamo characters and animations can be used royalty-free in personal, commercial and non-profit projects, subject to its restrictions on redistributing raw assets.
RUNTIME USE: valid source for future authored/imported clips after the owner publishes the resulting Roblox animations.
LIMITATION: Mixamo does not provide Roblox AnimationIds directly.

### CC0 asset libraries

SOURCE: Kenney — City Kit (Commercial)
URL: https://kenney.nl/assets/city-kit-commercial
LICENSE: Creative Commons CC0
SIZE: 50 files.
USE: source material for custom imported urban props and modular building decisions.

SOURCE: Kenney — City Kit (Suburban)
URL: https://kenney.nl/assets/city-kit-suburban
LICENSE: Creative Commons CC0
SIZE: 40 files.
USE: secondary city detail reference/source.

SOURCE: Kenney — City Kit (Roads)
URL: https://kenney.nl/assets/city-kit-roads
LICENSE: Creative Commons CC0
SIZE: 90 files.
USE: road/signage source material.

SOURCE: Kenney — City Kit (Industrial)
URL: https://kenney.nl/assets/city-kit-industrial
LICENSE: Creative Commons CC0
SIZE: 40 files.
USE: industrial/Riftworks source material.

SOURCE: Kenney — Impact Sounds
URL: https://kenney.nl/assets/impact-sounds
LICENSE: Creative Commons CC0
SIZE: 130 files.
USE: source for future imported impact audio.

SOURCE: Kenney — Interface Sounds
URL: https://kenney.nl/assets/interface-sounds
LICENSE: Creative Commons CC0
SIZE: 100 files.
USE: source for future UI audio.

## Production findings recorded during the 2026-09-26 audit

- Fast travel checked a non-existent `Blocking` attribute while combat uses `IsBlocking`; this was corrected.
- Battle Streak waves used stale coordinates unrelated to the rebuilt Apex Yard; wave spawning now derives its center from the runtime BattleStreakArena.
- Movement only bound PlayerAdded and could miss players when initialized after them; current players are now bound too.
- Light combo state did not overwrite LastAction, so a dash could incorrectly influence several later light attacks; this was corrected.
- UI notification tasks could hide newer notifications; a serial guard now prevents that race.
- WorldStateService and WorldPresentationService both wrote Lighting.ClockTime; WorldStateService no longer owns presentation lighting.
- DestructionService exposed RestoreSeconds attributes but ignored them; restore duration now honors the attribute.
- AudioController was metadata-only; it now has a real positional sound path using a verified free asset.
- MapDecorationService previously ignored MapAssetCatalog and MapAssetLoader; it now asynchronously loads a small verified-prop set while preserving procedural fallback.
- Reality Break now produces bounded local environment color response through tagged responsive parts and a shared effect budget.
- The active runtime does not contain the old external animation/VFX controller modules referenced by the legacy tree; their proprietary content is not reintroduced. The active AnimationClient/VFXController were extended instead.

## Validation and live-test limits

Static validation can prove source structure, syntax, references, contracts and Rojo packaging. It cannot prove visual quality, collision feel, stream pop-in, audio loudness or sustained mobile frame time without a live Roblox client/device test.
