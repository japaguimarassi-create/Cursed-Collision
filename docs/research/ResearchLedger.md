# Cursed Collision — Research Ledger

Research date: 2026-09-23

## Official Roblox / Luau references

### Animation markers
SOURCE: Roblox Creator Hub
URL: https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
TYPE: Official
TOPIC: AnimationTrack / markers / priority
OBSERVATION: AnimationTrack exposes Priority and marker-related runtime behavior.
TECHNICAL LESSON: Combat timing should be attached to authored animation markers; server gameplay must still validate the request.
IMPLEMENTATION IDEA: Client CombatHandler listens to GetMarkerReachedSignal("Hit") and requests the hit; server validates attack identity and timing window.
LEGAL/LICENSE NOTE: API documentation is technical guidance, not copied game code.
CONFIDENCE: High

### Input abstraction
SOURCE: Roblox Creator Hub
URL: https://create.roblox.com/docs/reference/engine/classes/UserInputService
TYPE: Official
TOPIC: PreferredInput / cross-platform input
OBSERVATION: PreferredInput identifies the input type Roblox considers primary and updates as the player's recent input changes.
TECHNICAL LESSON: Input routing should not hard-code a single device and should adapt dynamically.
IMPLEMENTATION IDEA: InputManager owns keyboard, gamepad and mouse bindings; HUD updates hints from PreferredInput.
LEGAL/LICENSE NOTE: Technical API reference.
CONFIDENCE: High

### Contextual actions
SOURCE: Roblox Creator Hub
URL: https://create.roblox.com/docs/reference/engine/classes/ContextActionService
TYPE: Official
TOPIC: ContextActionService / touch / gamepad
OBSERVATION: ContextActionService supports contextual input bindings and optional touch buttons; Roblox notes that custom ImageButton/TextButton interfaces provide more customization.
TECHNICAL LESSON: Use one action abstraction and keep a custom combat HUD for precise layout and accessibility.
IMPLEMENTATION IDEA: InputManager binds actions while HUDController owns presentation.
LEGAL/LICENSE NOTE: Technical API reference.
CONFIDENCE: High

### Client-server security
SOURCE: Roblox Creator Hub
URL: https://create.roblox.com/docs/scripting/security/client-server-boundary
TYPE: Official
TOPIC: RemoteEvent validation
OBSERVATION: Client-sent data must be validated before affecting game state.
TECHNICAL LESSON: Animation markers are presentation/timing signals; damage, cooldown and target selection remain server authority.
IMPLEMENTATION IDEA: M1Hit/SkillHit remotes carry only an opaque attack ID; the server owns hitboxes and damage.
LEGAL/LICENSE NOTE: Technical API reference.
CONFIDENCE: High

### Remote communication
SOURCE: Roblox Creator Hub
URL: https://create.roblox.com/docs/scripting/events/remote
TYPE: Official
TOPIC: RemoteEvent architecture
OBSERVATION: RemoteEvents are asynchronous one-way communication; UnreliableRemoteEvents are intended for continuously changing non-critical data.
TECHNICAL LESSON: Keep authoritative combat on reliable RemoteEvents and cosmetic presentation client-side.
IMPLEMENTATION IDEA: CombatAction is used for gameplay requests; CombatFX is used for replicated presentation signals.
LEGAL/LICENSE NOTE: Technical API reference.
CONFIDENCE: High

### Safe mobile UI
SOURCE: Roblox Creator Hub
URL: https://create.roblox.com/docs/pt-br/ui/on-screen-containers
TYPE: Official
TOPIC: ScreenGui / ScreenInsets
OBSERVATION: CoreUISafeInsets keeps interactive UI away from topbar controls and device cutouts.
TECHNICAL LESSON: Interactive combat controls should use safe insets instead of assuming a fixed screen.
IMPLEMENTATION IDEA: HUDController sets ScreenInsets = CoreUISafeInsets and uses proportional layout plus minimum sizes.
LEGAL/LICENSE NOTE: Technical API reference.
CONFIDENCE: High

### UI sizing
SOURCE: Roblox Creator Hub
URL: https://create.roblox.com/docs/ui/size-modifiers
TYPE: Official
TOPIC: UISizeConstraint
OBSERVATION: UISizeConstraint provides minimum and maximum bounds across screen sizes.
TECHNICAL LESSON: Mobile and wide-screen layouts need constraints in addition to scale-based sizing.
IMPLEMENTATION IDEA: Action buttons and identity panels receive explicit minimum/maximum dimensions.
LEGAL/LICENSE NOTE: Technical API reference.
CONFIDENCE: High

