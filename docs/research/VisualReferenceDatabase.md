# Collision Battlestar — Visual Reference Database

Research date: 2026-09-26

## Design references

### VIS-001 — Urban combat readability
Source: Roblox Creator Hub — UI and UX design
URL: https://create.roblox.com/docs/production/game-design/ui-ux-design
Observed rule: visual hierarchy, contrast and consistent states keep vital information readable.
Implementation target: restrained HUD, clear action hierarchy and high-contrast combat feedback.

### VIS-002 — Safe-area HUD
Source: Roblox Creator Hub — Create HUD meters
URL: https://create.roblox.com/docs/tutorials/use-case-tutorials/ui/create-hud-meters
Observed rule: HUD elements should respect the safe area around device cutouts and platform UI.
Implementation target: ScreenInsets/CoreUISafeInsets and responsive scaling.

### VIS-003 — Controller navigation
Source: Roblox Creator Hub — GuiService
URL: https://create.roblox.com/docs/reference/engine/classes/GuiService
Observed rule: selectable GUI objects and selected-object navigation support gamepad interaction.
Implementation target: map control is selectable and receives initial gamepad focus.

### VIS-004 — Streaming city composition
Source: Roblox Creator Hub — Instance streaming
URL: https://create.roblox.com/docs/workspace/streaming
Observed rule: large worlds benefit from selective instance streaming.
Implementation target: long linear city with compact local combat zones and limited decorative density.

### VIS-005 — Battle Line spatial language
Internal design reference
Observed rule: seven named districts connected on one navigable spine.
Implementation target: Origin Plaza → Neon Strip → Iron Market → Collision Core → Skyline → Riftworks → Apex Yard.

### VIS-006 — Combat VFX
Internal design rule
Observed rule: impact direction must remain readable against urban geometry.
Implementation target: compact burst, expanding impact wave and short directional blade-beam with a hard effect cap.

### VIS-007 — Reality Break presentation
Internal design rule
Observed rule: world-state events need visible environmental feedback without hiding combat silhouettes.
Implementation target: short color pulse on tagged responsive environment parts and restrained local color correction.

## Performance rules

- Repeated props are low-poly and sparse.
- High-detail assets are reserved for a few hero slots.
- Effects are event-driven and bounded by `VFXDefinitions.Limits.MaxEffects`.
- Distant map content remains streamable.
- The map never depends on third-party asset loading to become playable.

## External asset policy

No third-party franchise characters, branded techniques, or copied proprietary UI art are runtime dependencies. External references are used only for generic composition and production research.
