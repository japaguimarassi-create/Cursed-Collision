# Animal corridor, family guardians, and treadmills — visual specification

## Reference review before implementation

We reviewed the official Steal An Egg listing and a public screenshot showing the treadmill. The official listing explicitly describes treadmill training, Speed gain, and treadmill/base upgrades: https://www.roblox.com/games/107778070777162/Steal-An-Egg. The screenshot used to assess visual hierarchy is https://eggipedia.com/images/sae/shots/tapis.webp.

Reference signals retained at a high level:
- low, dark running belt with strong luminous contrast;
- robust side rails and a small, readable console;
- a training loop that is obvious to a player without reading a manual;
- a distinction between accumulated speed points, training rate, upgrade level, and actual movement speed.

No source mesh, screenshot, map coordinates, branded treadmill, or packaged model is reused. The new treadmill is assembled from native Roblox Parts and uses a single server-side animation loop for belt stripes.

## Implemented behavior

- Eight personal farms in a rectangular 4 x 2 block.
- One animated treadmill on each farm, with a server-side TrainingZone.
- Speed points are awarded while the server verifies that the character is standing inside the belt zone. Standing still is enough, so players do not slide off the fixed training platform to earn Speed.
- The treadmill can be upgraded with in-game coins up to level 10.
- Training gain scales by a 1.5× level multiplier, rounded down to whole points per second.
- Movement speed follows a square-root curve and is clamped to 40 studs/s. Carrying an animal applies the existing weight penalty.
- An adult family guardian protects every stage; its chase speed rises with phase so early-stage escapes remain possible.
- Eight phases in order: hen, swan, wolf, crocodile, polar bear, lion, dragon, and whale.

## Visual test loop

After each structural change, check Luau parsing, server-authoritative movement rules, map dimensions and spawn positions, current HUD attributes, the no-monetization audit, and RBXL generation. A passing cloud build confirms the source and artifact generation, not a live Roblox Studio playtest.
