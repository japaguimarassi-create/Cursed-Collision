from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

required = [
    "default.project.json",
    "rokit.toml",
    "README.md",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/Constants.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/Definitions.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/Config.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/GameIdentity.lua",
    "src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua",
    "src/CollisionBattlestar/ServerScriptService/Core/ServiceRegistry.lua",
    "src/CollisionBattlestar/ServerScriptService/Core/RuntimeState.lua",
    "src/CollisionBattlestar/ServerScriptService/Core/PlayerState.lua",
    "src/CollisionBattlestar/ServerScriptService/Security/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Economy/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/World/ArenaBuilder.lua",
    "src/CollisionBattlestar/ServerScriptService/World/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Enemies/EnemyFactory.lua",
    "src/CollisionBattlestar/ServerScriptService/Enemies/EnemyBrain.lua",
    "src/CollisionBattlestar/ServerScriptService/Enemies/Navigation.lua",
    "src/CollisionBattlestar/ServerScriptService/Enemies/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Combat/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Waves/Service.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Input/Service.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/HUD/Root.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/CombatFX/Service.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Camera/Service.lua",
    "tools/tests/PhaseASharedSpec.luau",
    "tools/tests/phase_a_run.luau",
]

for relative in required:
    path = ROOT / relative
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit("Missing required Phase A file: " + relative)

manifest = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
if manifest.get("name") != "CollisionBattlestar":
    raise SystemExit("Unexpected project name")

tree = manifest.get("tree", {})
workspace = tree.get("Workspace", {})
if workspace.get("$properties", {}).get("StreamingEnabled") is not False:
    raise SystemExit("Phase A requires StreamingEnabled=false")

replicated_path = tree.get("ReplicatedStorage", {}).get("$path", "")
server_path = tree.get("ServerScriptService", {}).get("$path", "")
client_path = tree.get("StarterPlayer", {}).get("StarterPlayerScripts", {}).get("$path", "")

if replicated_path != "src/CollisionBattlestar/RuntimeReplicatedStorage":
    raise SystemExit("ReplicatedStorage mapping is not isolated")
if server_path != "src/CollisionBattlestar/ServerScriptService":
    raise SystemExit("Server mapping is not isolated")
if client_path != "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts":
    raise SystemExit("Client mapping is not isolated")

runtime_root = ROOT / "src/CollisionBattlestar"
lua_files = list(runtime_root.rglob("*.lua"))

if not lua_files:
    raise SystemExit("No runtime Luau files found")

for path in lua_files:
    source = path.read_text(encoding="utf-8")
    if any(marker in source for marker in ("<<<<<<<", "=======", ">>>>>>>")):
        raise SystemExit("Merge marker found in " + str(path))
    if "loadstring(" in source:
        raise SystemExit("Dynamic loading found in " + str(path))
    if "TODO" in source:
        raise SystemExit("Placeholder TODO found in " + str(path))

server_source = (ROOT / "src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua").read_text(encoding="utf-8")
combat_source = (ROOT / "src/CollisionBattlestar/ServerScriptService/Combat/Service.lua").read_text(encoding="utf-8")
client_source = (ROOT / "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua").read_text(encoding="utf-8")
hud_source = (ROOT / "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/HUD/Root.lua").read_text(encoding="utf-8")

for token in [
    'Instance.new("RemoteEvent")',
    "StartInOrder",
    "PlayerState",
    "World",
    "Enemies",
    "Combat",
    "Waves",
]:
    if token not in server_source:
        raise SystemExit("Bootstrap contract missing: " + token)

for token in [
    'action == "Attack"',
    'action == "Dash"',
    "GetPartBoundsInBox",
    "ValidateAttackTarget",
    "TakeDamage",
]:
    if token not in combat_source:
        raise SystemExit("Combat contract missing: " + token)

for token in [
    "WaitForChild",
    "HUD.new",
    "InputService.new",
    "CombatFX.new",
    "CameraService.new",
]:
    if token not in client_source:
        raise SystemExit("Client bootstrap contract missing: " + token)

for token in [
    'gui.Name = "CollisionBattlestarHUD"',
    "Enum.ScreenInsets.CoreUISafeInsets",
    "AttackButton",
    "DashButton",
    "CBS_Credits",
    "CBS_PowerLevel",
]:
    if token not in hud_source:
        raise SystemExit("HUD contract missing: " + token)

print("Validated Collision Battlestar Phase A tree and runtime contracts.")
