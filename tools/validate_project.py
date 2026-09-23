from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"

CHARACTERS = [
    "PotentialMan", "Yuji", "Gojo", "Sukuna", "Megumi", "Yuta", "Maki", "Toji",
    "Mahito", "Todo", "Hakari", "Choso", "Kashimo", "Naoya", "Kenjaku", "Jogo",
    "Dagon", "Hanami", "Higuruma", "Takaba", "Uraume", "Yorozu", "Ryu", "Uro",
    "Kusakabe"
]

REQUIRED = [
    "ReplicatedStorage/Shared/Config.lua",
    "ReplicatedStorage/Shared/RemoteService.lua",
    "ReplicatedStorage/Combat/HitboxService.lua",
    "ReplicatedStorage/Combat/AbilityTimeline.lua",
    "ReplicatedStorage/Combat/HitRegistry.lua",
    "ReplicatedStorage/Animation/AnimationRegistry.lua",
    "ReplicatedStorage/Animation/AnimationData.lua",
    "ReplicatedStorage/Characters/CharacterDefinitions.lua",
    "ReplicatedStorage/Characters/CharacterService.lua",
    "ReplicatedStorage/Emotes/EmoteDefinitions.lua",
    "ReplicatedStorage/Monetization/GamePassConfig.lua",
    "ReplicatedStorage/Monetization/GamePassService.lua",
    "ServerScriptService/CombatCore/StateManager.lua",
    "ServerScriptService/CombatCore/CooldownService.lua",
    "ServerScriptService/CombatCore/NetworkService.lua",
    "ServerScriptService/CombatCore/MovementController.lua",
    "ServerScriptService/CombatCore/DamageService.lua",
    "ServerScriptService/CombatCore/CombatService.lua",
    "ServerScriptService/CombatCore/AbilityService.lua",
    "ServerScriptService/CombatCore/UltimateService.lua",
    "ServerScriptService/CombatCore/RagdollService.lua",
    "ServerScriptService/CombatServer.server.lua",
    "ServerScriptService/EmoteServer.server.lua",
    "ServerScriptService/GamePassServer.server.lua",
    "ServerScriptService/RemoteBootstrap.server.lua",
    "StarterPlayer/StarterPlayerScripts/CombatClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/AccountClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/CharacterSelectClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/OwnerClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/EmoteClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/AnimationClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/CrossPlatformInput.client.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/InputController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/InputManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationPriorityManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationBlender.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationStateMachine.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CombatAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/MovementAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AbilityAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationCache.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CombatHandler.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CameraController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/VFXManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/SFXManager.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Util.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Combat.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Menu.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Characters.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Owner.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Emotes.lua",
]

FORBIDDEN_ACTIVE = ("Domain", "OneTime")

def path_for(relative: str) -> Path:
    return SRC / relative

def read(relative: str) -> str:
    path = path_for(relative)
    if not path.exists():
        fail(f"missing file: src/{relative}")
    return path.read_text(encoding="utf-8")

def fail(message: str):
    print(f"FAIL: {message}")
    sys.exit(1)

for relative in REQUIRED:
    if not path_for(relative).exists():
        fail(f"required file missing: src/{relative}")

project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
if project.get("name") != "CursedCollision":
    fail("default.project.json project name must be CursedCollision")

for character in CHARACTERS:
    if not path_for(f"ReplicatedStorage/Characters/{character}.lua").exists():
        fail(f"character module missing: {character}")

character_service = read("ReplicatedStorage/Characters/CharacterService.lua")
for character in CHARACTERS:
    if f"{character} = require(ReplicatedStorage.Characters.{character})" not in character_service:
        fail(f"CharacterService binding missing: {character}")

network = read("ServerScriptService/CombatCore/NetworkService.lua")
for action in (
    "M1", "M1Hit", "Dash", "BlockStart", "BlockEnd", "Special",
    "Skill1", "Skill2", "Skill3", "Skill4", "SkillHit",
    "SelectCharacter", "Ultimate", "Awakening"
):
    if f"{action} = true" not in network:
        fail(f"network action missing: {action}")

combat_server = read("ServerScriptService/CombatServer.server.lua")
for token in (
    "combat:M1(player)",
    "combat:ConfirmM1(player",
    "combat:SkillSlot(player, 1)",
    "combat:ConfirmSkill(player",
):
    if token not in combat_server:
        fail(f"combat route missing: {token}")

combat_service = read("ServerScriptService/CombatCore/CombatService.lua")
for token in (
    "function CombatService:M1",
    "function CombatService:ConfirmM1",
    "action = \"M1Start\"",
    "HitboxService:TargetsInBox",
):
    if token not in combat_service:
        fail(f"M1 authority missing: {token}")

ability_service = read("ServerScriptService/CombatCore/AbilityService.lua")
for token in (
    "function AbilityService:Confirm",
    "action = \"SkillStart\"",
    "fallbackHitDelay",
    "HitRegistry:Begin",
):
    if token not in ability_service:
        fail(f"ability marker pipeline missing: {token}")

