from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

required = [
    "default.project.json",
    "rokit.toml",
    "README.md",
    "src/CollisionBattlestar/ReplicatedStorage/Shared/Config.lua",
    "src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua",
    "src/CollisionBattlestar/ServerScriptService/Systems/WorldService.lua",
    "src/CollisionBattlestar/ServerScriptService/Systems/TagService.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/UIController.client.lua",
]

for relative in required:
    path = ROOT / relative
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit("Missing required file: " + relative)

manifest = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
if manifest.get("name") != "CollisionBattlestar":
    raise SystemExit("Unexpected project name")

workspace = manifest["tree"]["Workspace"]["$properties"]
if workspace.get("StreamingEnabled") is not True:
    raise SystemExit("StreamingEnabled must remain enabled")

source_root = ROOT / "src"
lua_files = list(source_root.rglob("*.lua"))
if len(lua_files) != 5:
    raise SystemExit("Unexpected Luau file count: {}".format(len(lua_files)))

for path in lua_files:
    source = path.read_text(encoding="utf-8")
    if any(marker in source for marker in ("<<<<<<<", "=======", ">>>>>>>")):
        raise SystemExit("Merge marker found in " + str(path))
    if "loadstring(" in source:
        raise SystemExit("Dynamic code loading found in " + str(path))

for legacy in (
    "HUDLayout.lua",
    "CombatService.lua",
    "DataService.lua",
    "InputController.client.lua",
    "FXController.client.lua",
    "roblox_connection.sh",
    "validate_no_ai.py",
):
    if any(path.name == legacy for path in ROOT.rglob("*")):
        raise SystemExit("Old rebuild artifact remains: " + legacy)

print("Validated clean Tag rebuild with {} Luau files.".format(len(lua_files)))
