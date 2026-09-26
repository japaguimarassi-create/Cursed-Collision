# Free Roblox Assets Policy

The rebuild avoids random Toolbox dependencies in the core gameplay path.

## Approved starting source

Roblox provides an official NPC Kit containing Drooling Zombie, Soldiers, RO-01 Robots and NP-C 9000 Robots. The Creator Hub states that this project can be used under Roblox's Limited Use License, and the NPCs can be visually customized and behavior-modified.

This kit is reserved for the later PvE stage rather than the initial Tag stage.

## Creator Store

The Creator Store contains free creator assets, including 3D models, materials, gameplay scripts, UI elements and sounds. Free does not mean automatically safe to insert into a production game. Every imported asset must be inspected for scripts, dependencies, licenses and unnecessary runtime behavior before it is accepted into the source tree.

## Avatar skins

Roblox's Marketplace and Avatar Editor Service are separate from the Creator Store. Marketplace items can represent global avatar cosmetics, while Creator Store assets are development assets.

For this project, a "free skin" is accepted only when its current listing is verifiably free and its use is permitted. The game will not hard-code an unverified catalog item as a permanent dependency.

## Implementation rule

Prefer:
1. Roblox-authored free resources;
2. self-authored procedural skins;
3. verified free Creator Store resources;
4. verified Marketplace cosmetics only when the platform rules permit the intended use.

Do not ship unknown free models directly into the core server code.