### Performance
SOURCE: Roblox Creator Hub
URL: https://create.roblox.com/docs/performance-optimization
TYPE: Official
TOPIC: profiling / memory / frame time
OBSERVATION: Roblox recommends measuring frame rate, memory, server heartbeat and load time, then iterating based on measured bottlenecks.
TECHNICAL LESSON: Avoid premature micro-optimization; profile actual hot paths.
IMPLEMENTATION IDEA: Keep UI refresh throttled, cache animations, and reserve per-frame work for presentation that truly requires it.
LEGAL/LICENSE NOTE: Technical API reference.
CONFIDENCE: High

### Streaming
SOURCE: Roblox Creator Hub
URL: https://create.roblox.com/docs/workspace/streaming
TYPE: Official
TOPIC: Instance streaming
OBSERVATION: Instance streaming dynamically loads/unloads 3D content and can improve join time, memory and performance.
TECHNICAL LESSON: A large city should be built with streaming in mind rather than assuming the full map is always resident.
IMPLEMENTATION IDEA: Keep combat-critical instances close to players and separate cosmetic/distant content.
LEGAL/LICENSE NOTE: Technical API reference.
CONFIDENCE: High

### Preloading
SOURCE: Roblox Creator Hub
URL: https://create.roblox.com/docs/reference/engine/classes/ContentProvider
TYPE: Official
TOPIC: ContentProvider / PreloadAsync
OBSERVATION: PreloadAsync is useful for essential assets; Roblox warns against preloading the entire Workspace.
TECHNICAL LESSON: Selective animation/UI preloading is preferred over bulk preloading.
IMPLEMENTATION IDEA: Animation cache only instantiates configured assets and future preloading should target spawn/menu assets.
LEGAL/LICENSE NOTE: Technical API reference.
CONFIDENCE: High

### Synchronized client/server time
SOURCE: Roblox Creator Hub
URL: https://create.roblox.com/docs/reference/engine/classes/Workspace/ModelStreamingBehavior
TYPE: Official
TOPIC: Workspace:GetServerTimeNow
OBSERVATION: Roblox exposes GetServerTimeNow() as a smoothed estimate of server Unix time for synchronized experiences.
TECHNICAL LESSON: Replicated cooldown presentation should not compare server os.clock() values to client os.clock().
IMPLEMENTATION IDEA: CooldownService stores server-time timestamps in replicated attributes; gameplay validation remains server-side.
LEGAL/LICENSE NOTE: Technical API reference.
CONFIDENCE: High

## JJS behavioral and visual references

### Core control layout
SOURCE: Roblox experience page
URL: https://www.roblox.com/games/9391468976/Jujutsu-Shenanigans
TYPE: Gameplay / product
TOPIC: Core battleground controls
OBSERVATION: The current experience description lists M1, 1–4 skills, Q dash, F block, R special, W+W sprint and G awaken.
TECHNICAL LESSON: The control vocabulary maps naturally to a compact battleground HUD.
IMPLEMENTATION IDEA: Cursed Collision keeps the same broad action categories but uses its own layout, labels and mappings.
LEGAL/LICENSE NOTE: Used only as behavioral reference; no assets or code copied.
CONFIDENCE: High

### Mobile action hierarchy
SOURCE: Pro Game Guides
URL: https://progameguides.com/roblox/all-controls-in-jujutsu-shenanigans-roblox/
TYPE: Gameplay guide
TOPIC: Mobile controls
OBSERVATION: The guide describes dedicated mobile controls for block, basic melee, jump, dash, special, four skills, awakening and movement.
TECHNICAL LESSON: Combat controls must remain reachable without relying on a keyboard.
IMPLEMENTATION IDEA: Cursed Collision uses large touch targets and preserves the four-skill bottom bar with a separate action cluster.
LEGAL/LICENSE NOTE: Visual/behavioral reference only.
CONFIDENCE: Medium

### Current JJS control guide
SOURCE: Jujutsu Shenanigans Wiki community guide
URL: https://jujutsushenaniganswiki.wiki/pt-br/combat/controls/
TYPE: Community
TOPIC: PC/mobile/console controls
OBSERVATION: The guide was updated 2026-09-16 and documents platform-specific control layouts and contextual states.
TECHNICAL LESSON: Device-aware input hints are useful because control roles can remain constant even when bindings differ.
IMPLEMENTATION IDEA: HUDController changes key hints according to PreferredInput.
LEGAL/LICENSE NOTE: Community reference.
CONFIDENCE: Medium

