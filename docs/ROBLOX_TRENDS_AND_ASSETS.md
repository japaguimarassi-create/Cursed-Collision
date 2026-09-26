# Collision Battlestar — Roblox trend and asset research

Updated 2026-09-26

## Current design response

Collision Battlestar combines a continuous urban combat map with repeatable wave combat. The current foundation emphasizes:
- one-place Battle Line traversal;
- fast combat loop with M1, Heavy, Block, Parry, Dash, Special and Overdrive;
- Momentum / Instability as a reusable combat resource model;
- Battle Streak as a repeatable wave activity;
- Reality Break as a timed world-state event;
- responsive touch, keyboard and gamepad input;
- low-cost city geometry with streaming.

## Creator Store policy

Roblox's Creator Store provides free-to-use assets as well as paid assets. Every runtime asset selected for Collision Battlestar must have an explicit usable-rights signal or come from a clearly documented permissive source.

Selected free runtime props:
- Bench 400850371 — 228 tris
- Dumpster 42942436 — 82 tris
- Bus Stop 4987899016 — 1,432 tris
- Bus Stop Sign 8673868211 — 14 tris
- Bus Stop Pole 18143058886 — 648 tris
- Car Showcase 5157346970 — 2,120 tris

High-density city kits remain source material rather than automatic runtime imports. A city kit can be technically free while still being too dense for repeated use on a mobile-first map.

## Asset-loading rule

The default map is generated procedurally. MapAssetLoader adds a small optional hero-prop pass after the default geometry exists. This avoids making gameplay depend on third-party loading availability.

## Visual language

Keep the city's combat spaces open enough for readable hit reactions. Use a small number of tall landmarks for orientation and keep route signage consistent with the Battle Line node names.

External franchise references are not runtime dependencies and are excluded from the active project content.
