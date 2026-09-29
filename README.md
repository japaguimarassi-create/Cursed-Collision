# Collision Battlestar

Where Worlds Collide

Collision Battlestar is the current project identity for the rebuild. The repository name remains Cursed-Collision for history compatibility.

## Foundation loop

Join -> Spawn -> Fight -> Defeat enemies -> Earn Credits -> Defeat the red Elite -> Clear the wave -> Upgrade Damage -> Next wave.

The current build focuses on one procedural PvE arena. Persistence, companions, skins, full shop and monetization, PvP, missions, bosses, and large-world content are deferred until this loop is verified.

## Runtime architecture

- Server-authoritative combat, waves, enemy damage, rewards, and upgrade economy.
- Three gameplay RemoteEvents: Combat, State, FX.
- One server bootstrap and one client bootstrap.
- One mobile-first HUD.
- Procedural arena geometry with no third-party gameplay scripts.

## Controls

Mobile uses the on-screen M1 and Dash buttons.

Keyboard: Left Click = M1, Q = Dash.

Controller: R2 = M1, B = Dash.

## Development

Validation: python3 tools/validate_project.py

Unit tests: luau tools/tests/run.luau

Build: rojo build default.project.json --output build/CollisionBattlestar.rbxl