## Visual reference index

The current image-query pass returned representative references rather than the requested 2000-image corpus. The available tool does not expose a bulk 2000-record export in one operation, so this ledger records the verified sample and keeps it separate from technical evidence.

- A/HUD + skills: https://image.thenerdstash.com/2024/04/Jujutsu-Shenanigans-Special-Ability.jpg
- B/Mobile HUD: https://i.axod.net/pcbq6L2SwIcDbfCMZld_NbXlsZMolPKtwgTtCfj_aWFsxio7Ip0PFCle51hz556JhBHoCH8BvNEtacXqLOGXAlcD58doPnKP1IXXVSLs6IMoE0qJBvQhBU-lxNJdKj1CrEOCNGShPih1nzwO2NcZkxre0-OsWA.jpeg
- C/City + combat presentation: https://progameguides.com/wp-content/uploads/2024/11/featured-jujutsu-shenanigans-all-secret-moves.jpg
- D/Awakening presentation: https://staticg.sportskeeda.com/editor/2025/02/06549-17398621394275-1920.jpg
- E/VFX combat presentation: https://staticg.sportskeeda.com/editor/2025/02/3d000-17398639787244-1920.jpg
- F/UI/menu/emote wheel pattern reference: https://cdn-offer-photos.zeusx.com/b9d5d102-e73c-43b4-85d0-25fb56f8868a.jpg

Visual notes: use these as composition/readability references only. They are not implementation assets for Cursed Collision.

### Implementation checkpoint — 2026-09-23
SOURCE: Cursed Collision implementation branch
TYPE: Internal engineering checkpoint
OBSERVATION: Combat M1/skills/Special now use server-owned marker windows; client animation markers only request resolution.
TECHNICAL LESSON: The client never directly applies damage; CombatMarkerService validates token, timing window and travel origin before the server callback executes.
HUD LESSON: ScreenInsets, responsive scaling, touch sizing and gamepad selection are centralized in the modular HUD layer.
EMOTE LESSON: Emotes stop on movement, damage, stun, ragdoll and combat-state attributes and use cached tracks when an asset ID is configured.
STATUS: Implemented; CI/static validation required; live Roblox device testing remains outstanding.

### Fresh platform/UI research — 2026-09-23
SOURCE: Roblox Creator Hub — Create HUD meters
URL: https://create.roblox.com/docs/tutorials/use-case-tutorials/ui/create-hud-meters
OBSERVATION: Roblox recommends safe-area handling with ScreenInsets for device cutouts and the Roblox top bar; Device Emulator is the documented route for multi-device UI validation.
IMPLEMENTATION: Cursed Collision uses ScreenInsets/CoreUISafeInsets plus responsive short-axis scaling and minimum touch button constraints.

SOURCE: Roblox Creator Hub — Console development guidelines
URL: https://create.roblox.com/docs/production/publishing/console-guidelines
OBSERVATION: TV-safe areas, scalable UI and controller navigation are required considerations for console UI.
IMPLEMENTATION: Cursed Collision enables GuiNavigationEnabled and SelectedObject for gamepad focus and keeps key controls inside the responsive HUD composition.

SOURCE: Roblox Creator Hub — AnimationTrack
URL: https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
OBSERVATION: AnimationTrack exposes Priority and GetMarkerReachedSignal.
IMPLEMENTATION: CombatHandler listens for the exact Hit marker; server CombatMarkerService validates the attack before hitbox/damage execution.

SOURCE: Jujutsu Shenanigans official Roblox page
URL: https://www.roblox.com/games/9391468976/Jujutsu-Shenanigans
OBSERVATION: The public description documents a compact battleground input model centered on M1, 1–4 skills, dash, block, special, sprint and awaken.
IMPLEMENTATION: Cursed Collision mirrors the interaction hierarchy while using original code/assets and its own character/moveset data.

SOURCE: Jujutsu Shenanigans visual references (third-party screenshots)
URL: https://thenerdstash.com/how-to-use-special-abilities-in-roblox-jujutsu-shenanigans/
URL: https://www.sportskeeda.com/roblox-news/jujutsu-shenanigans-guide
OBSERVATION: Screenshots show a restrained lower-center four-skill rail and a separate action/control hierarchy around the combat view.
IMPLEMENTATION: Cursed Collision uses a four-skill rail, central power meter, top identity/status, and right-side mobile action cluster.
