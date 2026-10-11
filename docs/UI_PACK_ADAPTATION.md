# UI PACK ADAPTATION — STEAL AN ANIMAL

This guide records the design mapping used when adapting the supplied Zxgly cartoony simulator UI concept into the Rojo-controlled experience. The original pack inspired the visual system; this build recreates its panel hierarchy and interactions rather than importing its binary model or executing generic LocalScripts that may assume unrelated remotes, currencies and product IDs.

## 1. Text and navigation mapping

| Pack concept / panel | STEAL AN ANIMAL replacement | Runtime behaviour |
| --- | --- | --- |
| Inventory / InventoryFrame | **YOUR BARN** | Lists stored animals, capacity, rate per second and uncollected bank |
| Pets / Eggs | **ANIMAL INDEX** | Shows species, biome, rarity, weight and coin rate; players find animals in the world |
| Cash / currency counter | **COINS** | Wallet coins, saved in the server profile |
| Gems / premium currency | **Remove** | No second currency; Robux purchases live in the separate Passes screen |
| Store / Shop | **FARM UPGRADES** | Speed levels purchased with coins |
| Gamepass / ForeverPack / Robux store | **PASSES & PRODUCTS** | Four different permanent benefits and two repeatable Developer Products |
| Strength / sword / power upgrade | **Remove** | Strength is not a gameplay stat; movement and escape depend on speed and animal weight |
| Capacity counter | **BARN 0/6** or **BARN 0/10** | Six standard slots; Expanded Barn adds four |
| Captured pets counter | **ANIMALS CAPTURED** / **STORED ANIMALS** | Separates total captures from animals safely delivered to the barn |
| Tool / net / lasso action | **STEAL** | Uses a server-authoritative ProximityPrompt; the animal attaches visually to the player |
| Sell button | **STORE ANIMAL** | Deposit the carried animal at the green pad of the player's own farm |
| Passive income / claim reward | **COLLECT COINS** | Gold pad and Barn screen button; server checks location and ownership |
| Code panel | **REDEEM CODE** | Server-verified, one-time farm codes |
| Daily / Reward calendar | **DAILY HARVEST** | One claim per UTC day with a seven-day streak |
| Quest | **FARM QUESTS** | First capture, first barn deposit, collector and full-barn objectives |
| Stats | **FARM STATISTICS** | Coins, animals, income rate, captures, deposits, speed and rebirths |
| Settings | **SETTINGS** | Reduced visual effects and viewport recalculation |
| Rebirth | **REBIRTH** | Resets speed and wallet only after server-side requirements; preserves the barn collection |

Not every name in a generic pack is reused. Features that do not fit the new loop (gems, sword strength, eggs, pet hatching or total Robux spent) are removed rather than presented as fake systems.

## 2. Nature and farm palette

The GUI creates UIGradient, UICorner and UIStroke instances in Luau, so colours are centrally controlled instead of manually edited in imported frames.

| Role | Hex | Use |
| --- | --- | --- |
| Deep forest | #233027 | Main panels and modal background |
| Pine panel | #374936 | Cards and secondary panels |
| Light moss | #4F6343 | Input fields and elevated cards |
| Meadow green | #7DBE53 | Farm and primary action |
| Leaf green | #469C53 | Deposit, success and growth |
| Dark moss | #2E653F | End colour of green gradients |
| Harvest gold | #FFCC59 | Coins, income and collect actions |
| Warm cream | #FFF4DB | Main text and light trim |
| Sky blue | #6AC3EF | Speed and quick escape |
| Aqua | #4FCBBE | Water biome and secondary highlight |
| Orchid | #B58BDD | Epic rarity and quest panels |
| Pumpkin | #ED914B | Rebirth and high-risk event |
| Berry pink | #F68BAC | Rare animal accent |

Recommended gradients: primary green button from #7DBE53 to #2E653F at 90 degrees; panel gradient from #4E6C41 to #233427; gold claim button from #FFCC59 to #996C27. Keep text cream or near-white; do not use the same gradient for every pass card.

## 3. Thematic icons

The runtime uses readable text markers where a transparent image asset is not bundled, avoiding broken external asset IDs.

| Generic icon archetype | Replacement |
| --- | --- |
| Gem / diamond | Remove or replace with a barn-income coin |
| Sword / strength / fist | Running shoe or speed trails |
| Egg / hatch | Animal paw or animal silhouette |
| Generic pet face | Species render on the barn slot; UI displays rarity and biome markers |
| Backpack / inventory | Barn with open double doors |
| Capacity / storage box | Barn slot grid or hay bale |
| Net / tool | Lasso loop / rope circle for the capture prompt |
| Coins | Gold coin stamped with a hoof or paw |
| Rebirth arrows | Leaf spiral around a barn roof |
| Quest scroll | Clipboard with paw print |
| Daily reward chest | Sunrise above a hay bale |
| Settings cog | Gear with a leaf centre |

