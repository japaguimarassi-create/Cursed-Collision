from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

required = [
    "default.project.json",
    "rokit.toml",
    "README.md",
    "gamepasses/manifest.json",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/Config.lua",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/GamePassIds.lua",
    "src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua",
    "src/CollisionBattlestar/ServerScriptService/Systems/DataService.lua",
    "src/CollisionBattlestar/ServerScriptService/Systems/EnemyService.lua",
    "src/CollisionBattlestar/ServerScriptService/Systems/CombatService.lua",
    "src/CollisionBattlestar/ServerScriptService/Systems/WaveService.lua",
    "src/CollisionBattlestar/ServerScriptService/Systems/CompanionService.lua",
    "src/CollisionBattlestar/ServerScriptService/Systems/ShopService.lua",
    "src/CollisionBattlestar/ServerScriptService/Systems/MonetizationService.lua",
    "src/CollisionBattlestar/ServerScriptService/Systems/WorldService.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/InputController.client.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/UIController.client.lua",
]

for relative in required:
    path = ROOT / relative
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit("Missing required file: " + relative)

manifest = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
if manifest.get("name") != "CollisionBattlestar":
    raise SystemExit("Unexpected project name")

if manifest["tree"]["Workspace"]["$properties"].get("StreamingEnabled") is not True:
    raise SystemExit("StreamingEnabled is disabled")

lua_files = list((ROOT / "src").rglob("*.lua"))
for path in lua_files:
    source = path.read_text(encoding="utf-8")
    if any(marker in source for marker in ("<<<<<<<", "=======", ">>>>>>>")):
        raise SystemExit("Merge marker found in " + str(path))
    if "loadstring(" in source:
        raise SystemExit("Dynamic code loading found in " + str(path))

print("Validated PvE rebuild with {} Luau files.".format(len(lua_files)))
