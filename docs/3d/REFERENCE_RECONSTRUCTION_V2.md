# 3D Reference Reconstruction v2

This revision translates the gathered game screenshots and earlier chat concepts into an original low-poly GLB asset family. It is intended for review and import as modular geometry, not as a finished Roblox place.

## Asset inventory

The package contains 15 GLBs: eight individually named guardians (Hen, Swan, Scorpion, Tiger, Yeti, Hellhound, Abyss Whale and Tyrannosaur), an open pen without houses, base and premium Ice treadmills, egg nests, a generic player carrying an egg, an eight-gate linear map, and one complete reference scene.

## Visual findings and decisions

- The reference game's loop links stealing/hatching eggs, pet income, treadmill/base upgrades and Speed training.
- Guards are shown asleep beside nests; the revised models now have visible Z markers.
- The base is interpreted as a simple open fenced plot, not a house or barn.
- The premium treadmill uses a dark running belt, vertical display and blue crystal structures.
- The whale remains broad and horizontal; the T-Rex is given an enlarged skull/jaw; the Scorpion uses an arched segmented tail.
- Our project's eight-biome order and Speed thresholds are retained rather than substituted with reported thresholds from the reference game.

## Iteration record

**v1 review:** the initial geometry set included the eight guardians, pen, nests, two treadmills and linear map, but lacked visible sleep markers and an egg-carrying avatar.

**v2 revision:** added eight Z markers, a generic block avatar holding a large egg, and split the major groups into individually importable GLBs. The master scene contains 507 uniquely named geometry nodes. Local validation reopened all 15 GLBs and checked each node reference, bounding box, eight guardians, eight sleep markers, eight map gates, two treadmill tiers and the absence of barn/house object names.

## Animation and runtime boundary

The GLBs are static geometry. The project’s Luau modules continue to provide Walk/Rest/Run posing, guardian chase/escape logic and local treadmill motion. No animation clips are claimed to be embedded in the GLBs.

The previously saved Blender project still contains its old barn structures. A Blender revision attempt was cancelled after the connected CPU modeling allowance was exhausted, so the GLB pen is a new independent reference asset and does not silently replace that saved scene. Actual Roblox Studio multiplayer playtesting is still pending.

## Source record

The exact source URLs and a mapping from each image/reference to the modeled feature are recorded in [reference_manifest_v2.json](reference_manifest_v2.json). The external sources are visual research references; all geometry in the package is an independent procedural reconstruction.
