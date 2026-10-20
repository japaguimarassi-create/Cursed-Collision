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

## Implemented visual direction (rebuild)

- The Shop and Index actions use large, highly differentiated green/blue touch buttons on the left, matching the visual hierarchy seen in Steal An Egg screenshots without importing the original UI assets.
- Currency, passive income and speed occupy a transparent, compact lower-left panel; farm capacity and bank balance remain one line below it.
- The contextual objective remains centered near the top. The rebirth chip and BotX status chip stay in the upper-right.
- The BotX chip opens Diagnostics and requests a fresh server status. The panel reports live NPC count, modes, positions and session event counts instead of only server-output messages.
- Currency placement adapts to the viewport and leaves the lowest touch-control zone free; tap targets remain at least 44 pixels in the modeled smallest supported scale.
- Existing gameplay remotes, menu routes, reward systems, animal index and server-side validations remain authoritative.

## Validation and limits

The GitHub Actions workflow parses Luau, runs the repository checks, builds the Rojo place, and validates the generated RBXL. These checks confirm syntax and project structure, not visual quality in a live session. The source-based CI layout model checks phone portrait, landscape, tablet and desktop sizes. That is not a substitute for visual inspection in the actual Roblox engine; live appearance and BotX runtime state still need to be observed in-game.

Screenshots and forum posts are external examples and may show different game versions or design iterations. The implementation uses its own colors, shapes, and layout rather than embedding those screenshots or reusing their art assets.
