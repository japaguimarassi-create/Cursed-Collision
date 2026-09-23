# Cursed Collision — Research Ledger

Date: 2026-09-23

## Architecture decisions

### Remote security
SOURCE: Roblox Creator Hub — Securing the client-server boundary
URL: https://create.roblox.com/docs/scripting/security/client-server-boundary
TYPE: Official
TOPIC: Remote validation and server authority
OBSERVATION: Roblox explicitly recommends validating every piece of client-sent data, checking context/permissions, and rate-limiting remotes.
TECHNICAL LESSON: Client requests are untrusted input; the server must decide gameplay outcomes.
IMPLEMENTATION IDEA: CombatMarkerService accepts only a server-created attack ID and only inside a server-defined timing window, then performs the hitbox query on the server.
LEGAL/LICENSE NOTE: Official documentation.
CONFIDENCE: High
STATUS: DOCUMENTED → IMPLEMENTED

### Remote delivery
SOURCE: Roblox Creator Hub — Remote events and callbacks
URL: https://create.roblox.com/docs/scripting/events/remote
TYPE: Official
TOPIC: RemoteEvents and one-way replication
OBSERVATION: RemoteEvents support asynchronous client/server messages; UnreliableRemoteEvents are intended for continuously changing non-critical data.
TECHNICAL LESSON: Critical combat results remain on reliable RemoteEvents; cosmetic presentation can be replicated as compact event payloads.
LEGAL/LICENSE NOTE: Official documentation.
CONFIDENCE: High
STATUS: DOCUMENTED → IMPLEMENTED

### Input abstraction
SOURCE: Roblox Creator Hub — UserInputService / ContextActionService
URL: https://create.roblox.com/docs/reference/engine/classes/UserInputService
URL: https://create.roblox.com/docs/reference/engine/classes/ContextActionService
TYPE: Official
TOPIC: Mobile and gamepad compatibility
OBSERVATION: PreferredInput reports the primary input type; ContextActionService supports contextual keyboard, gamepad and touch bindings, while Roblox notes that custom on-screen buttons are often preferable when more UI customization is required.
TECHNICAL LESSON: Keep gameplay actions abstracted from device-specific input and use custom touch UI for the combat HUD.
LEGAL/LICENSE NOTE: Official documentation.
CONFIDENCE: High
STATUS: DOCUMENTED → IMPLEMENTED

### Safe-area UI
SOURCE: Roblox Creator Hub — Create HUD meters / ScreenInsets
URL: https://create.roblox.com/docs/tutorials/use-case-tutorials/ui/create-hud-meters
TYPE: Official
TOPIC: Mobile safe areas and top bar
OBSERVATION: ScreenInsets controls the safe area used by ScreenGui descendants, accounting for device cutouts and Roblox top-bar controls.
TECHNICAL LESSON: Combat HUD uses CoreUISafeInsets and responsive scaling instead of fixed pixel placement.
LEGAL/LICENSE NOTE: Official documentation.
CONFIDENCE: High
STATUS: DOCUMENTED → IMPLEMENTED

### Gamepad navigation
SOURCE: Roblox Creator Hub — GuiService
URL: https://create.roblox.com/docs/reference/engine/classes/GuiService
TYPE: Official
TOPIC: Selectable controls and navigation
OBSERVATION: GuiService exposes GuiNavigationEnabled and SelectedObject for controller-driven UI navigation.
TECHNICAL LESSON: Combat buttons are Selectable and gamepad navigation is enabled when PreferredInput is Gamepad.
LEGAL/LICENSE NOTE: Official documentation.
CONFIDENCE: High
STATUS: DOCUMENTED → IMPLEMENTED

### Animation markers
SOURCE: Roblox Creator Hub — AnimationTrack
URL: https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
TYPE: Official
TOPIC: Hit timing
OBSERVATION: AnimationTrack exposes GetMarkerReachedSignal for named animation markers.
TECHNICAL LESSON: M1 and skill animation tracks use a Hit marker. The client can notify the server that the authored animation reached the marker, but the server validates timing and computes the hitbox.
LEGAL/LICENSE NOTE: Official documentation.
CONFIDENCE: High
STATUS: DOCUMENTED → IMPLEMENTED

### Render-loop cleanup
SOURCE: Roblox Creator Hub — RunService
URL: https://create.roblox.com/docs/reference/engine/classes/RunService
TYPE: Official
TOPIC: Render/update loops
OBSERVATION: BindToRenderStep is client-only and should be unbound when no longer needed.
TECHNICAL LESSON: Long-lived controllers are kept bounded; cooldown UI updates are throttled rather than requiring combat logic on every render step.
LEGAL/LICENSE NOTE: Official documentation.
CONFIDENCE: High
STATUS: DOCUMENTED → IMPLEMENTED

### Spatial validation
SOURCE: Roblox Creator Hub — Raycasting / spatial queries
URL: https://create.roblox.com/docs/workspace/raycasting
TYPE: Official
TOPIC: Server hit detection
OBSERVATION: Roblox provides filtered spatial queries and RaycastParams for controlled world queries.
TECHNICAL LESSON: Server hitbox code owns positional validation; client never supplies target damage or hit position.
LEGAL/LICENSE NOTE: Official documentation.
CONFIDENCE: High
STATUS: DOCUMENTED → IMPLEMENTED

### Physics security
SOURCE: Roblox Creator Hub — Network ownership
URL: https://create.roblox.com/docs/physics/network-ownership
TYPE: Official
TOPIC: Physics authority
OBSERVATION: Client-owned physics are responsive but cannot be fully trusted for gameplay-critical decisions.
TECHNICAL LESSON: Gameplay-critical combat validation does not rely on client Touched events.
LEGAL/LICENSE NOTE: Official documentation.
CONFIDENCE: High
STATUS: DOCUMENTED → IMPLEMENTED

### Data persistence
SOURCE: Roblox Creator Hub — Data stores
URL: https://create.roblox.com/docs/cloud-services/data-stores
TYPE: Official
TOPIC: Persistence
OBSERVATION: UpdateAsync defines atomic data updates through a callback that cannot yield.
TECHNICAL LESSON: Future persistent transaction paths must keep DataStore update callbacks pure and non-yielding.
LEGAL/LICENSE NOTE: Official documentation.
CONFIDENCE: High
STATUS: DOCUMENTED → IMPLEMENTED

## Visual research

The available image-query tooling returns a bounded sample rather than an exhaustive archive. A literal 2000-image corpus was not available through this tool surface in this run, so the visual database records representative captures and community discussion references instead of claiming 2000 collected assets.

Key visual observations:
- JJS presents a compact combat bar centered near the bottom of the screen with four character abilities.
- Current/community captures show a top navigation cluster for Characters/Shop/Settings/Inventory/Emotes and a responsive variation on mobile.
- Community settings references emphasize UI scaling, screen-shake toggles and control customization.
- Gameplay captures emphasize high-contrast impact VFX against relatively simple urban geometry, making hit feedback readable.
- Community mobile-layout discussion shows that touch reachability and button spacing materially affect combat ergonomics.

Implementation rule:
OBSERVED visual structure is treated as design inspiration only.
DOCUMENTED API behavior is used for technical decisions.
No proprietary JJS code or assets are copied.

Representative image references are in docs/visual-reference-database.md.
