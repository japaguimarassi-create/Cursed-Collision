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
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/CombatRules.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/DataSchema.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/PersistenceRules.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/ProgressionRules.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/FriendRules.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/CompanionDefinitions.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/CompanionRules.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/EnemySkinDefinitions.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/EnemySkinRules.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/ShopDefinitions.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/InventoryRules.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/ShopRules.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/PvPRules.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/MissionDefinitions.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/MissionRules.lua",
    "src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/MonetizationDefinitions.lua",
    "src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua",
    "src/CollisionBattlestar/ServerScriptService/Core/ServiceRegistry.lua",
    "src/CollisionBattlestar/ServerScriptService/Core/RuntimeState.lua",
    "src/CollisionBattlestar/ServerScriptService/Core/PlayerState.lua",
    "src/CollisionBattlestar/ServerScriptService/Persistence/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Progression/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Progression/RecoveryService.lua",
    "src/CollisionBattlestar/ServerScriptService/Security/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Economy/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/World/ArenaBuilder.lua",
    "src/CollisionBattlestar/ServerScriptService/World/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Enemies/EnemyFactory.lua",
    "src/CollisionBattlestar/ServerScriptService/Enemies/EnemyBrain.lua",
    "src/CollisionBattlestar/ServerScriptService/Enemies/Navigation.lua",
    "src/CollisionBattlestar/ServerScriptService/Enemies/SkinFactory.lua",
    "src/CollisionBattlestar/ServerScriptService/Enemies/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Combat/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Waves/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Friends/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Companions/AvatarResolver.lua",
    "src/CollisionBattlestar/ServerScriptService/Companions/VisualProfile.lua",
    "src/CollisionBattlestar/ServerScriptService/Companions/Factory.lua",
    "src/CollisionBattlestar/ServerScriptService/Companions/Brain.lua",
    "src/CollisionBattlestar/ServerScriptService/Companions/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Shop/InventoryService.lua",
    "src/CollisionBattlestar/ServerScriptService/Shop/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/PvP/ArenaBuilder.lua",
    "src/CollisionBattlestar/ServerScriptService/PvP/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Missions/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Analytics/Service.lua",
    "src/CollisionBattlestar/ServerScriptService/Admin/TestLabService.lua",
    "src/CollisionBattlestar/ServerScriptService/Monetization/Service.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Input/Service.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/HUD/Root.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/HUD/AdvancedPanels.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/CombatFX/Service.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Camera/Service.lua",
    "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/SocialInvite/Service.lua",
    "tools/tests/PhaseASharedSpec.luau",
    "tools/tests/PhaseBDataSchemaSpec.luau",
    "tools/tests/PhaseBPersistenceRulesSpec.luau",
    "tools/tests/PhaseBProgressionSpec.luau",
    "tools/tests/PhaseBCompanionRulesSpec.luau",
    "tools/tests/PhaseBSkinRulesSpec.luau",
    "tools/tests/PhaseBShopRulesSpec.luau",
    "tools/tests/PhaseBCommerceSpec.luau",
    "tools/tests/PhaseBPvPRulesSpec.luau",
    "tools/tests/PhaseBMissionRulesSpec.luau",
    "tools/tests/phase_b_rules_run.luau",
]

for relative in required:
    path = ROOT / relative
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit("Missing required Phase B file: " + relative)

manifest = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
if manifest.get("name") != "CollisionBattlestar":
    raise SystemExit("Unexpected project name")

tree = manifest.get("tree", {})
if tree.get("Workspace", {}).get("$properties", {}).get("StreamingEnabled") is not False:
    raise SystemExit("Phase B requires StreamingEnabled=false")

expected = {
    "ReplicatedStorage": "src/CollisionBattlestar/RuntimeReplicatedStorage",
    "ServerScriptService": "src/CollisionBattlestar/ServerScriptService",
    "StarterPlayerScripts": "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts",
}

if tree.get("ReplicatedStorage", {}).get("$path") != expected["ReplicatedStorage"]:
    raise SystemExit("ReplicatedStorage mapping is not isolated")
