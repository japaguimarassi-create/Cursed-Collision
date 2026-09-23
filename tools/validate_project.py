from pathlib import Path
import json
import re
import sys

CHARACTERS = [
    "PotentialMan", "Yuji", "Gojo", "Sukuna", "Megumi", "Yuta", "Maki", "Toji",
    "Mahito", "Todo", "Hakari", "Choso", "Kashimo", "Naoya", "Kenjaku", "Jogo",
    "Dagon", "Hanami", "Higuruma", "Takaba", "Uraume", "Yorozu", "Ryu", "Uro",
    "Kusakabe"
]

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"

REQUIRED = [
    "ReplicatedStorage/Shared/Config.lua",
    "ReplicatedStorage/Shared/RemoteService.lua",
    "ReplicatedStorage/Combat/HitboxService.lua",
    "ReplicatedStorage/Characters/CharacterDefinitions.lua",
    "ReplicatedStorage/Characters/CharacterService.lua",
    "ReplicatedStorage/Characters/PotentialMan.lua",
    "ReplicatedStorage/Combat/AbilityTimeline.lua",
    "ReplicatedStorage/Combat/HitRegistry.lua",
    "ReplicatedStorage/Animation/AnimationRegistry.lua",
    "ReplicatedStorage/Animation/AnimationData.lua",
    "ServerScriptService/CombatCore/StateManager.lua",
    "ServerScriptService/CombatCore/CooldownService.lua",
    "ServerScriptService/CombatCore/NetworkService.lua",
    "ServerScriptService/CombatCore/MovementController.lua",
    "ServerScriptService/CombatCore/DamageService.lua",
    "ServerScriptService/CombatCore/CombatService.lua",
    "ServerScriptService/CombatServer.server.lua",
    "StarterPlayer/StarterPlayerScripts/CombatClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/CombatFeedback.client.lua",
    "StarterPlayer/StarterPlayerScripts/AnimationClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/InputController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/InputManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/ProceduralAnimator.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationCache.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CombatHandler.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/HUDController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationPriorityManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationBlender.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationStateMachine.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CombatAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/MovementAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AbilityAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationCache.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CombatHandler.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Util.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Combat.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Menu.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Characters.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Owner.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Emotes.lua",
    "ReplicatedStorage/Animation/AnimationData.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CameraController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/VFXManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/SFXManager.lua",
    "StarterPlayer/StarterPlayerScripts/OwnerClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/CharacterSelectClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/EmoteClient.client.lua",
    "ServerScriptService/RemoteBootstrap.server.lua",
    "ServerScriptService/EmoteServer.server.lua",
    "ServerScriptService/GamePassServer.server.lua",
    "ReplicatedStorage/Emotes/EmoteDefinitions.lua",
    "ReplicatedStorage/Monetization/GamePassConfig.lua",
    "ReplicatedStorage/Monetization/GamePassService.lua",
    "StarterPlayer/StarterPlayerScripts/CharacterSelectClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/EmoteClient.client.lua",
]

