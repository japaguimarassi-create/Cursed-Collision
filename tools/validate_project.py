from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

required = [
    "default.project.json",
    "rokit.toml",
    "README.md",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/Constants.lua",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/Definitions.lua",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/Types.lua",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/GameIdentity.lua",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/CombatRules.lua",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/WaveRules.lua",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/EconomyRules.lua",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/SecurityRules.lua",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/PlayerState.lua",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/HUDContract.lua",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/HUDLayoutRules.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Bootstrap.server.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Core/ServiceRegistry.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Core/RuntimeState.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Core/PlayerState.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Security/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/World/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/World/ArenaBuilder.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/World/SpawnController.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Enemies/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Enemies/EnemyFactory.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Enemies/EnemyBrain.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Enemies/Navigation.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Combat/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Economy/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Foundation/Waves/Service.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/ClientBootstrap.client.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/InputController.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/HUD/Root.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/HUD/Theme.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/HUD/Components.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/CombatFX/Service.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Foundation/Camera/Service.lua",
    "docs/MAP_REFERENCE_RESEARCH_2026-09-29.md",
    "tools/tests/run.luau",
]

for relative in required:
    path = ROOT / relative
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit("Missing required file: " + relative)

manifest = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
if manifest.get("name") != "CollisionBattlestar":
    raise SystemExit("Unexpected project name")

workspace = manifest.get("tree", {}).get("Workspace", {})
if workspace.get("$properties", {}).get("StreamingEnabled") is not True:
    raise SystemExit("StreamingEnabled is disabled")

server_path = manifest["tree"]["ServerScriptService"]["$path"]
client_path = manifest["tree"]["StarterPlayer"]["StarterPlayerScripts"]["$path"]
if not server_path.endswith("/Foundation") or not client_path.endswith("/Foundation"):
    raise SystemExit("Runtime mapping does not point to foundation")

for path in (ROOT / "src").rglob("*.lua"):
    source = path.read_text(encoding="utf-8")
    if any(marker in source for marker in ("<<<<<<<", "=======", ">>>>>>>")):
        raise SystemExit("Merge marker found in " + str(path))
    if "loadstring(" in source:
        raise SystemExit("Dynamic code loading found in " + str(path))

legacy_roots = [
    ROOT / "src/CollisionBattlestar/ServerScriptService/Systems",
    ROOT / "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client",
]
for root in legacy_roots:
    if root.exists() and any(root.rglob("*.lua")):
        raise SystemExit("Legacy runtime source remains: " + str(root))

bootstrap = (ROOT / "src/CollisionBattlestar/ServerScriptService/Foundation/Bootstrap.server.lua").read_text(encoding="utf-8")
for remote in ("Combat", "State", "FX"):
    if f'ensureRemote("{remote}")' not in bootstrap:
        raise SystemExit("Required remote missing: " + remote)
if bootstrap.count('ensureRemote("') != 3:
    raise SystemExit("Unexpected remote count")

print("Validated Collision Battlestar foundation runtime and procedural PvE arena.")