The UI deliberately does not invent a second gems currency or a strength weapon. The on-screen capture action is STEAL, and the wild animal's name and income rate appear above it.

## 4. Barn layout and earning loop

The farm contains a red wooden barn, entry door, owner sign, treadmill, ten physical display slots, a green deposit pad and a gold collect pad. Six standard slots are available by default; slots 7–10 appear locked unless the Extra Barn Slots gamepass is owned. Slots are positioned separately from the action pads so stored animal models cannot cover the deposit or income prompt.

1. Find a wild animal in one of the map biomes.
2. Hold STEAL beside it. Only one animal can be carried.
3. Return to the farm. If a giant animal guardian catches you, the carried animal escapes.
4. Hold STORE ANIMAL at the green pad. The server saves the animal ID into the profile and adds its per-second rate.
5. Income accumulates into a separate bank. Hold COLLECT COINS at the gold pad or press Collect on the Barn page while standing near that same pad.
6. Rejoin after leaving to collect bounded offline income (up to six hours). The claim and last-income timestamp update atomically to prevent repeatedly claiming the same period.

The rate for each species is data-driven in AnimalCatalog.lua. The server, not the UI, verifies the carried animal, farm ownership, slot capacity, bank transfer and Developer Product receipts.

## 5. Map design choices from research

The research combined the current Steal An Egg listing and biome guides with Roblox Creator Hub environmental-art, adaptive-UI and streaming/performance documentation, plus developer forum examples of low-poly simulator maps and farm scenes. The recurring pattern is a main route connecting clearly themed biomes, landmarks that remain legible from a distance, and guardian risk near each animal region. For this game it becomes a single navigable route with six distinct regions, eight personal farms around the hub, bright gateways, rocks, trees, mushrooms, water pools and crystals.

This is an original layout, not a copy of Steal An Egg's exact map, title, meshes, animal roster or guardians. Chosen zones:

1. Sunny Meadow — farm animals and bear.
2. Whispering Forest — woodland animals and wolf.
3. Misty Wetlands — river animals and crocodile.
4. Frost Peak — snow animals and snow bear.
5. Golden Savanna — savanna animals and lion.
6. Ember Volcano — mythical animals and volcanic titan.

References:
- [Steal An Egg — Roblox experience](https://www.roblox.com/games/107778070777162/Steal-An-Egg)
- [IGN — Steal an Egg biome guide](https://www.ign.com/wikis/steal-an-egg-roblox/All_Biomes)
- [Games.gg — biome and guardian guide](https://games.gg/roblox/guides/steal-an-egg-biomes-guide/)
- [Community biome map guide](https://stealanegggame.wiki/exploration/)
- [Roblox — construct your world](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/construct-your-world)
- [Roblox — UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)
- [Roblox — position and size UI objects](https://create.roblox.com/docs/ui/position-and-size)
- [Roblox — adaptive design guidelines](https://create.roblox.com/docs/production/publishing/adaptive-design)
- [Roblox — instance streaming](https://create.roblox.com/docs/workspace/streaming)
- [Roblox Developer Forum — map design guidelines](https://devforum.roblox.com/t/map-design-guidelines-make-your-maps-superior/1293781)
- [Roblox Developer Forum — low-poly simulator map](https://devforum.roblox.com/t/feedback-on-my-low-poly-simulator-map/622572)
- [Zxgly — free cartoony Roblox UI pack](https://zxgly.itch.io/free-cartoony-roblox-ui-pack)

## 6. Mobile acceptance checklist

- Interactive UI uses CoreUISafeInsets so headings and buttons avoid the Roblox top bar and device cutouts.
- On touch devices the five-button navigation becomes narrower and sits above the virtual joystick/jump-button zones; desktop keeps a full-width bar near the bottom.
- Clickable actions use Activated and remain usable through touch, keyboard or gamepad focus where supported.
- Long menus scroll instead of shrinking every row to fit.
- The capture prompt is contextual; no permanent giant STEAL button blocks movement.
- Map construction exposes MapReady, BaseCount, AnimalCount and BiomeCount; the client shows a diagnostic if the server fails to finish building the world.
- Pass/product buttons remain in setup state until real IDs are assigned in MonetizationIds.lua; zero IDs are never treated as purchasable.
