from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

required = [
    "default.project.json",
    "rokit.toml",
    "README.md",
    "src/CollisionBattlestar/ReplicatedStorage/CleanRules.lua",
    "src/CollisionBattlestar/CleanServer/Runtime.server.lua",
    "src/CollisionBattlestar/CleanClient/Runtime.client.lua",
    "tools/tests/CleanRulesSpec.luau",
    "tools/tests/run.luau",
]

for relative in required:
    path = ROOT / relative
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit("Missing required clean-runtime file: " + relative)

manifest = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
if manifest.get("name") != "CollisionBattlestar":
    raise SystemExit("Unexpected project name")
tree = manifest.get("tree", {})
workspace = tree.get("Workspace", {})
if workspace.get("$properties", {}).get("StreamingEnabled") is not False:
    raise SystemExit("Clean runtime requires StreamingEnabled=false")
server_path = tree.get("ServerScriptService", {}).get("$path", "")
client_path = tree.get("StarterPlayer", {}).get("StarterPlayerScripts", {}).get("$path", "")
if server_path != "src/CollisionBattlestar/CleanServer":
    raise SystemExit("Server mapping is not CleanServer")
if client_path != "src/CollisionBattlestar/CleanClient":
    raise SystemExit("Client mapping is not CleanClient")
server_source = (ROOT / "src/CollisionBattlestar/CleanServer/Runtime.server.lua").read_text(encoding="utf-8")
client_source = (ROOT / "src/CollisionBattlestar/CleanClient/Runtime.client.lua").read_text(encoding="utf-8")
for source_path, source in [("server", server_source), ("client", client_source)]:
    if any(marker in source for marker in ("<<<<<<<", "=======", ">>>>>>>")):
        raise SystemExit("Merge marker found in " + source_path)
    if "loadstring(" in source:
        raise SystemExit("Dynamic loading found in " + source_path)
    if "TODO" in source:
        raise SystemExit("Placeholder TODO found in " + source_path)
for token in [
    "Players.CharacterAutoLoads = false",
    "workspace:SetAttribute(\"CBS_WorldReady\", true)",
    'Action.Name = "Action"',
    'State.Name = "State"',
    "player:LoadCharacter()",
    'action == "Attack"',
    'action == "Dash"',
    'action == "BuySkin"',
    'action == "SummonEcho"',
]:
    if token not in server_source:
        raise SystemExit("Server contract missing: " + token)

for token in [
    'gui.Name = "CollisionBattlestarHUD"',
    "Enum.ScreenInsets.CoreUISafeInsets",
    'ContextActionService:BindAction("CBS_Attack"',
    'ContextActionService:BindAction("CBS_Dash"',
    'connecting.Text = "SERVER CONNECTION FAILED"',
    'connecting.Text = "RECONNECT REQUIRED"',
]:
    if token not in client_source:
        raise SystemExit("Client contract missing: " + token)

for path in [ROOT / "src/CollisionBattlestar/CleanServer/Runtime.server.lua", ROOT / "src/CollisionBattlestar/CleanClient/Runtime.client.lua"]:
    if path.stat().st_size > 70000:
        raise SystemExit("Clean runtime file is too large: " + str(path))

print("Validated Collision Battlestar clean runtime mapping and safety contracts.")