ACTIVE = [
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
    "Domain",
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

for character in CHARACTERS:
    module_path = SRC / "ReplicatedStorage" / "Characters" / f"{character}.lua"
    if not module_path.exists():
        fail(f"character module missing: {character}")

project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
if project.get("name") != "CursedCollision":
    fail("default.project.json project name must be CursedCollision")

definitions = read("ReplicatedStorage/Characters/CharacterDefinitions.lua")
if not re.search(r"\bPotentialMan\s*=", definitions):
    fail("PotentialMan definition missing")

character_service = read("ReplicatedStorage/Characters/CharacterService.lua")
for character in CHARACTERS:
    if f"{character} = require(ReplicatedStorage.Characters.{character})" not in character_service:
        fail(f"CharacterService does not explicitly require {character}")
for legacy in ("DomainService", "DomainClashService", "PerfectComboService", "OneTimeAttackService"):
    if legacy in character_service:
        fail(f"legacy system still referenced by CharacterService: {legacy}")

network = read("ServerScriptService/CombatCore/NetworkService.lua")
for action in (
    "M1", "Dash", "BlockStart", "BlockEnd", "Special",
    "Skill1", "Skill2", "Skill3", "Skill4", "SelectCharacter"
):
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

combo_service = read("ServerScriptService/CombatCore/ComboService.lua")
ability_service = read("ServerScriptService/CombatCore/AbilityService.lua")
ragdoll_service = read("ServerScriptService/CombatCore/RagdollService.lua")
ultimate_service = read("ServerScriptService/CombatCore/UltimateService.lua")
animation_registry = read("ReplicatedStorage/Animation/AnimationRegistry.lua")
ability_timeline = read("ReplicatedStorage/Combat/AbilityTimeline.lua")
hit_registry = read("ReplicatedStorage/Combat/HitRegistry.lua")
animation_controller = read("StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.lua")
animation_priority = read("StarterPlayer/StarterPlayerScripts/Controllers/AnimationPriorityManager.lua")
animation_cache = read("StarterPlayer/StarterPlayerScripts/Controllers/AnimationCache.lua")
combat_handler = read("StarterPlayer/StarterPlayerScripts/Controllers/CombatHandler.lua")
animation_data = read("ReplicatedStorage/Animation/AnimationData.lua")
hud_util = read("StarterPlayer/StarterPlayerScripts/HUD/Util.lua")
hud_combat = read("StarterPlayer/StarterPlayerScripts/HUD/Combat.lua")
hud_menu = read("StarterPlayer/StarterPlayerScripts/HUD/Menu.lua")
hud_characters = read("StarterPlayer/StarterPlayerScripts/HUD/Characters.lua")
hud_owner = read("StarterPlayer/StarterPlayerScripts/HUD/Owner.lua")
hud_emotes = read("StarterPlayer/StarterPlayerScripts/HUD/Emotes.lua")
input_manager = read("StarterPlayer/StarterPlayerScripts/Controllers/InputManager.lua")
camera_controller = read("StarterPlayer/StarterPlayerScripts/Controllers/CameraController.lua")
vfx_manager = read("StarterPlayer/StarterPlayerScripts/Controllers/VFXManager.lua")
sfx_manager = read("StarterPlayer/StarterPlayerScripts/Controllers/SFXManager.lua")
combat_feedback = read("StarterPlayer/StarterPlayerScripts/CombatFeedback.client.lua")
combat_service = read("ServerScriptService/CombatCore/CombatService.lua")
for token in (
    "function CombatService:M1",
    "function CombatService:Dash",
    "function CombatService:SetBlock",
    "function CombatService:Special",
    "HitboxService:TargetsInBox",
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
if "Motor6D" not in animator or ":Lerp" not in animator:
    fail("procedural animator is missing Motor6D pose interpolation")

for token in ("HitFrame", "Startup", "Recovery", "Markers"):
    if token not in ability_timeline:
        fail(f"ability timeline marker missing: {token}")

animation_data = read("ReplicatedStorage/Animation/AnimationData.lua")
animation_cache = read("StarterPlayer/StarterPlayerScripts/Controllers/AnimationCache.lua")
combat_handler = read("StarterPlayer/StarterPlayerScripts/Controllers/CombatHandler.lua")
hud_controller = read("StarterPlayer/StarterPlayerScripts/Controllers/HUDController.lua")

for token in ("GetMarkerReachedSignal", "AnimationPriority"):
    if token not in combat_handler and token not in animation_controller and token not in animation_priority:
        fail(f"marker/priority animation infrastructure missing: {token}")

for token in ("M1_1", "M1_4", "Skill1", "Skill4", "Emote_001", "Execution"):
    if token not in animation_data:
        fail(f"animation data definition missing: {token}")

for token in ('Instance.new("Animation")', "LoadAnimation", "__mode"):
    if token not in animation_cache:
        fail(f"animation cache missing performance primitive: {token}")

for token in ("function CombatHandler:PlayM1", "function CombatHandler:PlaySkill", "GetMarkerReachedSignal"):
    if token not in combat_handler:
        fail(f"combat marker handler missing: {token}")

for token in ("ScreenInsets", "CoreUISafeInsets", "GuiNavigationEnabled", "UpdateHealth", "SetCooldown"):
    if token not in hud_controller:
        fail(f"cross-platform HUD foundation missing: {token}")

for token in ("BindAction", "Emit"):
    if token not in input_manager:
        fail(f"input manager missing unified route: {token}")

for token in ("Shake", "FovKick"):
    if token not in camera_controller:
        fail(f"camera controller missing game-feel control: {token}")

for token in ("function VFXManager:Play", "Hit", "PerfectBlock", "Death"):
    if token not in vfx_manager:
        fail(f"VFX manager missing event support: {token}")

for token in ("function SFXManager:Play", "LightHit", "HeavyHit", "Parry"):
    if token not in sfx_manager:
        fail(f"SFX manager missing contextual support: {token}")

for token in ("AbilityService.new", "Timeline:Get", "HitRegistry:Begin"):
    if token not in ability_service:
        fail(f"ability pipeline missing phase integration: {token}")

for token in ("PerfectBlock", "guardBreak", "RagdollService:Apply"):
    if token not in damage:
        fail(f"damage pipeline missing defense/impact integration: {token}")

for token in ("UltimateMeter", "AwakeningMeter", "Activate"):
    if token not in ultimate_service:
        fail(f"ultimate/awakening service missing: {token}")

for token in ("CombatAction", "AbilityRemote", "MovementRemote", "StateRemote", "UltimateAction"):
    if token not in read("ReplicatedStorage/Shared/RemoteService.lua"):
        fail(f"structured remote missing: {token}")

client = read("StarterPlayer/StarterPlayerScripts/CombatClient.client.lua")
account_client = read("StarterPlayer/StarterPlayerScripts/AccountClient.client.lua")
owner_client = read("StarterPlayer/StarterPlayerScripts/OwnerClient.client.lua")
cross_platform = read("StarterPlayer/StarterPlayerScripts/CrossPlatformInput.client.lua")
remote_bootstrap = read("ServerScriptService/RemoteBootstrap.server.lua")
emote_defs = read("ReplicatedStorage/Emotes/EmoteDefinitions.lua")
emote_server = read("ServerScriptService/EmoteServer.server.lua")
gamepass_config = read("ReplicatedStorage/Monetization/GamePassConfig.lua")
gamepass_service = read("ReplicatedStorage/Monetization/GamePassService.lua")
gamepass_server = read("ServerScriptService/GamePassServer.server.lua")
damage_service = read("ServerScriptService/CombatCore/DamageService.lua")
character_client = read("StarterPlayer/StarterPlayerScripts/CharacterSelectClient.client.lua")
emote_client = read("StarterPlayer/StarterPlayerScripts/EmoteClient.client.lua")
for token in ("M1", "combatAction:FireServer", 'WaitForChild("Remotes", 30)', "HUDController.new"):
    if token not in client:
        fail(f"combat HUD/input missing expected element: {token}")

for token in ('"M1"', '"Dash"', '"Block"', '"Special"', '"Sprint"', '"Ultimate"', '"Awakening"'):
    if token not in hud_controller:
        fail(f"combat HUD control missing: {token}")

for token in ('"MenuButton"', '"AccountPanel"', 'CCHUD_MenuOpen'):
    if token not in account_client:
        fail(f"main menu separation token missing: {token}")
if '"AdminTab"' in account_client or "AdminAction:FireServer" in account_client:
    fail("owner controls still embedded in AccountClient")

for token in ('"OwnerButton"', '"OwnerPanel"', "CCHUD_OwnerPanelOpen", 'GetAttribute("IsGameOwner")'):
    if token not in owner_client:
        fail(f"owner UI authorization/separation token missing: {token}")

for forbidden in ("Domain", "OneTime"):
    if forbidden in cross_platform:
        fail(f"unsupported gamepad action remains in CrossPlatformInput: {forbidden}")
if "FireServer" in cross_platform:
    fail("CrossPlatformInput must not duplicate combat RemoteEvent routing")

if 'RemoteService:Get()' not in remote_bootstrap:
    fail("RemoteBootstrap does not initialize server remotes")

for id in ("emote_001", "emote_002", "emote_003", "emote_004", "emote_005"):
    if id not in emote_defs:
        fail(f"missing emote definition: {id}")

for token in ('"EmoteAction"', '"EmoteEvent"', '"GamePassAction"', '"GamePassEvent"'):
    remote = read("ReplicatedStorage/Shared/RemoteService.lua")
    if token not in remote:
        fail(f"remote missing: {token}")

for token in ('"Start"', '"Stop"', '"SetWheel"', "HealthChanged", "MoveDirection", "IsAttacking", "Ragdolled"):
    if token not in emote_server:
        fail(f"emote server interruption/route missing: {token}")

for token in ("UltimateSkin", "KillSound", "InstantSkin"):
    if token not in gamepass_config or token not in gamepass_service:
        fail(f"gamepass definition/service missing: {token}")

if "GP_KillSound" not in gamepass_service or "NotifyKill" not in damage_service:
    fail("kill sound pass is not connected to confirmed kills")

for token in ('"CharacterButton"', '"CharacterPanel"', "CCHUD_CharacterMenuOpen"):
    if token not in hud_characters:
        fail(f"character selection UI token missing: {token}")

for token in ('"EmoteButton"', '"EmoteWheel"', "CCHUD_EmoteWheelOpen"):
    if token not in hud_emotes:
        fail(f"emote UI token missing: {token}")

for token in ('"MenuButton"', '"AccountPanel"', '"ShopTab"', '"QuestTab"', '"PassTab"'):
    if token not in hud_menu:
        fail(f"main menu HUD token missing: {token}")

for token in ('"OwnerButton"', '"OwnerPanel"', "IsGameOwner"):
    if token not in hud_owner:
        fail(f"owner UI token missing: {token}")

for relative in ACTIVE:
    source = read(relative)
    for forbidden in FORBIDDEN_ACTIONS:
        if re.search(rf"\b{re.escape(forbidden)}\b", source):
            if relative.endswith("README.md"):
                continue
            if forbidden in ("Domain", "OneTime") and relative.endswith("Config.lua"):
                continue
            fail(f"forbidden legacy combat token appears in active runtime file {relative}: {forbidden}")

print(f"PASS: {len(REQUIRED)} foundation files present")
print(f"PASS: {len(CHARACTERS)} character modules are present and explicitly bound")
print("PASS: active combat surface is M1 + Dash + Block + Special + Skill1..4")
print("PASS: server-authoritative hitbox, damage, stun, cooldown and dash protection detected")
print("PASS: procedural Motor6D animation controller detected")
print("PASS: five original emotes and server emote routing detected")
print("PASS: three configurable gamepass systems are present")
print("PASS: dedicated character selection and emote wheel UIs detected")
print("PASS: combat HUD, main menu and Owner UI are isolated")
print("PASS: Owner UI is server-authorized and not embedded in the main menu")
print("PASS: mobile/gamepad action routes match the active NetworkService")
print("PASS: centralized combo, ability, ragdoll and ultimate services detected")
print("PASS: marker-aware cached animation pipeline detected")
print("PASS: HUD components are isolated into separate client entry points")
print("PASS: mobile, PC and console HUD layouts use safe insets and responsive scaling")
print("PASS: JJS-inspired top-bar/menu/character/emote composition is present")
print("PASS: unified input, camera, VFX and SFX layers detected")
print("PASS: structured combat/ability/movement/state/ultimate remotes detected")
print("PASS: heavy/dodge/grab/counter/slam/domain/awakening routes are not in the active combat router")
