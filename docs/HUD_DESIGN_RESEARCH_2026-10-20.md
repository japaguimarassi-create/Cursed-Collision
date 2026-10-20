# HUD Design Research — 2026-10-20

## Goal

Replace the previous oversized, card-heavy interface with an original, mobile-first HUD for **Steal An Animal**. The target play loop is capture, escape with the animal, deposit it, collect income, and train or upgrade the farm.

## References reviewed

1. Official Steal An Egg experience: https://www.roblox.com/games/107778070777162/Steal-An-Egg
2. Gameplay screenshot showing the Shop and Index controls, currency counters, and guardian encounter: https://games.gg/cdn-cgi/image/width%3D1920%2Cquality%3D75%2Cformat%3Dauto%2Cfit%3Dscale-down%2Cmetadata%3Dnone%2Conerror%3Dredirect/https%3A/assets.games.gg/steal_an_egg_sakura_incubator_guide_deltias_gaming_fded6ba159.webp
3. Roblox Creator Hub — adaptive-design guidance: https://create.roblox.com/docs/production/publishing/adaptive-design
4. Roblox Creator Hub — safe areas and mobile thumb zones: https://create.roblox.com/docs/ui/position-and-size
5. Roblox Creator Hub — mobile input and device adaptation: https://create.roblox.com/docs/input/mobile
6. Roblox Creator Hub — UI/UX, icon identity, grouping and visual hierarchy: https://create.roblox.com/docs/production/game-design/ui-ux-design
7. Roblox Creator Hub — ScreenGui and Core UI insets: https://create.roblox.com/docs/reference/engine/classes/ScreenGui
8. Roblox Developer Forum — minimal/simple UI discussion: https://devforum.roblox.com/t/ui-style-guide-series-minimalistic-simplistic/2578826
9. Roblox Developer Forum — icon-based simulator interface example: https://devforum.roblox.com/t/feedback-on-my-simulator-ui/1553479
10. Roblox Developer Forum — UI/UX portfolio with icon buttons: https://devforum.roblox.com/t/flipz-uiux-portfolio/1470833

## What the references suggest

- **Recognizable actions:** Shop and collection Index are visually distinct, icon-led controls; their labels should remain short.
- **Compact economy display:** coins, income, movement speed, farm capacity, and bank balance need a stable order and should be readable without opening a menu.
- **Gameplay stays dominant:** the corridor, animals, eggs, and guardian are the main scene. Persistent panels should occupy little space and avoid opaque, oversized backgrounds.
- **Context beats repetition:** the objective should change when the profile is loading, when the player has not captured an animal yet, and when they are carrying one.
- **Mobile-safe placement:** Roblox touch controls occupy the lower corners. The persistent menu is therefore kept above those zones, with no permanent bottom action dock.
- **Adaptive sizing:** use viewport-aware placement, size constraints, and CoreUI safe insets rather than assuming one screen resolution.
- **Consistent icon language:** use original, simple line shapes for the bag, book, and overflow menu; don't copy game-specific artwork or rely on undocumented asset IDs.
- **Progression stays available:** rebirth remains a small direct-access chip; less-frequent features live inside the scrollable More menu.

## Implemented visual direction

- Woodland/greenfield palette tuned to the bright outdoor map instead of the former blue-heavy panel palette.
- One compact, translucent resource strip with three aligned values and a restrained farm/bank footer.
- A single objective capsule with a small state marker. The escape state uses an orange cue; neutral progression uses green; loading uses muted color.
- Three compact icon-and-label buttons for Shop, Index, and More, placed away from the lower touch-control areas.
- Rebirth stays visible as a small badge rather than a full-width primary button.
- The old permanent bottom action dock and its dead hidden button instances are removed.
- Existing gameplay remotes, menu routes, reward systems, index data, and server-side validations remain the source of truth.

## Validation and limits

The GitHub Actions workflow parses Luau, runs the repository checks, builds the Rojo place, and validates the generated RBXL. These checks confirm syntax and project structure, not visual quality in a live session. The final layout still requires playtesting in Roblox Studio with mobile-device emulation and a real touch device at multiple aspect ratios.

Screenshots and forum posts are external examples and may show different game versions or design iterations. The implementation uses its own colors, shapes, and layout rather than embedding those screenshots or reusing their art assets.
