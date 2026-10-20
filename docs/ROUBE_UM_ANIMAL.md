# STEAL AN ANIMAL — Fresh Build

## Game loop

Spawn at a personal farm, enter one of six biomes, hold the ROUBAR prompt on a wild baby animal, and bring it home. Carrying heavier animals slows movement. A giant guardian can pursue anyone carrying prey; if it catches the player, the carried animal escapes. At the player's own farm, the GUARDAR prompt stores the animal and starts its passive income.

## Animal evolution

All stored animals start at **BEBÊ**. Their stage is derived from their saved birth timestamp, so evolution continues while the player is offline.

| Stage | Age | Income multiplier |
| --- | ---: | ---: |
| Baby | 0–119 seconds | 1× |
| Child | 120–299 seconds | 1.5× |
| Teen | 300–539 seconds | 2.25× |
| Adult | 540 seconds onward | 3.375× |

Every transition increases the animal's income by 50% over the previous stage. A species with a base income of 10 coins/second therefore earns 10, 15, 22.5, and 33.75 coins/second across the four stages; the runtime floors fractional coin grants when crediting whole coins.

## World and models

The map is assembled from native Roblox parts during server startup. The hub contains eight personal farm plots, a fountain, and a wide return route. Six biome areas use distinct ground materials, accent colors, entry arches, signs, crystals, trees, flowers, and rock formations. The visual system is built from original part compositions rather than copied meshes or unreviewed Toolbox scripts.

Animal models use procedural body, head, muzzle, eyes, ears, legs, tails, wings, horns, shells, tusks, and species accents. Model scale follows the animal's current life stage. The guardian variants use the same species palette at a much larger scale.

## Persistence and server validation

Profiles contain coins, speed level, barn bank, stored animal IDs, birth timestamps, and the last income timestamp. UpdateAsync persists the profile. Offline income is capped at six hours and calculated across stage transitions rather than applying an adult rate to the entire offline period. If a DataStore load fails, the temporary profile is not written back over the unknown saved data.

The reviewed r3 build corrects the profile-sanitization syntax and wild-animal ground alignment. The server validates capture targets, one-animal carry limits, farm ownership, barn capacity, collection distance, upgrade cost, and guardian catches. The client only presents the HUD and sends action requests.

## Build

Run the following commands from the repository root:
- python3 tools/validate_roube_animal.py
- luau tools/tests/run.luau
- python3 tools/tests/test_map_layout.py
- python3 tools/tests/test_monetization.py
- python3 tools/tests/test_core_reliability.py
- rojo build default.project.json --output build/StealAnAnimal.rbxl

The build workflow creates an artifact for inspection. It does not publish the place.
