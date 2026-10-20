# STEAL AN ANIMAL

A fresh Roblox experience built in Luau with Rojo. The live game loop is: steal a baby animal from a biome, escape its giant guardian, return to your own farm, store the animal, and earn passive coins as it grows.

## Core gameplay

- Six procedural biomes: Sunny Meadow, Whispering Forest, Misty Wetlands, Frost Peak, Golden Savanna, and Amber Volcano.
- Twenty-one original animal species, each with a distinct color palette and procedural silhouette.
- Animals begin as **babies**, then evolve into **children**, **adolescents**, and **adults**.
- Each evolution adds **50%** to that animal's income. The cumulative income multipliers are 1×, 1.5×, 2.25×, and 3.375×.
- Giant animal guardians pursue players who are carrying stolen animals. If caught, the animal escapes and returns to the wild after a delay.
- Six animal slots per farm, persistent inventory, passive barn income, manual collection, speed upgrades, and bounded offline income.
- Native Roblox parts and procedural scenery; no Toolbox scripts, gamepasses, VIP purchases, or paid barn expansions.
- Mobile-first HUD with currency, income rate, barn occupancy, carrying state, and farm actions.

## Build and validate

The active Rojo project is default.project.json, which maps only src/StealAnAnimal/ into the Roblox DataModel. The previous implementation remains in the repository for historical comparison but is not included in the built place.

Commands:
- python3 tools/validate_roube_animal.py
- luau tools/tests/run.luau
- python3 tools/tests/test_map_layout.py
- python3 tools/tests/test_monetization.py
- python3 tools/tests/test_core_reliability.py
- rojo build default.project.json --output build/StealAnAnimal.rbxl

The GitHub Actions workflow checks Luau syntax and creates a .rbxl artifact. This does not publish to Roblox. Production publishing remains a separate manual workflow and is not run by this branch.

## Data and safety

Player profiles use DataStore UpdateAsync, autosave, and a six-hour offline-income cap. If a profile cannot be loaded, the game avoids overwriting the unknown saved record. Capture, storage, collection, movement, and upgrade costs are checked on the server.
