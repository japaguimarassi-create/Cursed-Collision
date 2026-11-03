# ANIMAL VISUAL COMPLEXITY PASS — 2026-11-03

## Scope

This pass deepens the eight flagship animal models inside `AnimalFactory.lua`. It keeps the procedural Roblox-native part workflow and does not replace the game with a static showcase.

## Geometry layers

- Crystalback Gecko: raised cheek scales, temple crystals, dorsal crystal crown, suction-pad toes and segmented tail bands.
- Bloomforged Beetle: antennae, glowing terminals, mandibles, abdomen plates, elytra veins and dorsal flower assembly.
- Rune-bill Bluejay: three additional feather rows, lower mandible, eye glints, wing rune stripes and crown runes.
- Astral Jackalope: layered cheek fur, jeweled antlers, hoof runes, a forehead star ring and moon crest.
- Spiritwood Panda: framed lanterns, canopy leaves, bark rings and firefly points.
- Novafox: layered tail roots, luminous tail tips, inner-ear glow, whiskers and a chest constellation.
- Starforged Sunlion: radial mane plates, whiskers, shoulder armor and crown gems.
- Verdant Sky Whale: gill engravings, fin ridges, belly plates and orbiting runes.

## Materials and rarity

The factory now exposes reusable crystal and emissive-part helpers. Each model stores a numeric `RarityTier` attribute. Mythic and higher models receive a segmented ground halo only at Teen/Adult stage or as a guardian. Secret, Eternal and Divine models additionally receive one Sparkles effect and one PointLight, with reduced intensity on ordinary pets.

## Mobile-conscious behavior

Common and young pets do not receive the rarity halo or lighting objects. Every generated part remains anchored and non-collidable under the existing factory finalization. No per-frame animation loop, particle storm or repeated light source was introduced.

## Validation boundary

The repository validator now checks the new material, anatomy and rarity tokens. This is a source-level regression check, not a Roblox physics/rendering test. Visual scale, overlap, mobile frame time and actual replicated effects still require a Studio playtest on a device before production publishing.