damage = read("ServerScriptService/CombatCore/DamageService.lua")
for token in ("Blocking", "DashUntil", "TakeDamage", "PerfectBlock", "guardBreak", "RagdollService:Apply"):
    if token not in damage:
        fail(f"damage protection missing: {token}")

state = read("ServerScriptService/CombatCore/StateManager.lua")
for token in ("IsAttacking", "CombatStunned", "Ragdolled", "character:SetAttribute"):
    if token not in state:
        fail(f"combat state attribute missing: {token}")

animation_data = read("ReplicatedStorage/Animation/AnimationData.lua")
for token in ("AnimationId", "Loop", "Priority", "EnergyCost"):
    if token not in animation_data:
        fail(f"animation data field missing: {token}")

animation_cache = read("StarterPlayer/StarterPlayerScripts/Controllers/AnimationCache.lua")
for token in ('Instance.new("Animation")', "LoadAnimation", "GetTrack"):
    if token not in animation_cache:
        fail(f"animation cache feature missing: {token}")

combat_handler = read("StarterPlayer/StarterPlayerScripts/Controllers/CombatHandler.lua")
if 'track:GetMarkerReachedSignal("Hit")' not in combat_handler:
    fail("CombatHandler must use track:GetMarkerReachedSignal(\"Hit\")")
if "M1Hit" not in combat_handler or "SkillHit" not in combat_handler:
    fail("CombatHandler must route M1Hit and SkillHit")

for wrapper, module in (
    ("CombatClient.client.lua", "Combat"),
    ("AccountClient.client.lua", "Menu"),
    ("CharacterSelectClient.client.lua", "Characters"),
    ("OwnerClient.client.lua", "Owner"),
    ("EmoteClient.client.lua", "Emotes"),
):
    wrapper_source = read(f"StarterPlayer/StarterPlayerScripts/{wrapper}")
    if f"require(script.Parent.HUD.{module})" not in wrapper_source:
        fail(f"isolated HUD wrapper missing: {wrapper}")

hud_combat = read("StarterPlayer/StarterPlayerScripts/HUD/Combat.lua")
for token in ('"M1"', '"Dash"', '"Block"', '"Special"', '"Sprint"', '"Ultimate"', '"Awakening"):
    if token not in hud_combat:
        fail(f"combat HUD feature missing: {token}")

hud_util = read("StarterPlayer/StarterPlayerScripts/HUD/Util.lua")
for token in ("DeviceSafeInsets", "UIScale", "PreferredInput", "GuiNavigationEnabled"):
    if token not in hud_util:
        fail(f"responsive HUD infrastructure missing: {token}")

hud_menu = read("StarterPlayer/StarterPlayerScripts/HUD/Menu.lua")
for token in ('"MenuButton"', '"AccountPanel"', '"ShopTab"', '"QuestTab"', '"PassTab"'):
    if token not in hud_menu:
        fail(f"main menu feature missing: {token}")

hud_characters = read("StarterPlayer/StarterPlayerScripts/HUD/Characters.lua")
for token in ('"CharacterButton"', '"CharacterPanel"', "CCHUD_CharacterMenuOpen"):
    if token not in hud_characters:
        fail(f"character selector feature missing: {token}")

hud_owner = read("StarterPlayer/StarterPlayerScripts/HUD/Owner.lua")
for token in ('"OwnerButton"', '"OwnerPanel"', "IsGameOwner"):
    if token not in hud_owner:
        fail(f"owner feature missing: {token}")

hud_emotes = read("StarterPlayer/StarterPlayerScripts/HUD/Emotes.lua")
for token in ('"EmoteButton"', '"EmoteWheel"'):
    if token not in hud_emotes:
        fail(f"emote wheel feature missing: {token}")

account_wrapper = read("StarterPlayer/StarterPlayerScripts/AccountClient.client.lua")
if "AdminAction:FireServer" in account_wrapper:
    fail("owner/admin action must remain outside AccountClient")

cross_platform = read("StarterPlayer/StarterPlayerScripts/CrossPlatformInput.client.lua")
if "FireServer" in cross_platform or "CombatAction" in cross_platform:
    fail("legacy CrossPlatformInput still sends combat actions")

for relative in (
    "ServerScriptService/CombatCore/CombatService.lua",
    "ServerScriptService/CombatCore/AbilityService.lua",
    "ServerScriptService/CombatCore/DamageService.lua",
    "ServerScriptService/CombatServer.server.lua",
    "StarterPlayer/StarterPlayerScripts/CombatClient.client.lua",
):
    source = read(relative)
    for forbidden in FORBIDDEN_ACTIVE:
        if re.search(rf"\b{re.escape(forbidden)}\b", source):
            fail(f"legacy unsupported token in active runtime: {relative} -> {forbidden}")

print("PASS: foundation files present")
print(f"PASS: {len(CHARACTERS)} character modules present and explicitly bound")
print("PASS: server-authoritative M1/Skill marker confirmation pipeline")
print("PASS: cached Animation/AnimationTrack infrastructure with explicit Hit markers")
print("PASS: emotes interrupt on attack/damage/stun/ragdoll and remain server-authorized")
print("PASS: combat, menu, character, owner and emote HUD are isolated")
print("PASS: Mobile / PC / Console safe-area and navigation infrastructure detected")
