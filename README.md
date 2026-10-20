# STEAL AN ANIMAL

A mobile-first Roblox experience about stealing baby animals, escaping their adult family guardians, bringing them to a rectangular personal farm, and earning passive coins as they grow.

## Map layout

- Eight original sequential zones, from the sunny meadow and lake to the amber volcano and blue abyss.
- Eight farms arranged as a clean 4 by 2 rectangle around the spawn hub.
- One wide, unobstructed animal corridor with a central track, colored stage gates, and roadside scenery.
- Every zone has an oversized adult guardian that protects the local animals; the final guardian is a whale.
- Twenty-nine original animal entries, including a hen, swan, polar bear, lion, dolphin, manta ray, and whale.
- Native Roblox parts form the animal silhouettes and decorations. The visual direction is inspired by the readable zones, strong color contrast, and giant guardian scale seen in Steal An Egg, but the farm layout, biomes, palettes, and animal models are original.

## Core gameplay

- Animals begin as babies, then evolve into children, adolescents, and adults.
- Each evolution adds 50% to that animal's income. Cumulative income multipliers are 1x, 1.5x, 2.25x, and 3.375x.
- Giant adult guardians pursue players carrying stolen animals. If caught, the animal escapes and returns to the wild after a delay.
- Six animal slots per farm, persistent inventory, passive barn income, manual collection, speed upgrades, and bounded offline income.
- Mobile-first HUD, server-validated capture and deposit, persistent profiles, no gamepasses, no VIP purchases, and no paid barn expansions.

## Build and validate

The Rojo project maps src/StealAnAnimal into the Roblox DataModel. The workflow parses active Luau files before tests and creates an RBXL artifact.

Validation commands:
- python3 tools/validate_roube_animal.py
- luau tools/tests/run.luau
- python3 tools/tests/test_map_layout.py
- python3 tools/tests/test_monetization.py
- python3 tools/tests/test_core_reliability.py
- rojo build default.project.json --output build/StealAnAnimal.rbxl

Passing automated checks does not replace a live Roblox Studio test. This branch does not publish to Roblox. Publishing remains a separate manual operation with explicit destination configuration and confirmation.

## Visual research

Reference screenshots were reviewed before implementation. They were used for high-level ideas only: a legible long route, colorful zone transitions, fenced farms, and large guardian figures. No exact map, mesh, screenshot, or packaged asset was copied.
