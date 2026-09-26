# Collision Battlestar

PvE wave fighter foundation.

Current playable loop:
- procedurally generated combat world;
- escalating enemy waves;
- one red Elite enemy per wave;
- server-authoritative M1 combat;
- enemy AI with pathfinding and melee attacks;
- credits for every kill and wave-clear bonuses;
- persistent damage, defense and speed upgrades;
- recruitable NPC companions with stronger tiers;
- physical upgrade/companion shop;
- Roblox GamePass integration through MarketplaceService;
- optional Open Cloud provisioning for the six new passes.

Roblox target:
- Universe: 5290480963
- Place: 15338267657

GamePasses:
- Elite Hunter
- Companion Slot+
- Arsenal VIP
- VIP
- Wave Master
- Companion Prime

GamePass IDs are generated into the Shared/GamePassIds.lua module. A zero ID means that pass has not yet been provisioned.

The project does not depend on arbitrary free models for its core runtime. Roblox's official NPC Kit is reserved as an optional later asset source.

Next planned slice after the PvE build is verified:
- a compact HUD entry point;
- teleport to a distant white minimalist PvP battleground;
- separate PvP systems from the PvE world.
