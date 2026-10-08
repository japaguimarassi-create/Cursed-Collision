from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))

expected = {
    "ReplicatedStorage": "src/CollisionBattlestarV2/ReplicatedStorage",
    "ServerScriptService": "src/CollisionBattlestarV2/ServerScriptService",
    "StarterPlayerScripts": "src/CollisionBattlestarV2/StarterPlayer/StarterPlayerScripts",
}

tree = PROJECT.get("tree", {})

assert PROJECT.get("name") == "CollisionBattlestar"
assert tree.get("ReplicatedStorage", {}).get("$path") == expected["ReplicatedStorage"]
assert tree.get("ServerScriptService", {}).get("$path") == expected["ServerScriptService"]
assert tree.get("StarterPlayer", {}).get("StarterPlayerScripts", {}).get("$path") == expected["StarterPlayerScripts"]

for old in ("src/CollisionBattlestar/CleanServer", "src/CollisionBattlestar/CleanClient", "src/CollisionBattlestar/ReplicatedStorage", "src/CollisionBattlestar/ServerScriptService/Foundation"):
    manifest_text = json.dumps(PROJECT)
    assert old not in manifest_text

required = [
    "src/CollisionBattlestarV2/ReplicatedStorage/Shared/Constants.lua",
    "src/CollisionBattlestarV2/ReplicatedStorage/Shared/Rules.lua",
    "src/CollisionBattlestarV2/ReplicatedStorage/Shared/Data.lua",
    "src/CollisionBattlestarV2/ReplicatedStorage/Shared/EnemyDefinitions.lua",
    "src/CollisionBattlestarV2/ReplicatedStorage/Shared/MissionDefinitions.lua",
    "src/CollisionBattlestarV2/ReplicatedStorage/Shared/ShopDefinitions.lua",
    "src/CollisionBattlestarV2/ReplicatedStorage/Shared/PhysicsRules.lua",
    "src/CollisionBattlestarV2/ReplicatedStorage/Shared/Network.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Core/State.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Core/Heart.lua",
    "src/CollisionBattlestarV2/ServerScriptService/AI/Agent.lua",
    "src/CollisionBattlestarV2/ServerScriptService/AI/Heart.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Persistence.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Players.lua",
    "src/CollisionBattlestarV2/ServerScriptService/World.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Enemies.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Combat.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Waves.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Score.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Missions.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Shop.lua",
    "src/CollisionBattlestarV2/ServerScriptService/PvP.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Echo.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Ranking.lua",
    "src/CollisionBattlestarV2/ServerScriptService/Main.server.lua",
    "src/CollisionBattlestarV2/StarterPlayer/StarterPlayerScripts/Client.client.lua",
    "src/CollisionBattlestarV2/StarterPlayer/StarterPlayerScripts/HUD.lua",
    "src/CollisionBattlestarV2/StarterPlayer/StarterPlayerScripts/FX.lua",
    "src/CollisionBattlestarV2/StarterPlayer/StarterPlayerScripts/Audio.lua",
    "tools/tests/run_v2.luau",
    "tools/tests/v2/V2Spec.luau",
]

for relative in required:
    path = ROOT / relative
    assert path.is_file() and path.stat().st_size > 0, f"missing: {relative}"

v2 = ROOT / "src/CollisionBattlestarV2"
lua_files = list(v2.rglob("*.lua"))
assert 20 <= len(lua_files) <= 40, f"unexpected V2 Lua count: {len(lua_files)}"

for path in lua_files:
    source = path.read_text(encoding="utf-8")
    assert "TODO" not in source
    assert "<<<<<<<" not in source
    assert "=======" not in source
    assert ">>>>>>>" not in source
    assert "loadstring(" not in source

heart = (v2 / "ServerScriptService/Core/Heart.lua").read_text(encoding="utf-8")
ai_heart = (v2 / "ServerScriptService/AI/Heart.lua").read_text(encoding="utf-8")
combat = (v2 / "ServerScriptService/Combat.lua").read_text(encoding="utf-8")
world = (v2 / "ServerScriptService/World.lua").read_text(encoding="utf-8")
persistence = (v2 / "ServerScriptService/Persistence.lua").read_text(encoding="utf-8")
players = (v2 / "ServerScriptService/Players.lua").read_text(encoding="utf-8")
main = (v2 / "ServerScriptService/Main.server.lua").read_text(encoding="utf-8")

for token in ("Register", "Report", "Reload", "RuntimeReloading", "RuntimeRestored", "RuntimeFailed"):
    assert token in heart

for token in ("MaxNPCs", "Register", "Unregister", "SetWave", "HealthCheck"):
    assert token in ai_heart

for token in ("GetPartBoundsInBox", "Raycast", "OnServerEvent", "TakeDamage"):
    assert token in combat

for token in ("RegisterCollisionGroup", "CollisionGroupSetCollidable", "CustomPhysicalProperties"):
    assert token in world

for token in ("UpdateAsync", "GenerateGUID", "GetDataStore"):
    assert token in persistence

assert "LoadCharacterAsync" in players
assert "loadstring(" not in main

print(f"Validated Collision Battlestar V2 runtime: {len(lua_files)} Lua files")
