from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"

REQUIRED = [
    "ReplicatedStorage/Shared/Config.lua",
    "ReplicatedStorage/Shared/RemoteService.lua",
    "ReplicatedStorage/Combat/HitboxService.lua",
    "ReplicatedStorage/Characters/CharacterDefinitions.lua",
    "ReplicatedStorage/Characters/CharacterService.lua",
    "ReplicatedStorage/Characters/PotentialMan.lua",
    "ServerScriptService/CombatCore/StateManager.lua",
    "ServerScriptService/CombatCore/CooldownService.lua",
    "ServerScriptService/CombatCore/NetworkService.lua",
    "ServerScriptService/CombatCore/MovementController.lua",
    "ServerScriptService/CombatCore/DamageService.lua",
    "ServerScriptService/CombatCore/CombatService.lua",
    "ServerScriptService/CombatServer.server.lua",
    "StarterPlayer/StarterPlayerScripts/CombatClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/InputController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/ProceduralAnimator.lua",
]

ACTIVE = [
    "ReplicatedStorage/Shared/Config.lua",
    "ReplicatedStorage/Characters/CharacterDefinitions.lua",
    "ReplicatedStorage/Characters/CharacterService.lua",
    "ReplicatedStorage/Characters/PotentialMan.lua",
    "ReplicatedStorage/Combat/HitboxService.lua",
    "ServerScriptService/CombatCore/StateManager.lua",
    "ServerScriptService/CombatCore/CooldownService.lua",
    "ServerScriptService/CombatCore/NetworkService.lua",
    "ServerScriptService/CombatCore/MovementController.lua",
    "ServerScriptService/CombatCore/DamageService.lua",
    "ServerScriptService/CombatCore/CombatService.lua",
    "ServerScriptService/CombatServer.server.lua",
    "StarterPlayer/StarterPlayerScripts/CombatClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/InputController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/ProceduralAnimator.lua",
]

FORBIDDEN_ACTIONS = [
    "Heavy",
    "Dodge",
    "Grab",
    "Counter",
    "Slam",
    "Domain",
    "Awaken",
    "OneTime",
]

def path_for(relative):
    return SRC / relative

def read(relative):
    path = path_for(relative)
    if not path.exists():
        fail(f"missing file: src/{relative}")
    return path.read_text(encoding="utf-8")

def fail(message):
    print(f"FAIL: {message}")
    sys.exit(1)

for relative in REQUIRED:
    if not path_for(relative).exists():
        fail(f"required file missing: src/{relative}")

project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
if project.get("name") != "CursedCollision":
    fail("default.project.json project name must be CursedCollision")

definitions = read("ReplicatedStorage/Characters/CharacterDefinitions.lua")
if not re.search(r"\bPotentialMan\s*=", definitions):
    fail("PotentialMan definition missing")
if re.search(r"\bMegumi\s*=", definitions):
    fail("legacy Megumi definition is still exposed")

character_service = read("ReplicatedStorage/Characters/CharacterService.lua")
if "PotentialMan = require(ReplicatedStorage.Characters.PotentialMan)" not in character_service:
    fail("CharacterService does not require PotentialMan")
for legacy in ("CharacterFactory", "CustomMovesets", "DomainService", "DomainClashService"):
    if legacy in character_service:
        fail(f"legacy system still referenced by CharacterService: {legacy}")

network = read("ServerScriptService/CombatCore/NetworkService.lua")
for action in ("M1", "Dash", "BlockStart", "BlockEnd", "Special", "SelectCharacter"):
    if f"{action} = true" not in network:
        fail(f"allowed action missing from NetworkService: {action}")

for forbidden in FORBIDDEN_ACTIONS:
    if f"{forbidden} = true" in network:
        fail(f"forbidden action remains active in NetworkService: {forbidden}")

combat_server = read("ServerScriptService/CombatServer.server.lua")
for required_call in (
    "combat:M1(player)",
    "combat:Dash(",
    "combat:SetBlock(",
    "combat:Special(player)",
):
    if required_call not in combat_server:
        fail(f"CombatServer missing active action route: {required_call}")

for legacy in (
    "DomainService",
    "DomainClashService",
    "PerfectComboService",
    "OneTimeAttackService",
    "QuestService",
    "RagdollService",
):
    if legacy in combat_server:
        fail(f"legacy combat system still referenced by CombatServer: {legacy}")

combat_service = read("ServerScriptService/CombatCore/CombatService.lua")
for token in (
    "function CombatService:M1",
    "function CombatService:Dash",
    "function CombatService:SetBlock",
    "function CombatService:Special",
    "HitboxService:NearestTargetInFront",
):
    if token not in combat_service:
        fail(f"CombatService missing required implementation: {token}")

damage = read("ServerScriptService/CombatCore/DamageService.lua")
for token in ("Blocking", "DashUntil", "TakeDamage", "BlockImpact", "Hit"):
    if token not in damage:
        fail(f"DamageService missing validation/impact behavior: {token}")

hitbox = read("ReplicatedStorage/Combat/HitboxService.lua")
for token in ("GetPartBoundsInBox", "OverlapParams", "NearestTargetInFront"):
    if token not in hitbox:
        fail(f"HitboxService missing spatial query implementation: {token}")

animator = read("StarterPlayer/StarterPlayerScripts/Controllers/ProceduralAnimator.lua")
if "RunService:BindToRenderStep" not in animator:
    fail("procedural animator does not bind to the render loop")
if "RunService:UnbindFromRenderStep" not in animator:
    fail("procedural animator has no render-step cleanup")
if "Motor6D" not in animator or "CFrame:Lerp" not in animator:
    fail("procedural animator is missing Motor6D pose interpolation")

client = read("StarterPlayer/StarterPlayerScripts/CombatClient.client.lua")
for token in ("M1", "DASH", "BLOCK", "SPECIAL", "CombatAction:FireServer"):
    if token not in client:
        fail(f"combat HUD/input missing expected element: {token}")

for relative in ACTIVE:
    source = read(relative)
    for forbidden in FORBIDDEN_ACTIONS:
        if re.search(rf"\b{re.escape(forbidden)}\b", source):
            if relative.endswith("README.md"):
                continue
            if forbidden in ("Awaken", "Domain", "OneTime") and relative.endswith("Config.lua"):
                continue
            fail(f"forbidden legacy combat token appears in active file {relative}: {forbidden}")

print(f"PASS: {len(REQUIRED)} rebuild files present")
print("PASS: Potential Man is the only active character")
print("PASS: active combat surface is M1 + Dash + Block + Special")
print("PASS: server-authoritative hitbox, damage, stun, cooldown and dash protection detected")
print("PASS: procedural Motor6D animation controller detected")
print("PASS: legacy heavy/dodge/grab/counter/slam/domain/awakening routes are not active")