if tree.get("ServerScriptService", {}).get("$path") != expected["ServerScriptService"]:
    raise SystemExit("Server mapping is not isolated")
if tree.get("StarterPlayer", {}).get("StarterPlayerScripts", {}).get("$path") != expected["StarterPlayerScripts"]:
    raise SystemExit("Client mapping is not isolated")

runtime_root = ROOT / "src/CollisionBattlestar"
lua_files = list(runtime_root.rglob("*.lua"))

for path in lua_files:
    source = path.read_text(encoding="utf-8")
    if any(marker in source for marker in ("<<<<<<<", "=======", ">>>>>>>")):
        raise SystemExit("Merge marker found in " + str(path))
    if "loadstring(" in source:
        raise SystemExit("Dynamic loading found in " + str(path))
    if "TODO" in source:
        raise SystemExit("Placeholder TODO found in " + str(path))

server = (ROOT / "src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua").read_text(encoding="utf-8")
combat = (ROOT / "src/CollisionBattlestar/ServerScriptService/Combat/Service.lua").read_text(encoding="utf-8")
client = (ROOT / "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua").read_text(encoding="utf-8")
hud = (ROOT / "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/HUD/Root.lua").read_text(encoding="utf-8")
panels = (ROOT / "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/HUD/AdvancedPanels.lua").read_text(encoding="utf-8")
persistence = (ROOT / "src/CollisionBattlestar/ServerScriptService/Persistence/Service.lua").read_text(encoding="utf-8")
companion = (ROOT / "src/CollisionBattlestar/ServerScriptService/Companions/Service.lua").read_text(encoding="utf-8")
pvp = (ROOT / "src/CollisionBattlestar/ServerScriptService/PvP/Service.lua").read_text(encoding="utf-8")
monetization = (ROOT / "src/CollisionBattlestar/ServerScriptService/Monetization/Service.lua").read_text(encoding="utf-8")

for token in [
    '"RemoteEvent"',
    '"Commerce"',
    '"Companion"',
    '"PvP"',
    '"Mission"',
    '"Admin"',
    "StartInOrder",
    "Persistence",
    "PlayerState",
    "Progression",
    "Companions",
    "Shop",
    "Missions",
    "TestLab",
    "Monetization",
]:
    if token not in server:
        raise SystemExit("Bootstrap contract missing: " + token)

for token in [
    'action == "Attack"',
    'action == "Dash"',
    "GetPartBoundsInBox",
    "ValidateAttackTarget",
    "ValidatePvPTarget",
    "TakeDamage",
]:
    if token not in combat:
        raise SystemExit("Combat contract missing: " + token)

for token in ["UpdateAsync", "GenerateGUID", "SaveAndRelease", "PLAYER_SESSION_LOCKED"]:
    if token not in persistence:
        raise SystemExit("Persistence contract missing: " + token)

for token in ["WaitForChild", "HUD.new", "InputService.new", "AdvancedPanels.new", "SocialInvite.new"]:
    if token not in client:
        raise SystemExit("Client bootstrap contract missing: " + token)

for token in [
    'gui.Name = "CollisionBattlestarHUD"',
    "Enum.ScreenInsets.CoreUISafeInsets",
    "AttackButton",
    "DashButton",
    "CBS_Credits",
    "CBS_PowerLevel",
]:
    if token not in hud:
        raise SystemExit("HUD contract missing: " + token)

for token in ["ShopButton", "CompanionButton", "MissionButton", "PvPButton", "InviteButton", "ShopOverlay", "CompanionOverlay", "MissionOverlay", "PvPOverlay"]:
    if token not in panels:
        raise SystemExit("Advanced HUD contract missing: " + token)

for token in ["Unsummon", "friend_present", "friendUserId", "CBS_EchoOwnerUserId"]:
    if token not in companion:
        raise SystemExit("Companion contract missing: " + token)

for token in ["IsInsideZone", "Join", "Leave", "CBS_PvP"]:
    if token not in pvp:
        raise SystemExit("PvP contract missing: " + token)

if "ProcessReceipt" not in monetization:
    raise SystemExit("Monetization receipt contract missing")

print("Validated Collision Battlestar Phase B tree and runtime contracts.")
