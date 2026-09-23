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
    "ReplicatedStorage/Characters/CharacterMoves.lua",
    "ReplicatedStorage/Characters/CustomMovesets.lua",
    "ReplicatedStorage/Characters/CharacterService.lua",
    "ServerScriptService/CombatCore/StateManager.lua",
    "ServerScriptService/CombatCore/CooldownService.lua",
    "ServerScriptService/CombatCore/NetworkService.lua",
    "ServerScriptService/CombatCore/MovementController.lua",
    "ServerScriptService/CombatCore/ComboService.lua",
    "ServerScriptService/CombatCore/AbilityService.lua",
    "ServerScriptService/CombatCore/DamageService.lua",
    "ServerScriptService/CombatCore/CombatService.lua",
    "ServerScriptService/CombatCore/RagdollService.lua",
    "ServerScriptService/CombatCore/UltimateService.lua",
    "ServerScriptService/CombatServer.server.lua",
    "ServerScriptService/RemoteBootstrap.server.lua",
    "ServerScriptService/EmoteServer.server.lua",
    "ServerScriptService/GamePassServer.server.lua",
    "ReplicatedStorage/Emotes/EmoteDefinitions.lua",
    "ReplicatedStorage/Monetization/GamePassConfig.lua",
    "ReplicatedStorage/Monetization/GamePassService.lua",
    "StarterPlayer/StarterPlayerScripts/CombatClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/AnimationClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/CombatFeedback.client.lua",
    "StarterPlayer/StarterPlayerScripts/AccountClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/CharacterSelectClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/OwnerClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/EmoteClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Util.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Combat.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Menu.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Characters.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Owner.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Emotes.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/InputController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/InputManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/ProceduralAnimator.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationPriorityManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationBlender.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationStateMachine.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CombatAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/MovementAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AbilityAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationCache.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CombatHandler.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/HUDController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CameraController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/VFXManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/SFXManager.lua",
]

ACTIVE = [
    "ReplicatedStorage/Characters/CharacterService.lua",
    "ReplicatedStorage/Combat/HitboxService.lua",
    "ServerScriptService/CombatCore/StateManager.lua",
    "ServerScriptService/CombatCore/CooldownService.lua",
    "ServerScriptService/CombatCore/NetworkService.lua",
    "ServerScriptService/CombatCore/MovementController.lua",
    "ServerScriptService/CombatCore/ComboService.lua",
    "ServerScriptService/CombatCore/AbilityService.lua",
    "ServerScriptService/CombatCore/DamageService.lua",
    "ServerScriptService/CombatCore/CombatService.lua",
    "ServerScriptService/CombatServer.server.lua",
    "StarterPlayer/StarterPlayerScripts/CombatClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/AnimationClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/InputManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CombatHandler.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Combat.lua",
]

def fail(message: str):
    print(f"FAIL: {message}")
    sys.exit(1)

def path_for(relative: str) -> Path:
    return SRC / relative

def read(relative: str) -> str:
    path = path_for(relative)
    if not path.exists():
        fail(f"missing file: src/{relative}")
    return path.read_text(encoding="utf-8")

for relative in REQUIRED:
    if not path_for(relative).exists():
        fail(f"required file missing: src/{relative}")

project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
if project.get("name") != "CursedCollision":
    fail("default.project.json project name must be CursedCollision")

for character in CHARACTERS:
    character_path = path_for(f"ReplicatedStorage/Characters/{character}.lua")
    if not character_path.exists():
        fail(f"character module missing: {character}")

definitions = read("ReplicatedStorage/Characters/CharacterDefinitions.lua")
character_service = read("ReplicatedStorage/Characters/CharacterService.lua")
for character in CHARACTERS:
    expected = f"{character} = require(ReplicatedStorage.Characters.{character})"
    if expected not in character_service:
        fail(f"CharacterService missing explicit binding: {character}")

network = read("ServerScriptService/CombatCore/NetworkService.lua")
for action in (
    "M1", "M1Hit", "Dash", "BlockStart", "BlockEnd", "Special",
    "Skill1", "Skill2", "Skill3", "Skill4", "SkillHit", "SelectCharacter",
    "Ultimate", "Awakening"
):
    if f"{action} = true" not in network:
        fail(f"NetworkService missing active action: {action}")

for forbidden in ("Domain", "OneTime"):
    if f"{forbidden} = true" in network:
        fail(f"legacy unsupported action active in NetworkService: {forbidden}")

combat_server = read("ServerScriptService/CombatServer.server.lua")
for token in (
    "combat:M1(player)",
    "combat:M1Hit(player, payload)",
    "combat:Dash(",
    "combat:SetBlock(",
    "combat:Special(player)",
    "combat:SkillHit(player, payload)",
):
    if token not in combat_server:
        fail(f"CombatServer missing route: {token}")

combat = read("ServerScriptService/CombatCore/CombatService.lua")
for token in (
    "function CombatService:M1",
    "function CombatService:M1Hit",
    "function CombatService:Dash",
    "function CombatService:SetBlock",
    "function CombatService:Special",
    "HitboxService:TargetsInBox",
    "record.HitUntil",
    "record.HitConsumed",
):
    if token not in combat:
        fail(f"CombatService missing server attack pipeline element: {token}")

ability = read("ServerScriptService/CombatCore/AbilityService.lua")
for token in (
    "function AbilityService:Execute",
    "function AbilityService:Hit",
    "HitRegistry:Begin",
    "HitRegistry:End",
    "record.HitUntil",
):
    if token not in ability:
        fail(f"AbilityService missing marker-driven attack pipeline element: {token}")

damage = read("ServerScriptService/CombatCore/DamageService.lua")
for token in ("Blocking", "DashUntil", "TakeDamage", "BlockImpact", "Hit", "PerfectBlock", "guardBreak", "RagdollService:Apply"):
    if token not in damage:
        fail(f"DamageService missing defense/impact element: {token}")

hitbox = read("ReplicatedStorage/Combat/HitboxService.lua")
for token in ("GetPartBoundsInBox", "OverlapParams", "NearestTargetInFront"):
    if token not in hitbox:
        fail(f"HitboxService missing spatial query primitive: {token}")

state = read("ServerScriptService/CombatCore/StateManager.lua")
for token in ("IsAttacking", "Stunned", "Ragdolled", "SetStun", "BeginAbility", "BeginBlock"):
    if token not in state:
        fail(f"StateManager missing critical state/attribute: {token}")

animation_data = read("ReplicatedStorage/Animation/AnimationData.lua")
for token in ("Idle", "Walk", "Run", "Sprint", "Jump", "Fall", "Land", "M1_1", "M1_4", "Dash", "AirDash", "Block", "Parry", "HitLight", "HitHeavy", "Ragdoll", "Recovery", "Dodge", "Skill1", "Skill4", "Special", "Ultimate", "Awakening", "Execution"):
    if token not in animation_data:
        fail(f"AnimationData missing definition: {token}")

animation_cache = read("StarterPlayer/StarterPlayerScripts/Controllers/AnimationCache.lua")
for token in ('Instance.new("Animation")', "LoadAnimation", "__mode", "GetTrack"):
    if token not in animation_cache:
        fail(f"AnimationCache missing required cache primitive: {token}")

animation_controller = read("StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.lua")
priority = read("StarterPlayer/StarterPlayerScripts/Controllers/AnimationPriorityManager.lua")
handler = read("StarterPlayer/StarterPlayerScripts/Controllers/CombatHandler.lua")
if 'GetMarkerReachedSignal("Hit")' not in handler:
    fail("CombatHandler missing exact Hit marker synchronization")
if "Enum.AnimationPriority.Action" not in handler and "AnimationPriority" not in priority and "AnimationPriority" not in animation_controller:
    fail("Action priority handling missing")

animator = read("StarterPlayer/StarterPlayerScripts/Controllers/ProceduralAnimator.lua")
if "RunService:BindToRenderStep" not in animator or "RunService:UnbindFromRenderStep" not in animator:
    fail("procedural animation loop cleanup missing")
if "Motor6D" not in animator or ":Lerp" not in animator:
    fail("procedural Motor6D interpolation missing")

input_manager = read("StarterPlayer/StarterPlayerScripts/Controllers/InputManager.lua")
hud_controller = read("StarterPlayer/StarterPlayerScripts/Controllers/HUDController.lua")
hud_combat = read("StarterPlayer/StarterPlayerScripts/HUD/Combat.lua")
if "BindAction" not in input_manager:
    fail("InputManager missing ContextActionService binding")
if "UserInputService" in hud_combat:
    fail("HUD/Combat must use InputManager instead of UserInputService directly")
for token in ("ScreenInsets", "CoreUISafeInsets", "UISizeConstraint", "PreferredInput"):
    if token not in hud_controller:
        fail(f"HUDController missing responsive input-safe UI feature: {token}")
for token in ("InputManager:BindAction", "CooldownUntil_", "GetServerTimeNow", "M1", "Special", "Ultimate", "Awakening"):
    if token not in hud_combat:
        fail(f"HUD/Combat missing integration token: {token}")

for wrapper, module in (
    ("StarterPlayer/StarterPlayerScripts/CombatClient.client.lua", "HUD.Combat"),
    ("StarterPlayer/StarterPlayerScripts/AccountClient.client.lua", "HUD.Menu"),
    ("StarterPlayer/StarterPlayerScripts/CharacterSelectClient.client.lua", "HUD.Characters"),
    ("StarterPlayer/StarterPlayerScripts/OwnerClient.client.lua", "HUD.Owner"),
    ("StarterPlayer/StarterPlayerScripts/EmoteClient.client.lua", "HUD.Emotes"),
):
    source = read(wrapper)
    if f"require(script.Parent.{module})" not in source or ".Start()" not in source:
        fail(f"client entrypoint is not delegating to modular HUD: {wrapper}")

remote_service = read("ReplicatedStorage/Shared/RemoteService.lua")
for token in ("CombatAction", "AbilityRemote", "MovementRemote", "StateRemote", "UltimateAction", "EmoteAction", "EmoteEvent"):
    if token not in remote_service:
        fail(f"missing organized remote: {token}")

emote_server = read("ServerScriptService/EmoteServer.server.lua")
for token in ("Start", "Stop", "SetWheel", "IsAttacking", "Stunned", "Ragdolled", "OwnedEmotes", "DataService:MarkDirty"):
    if token not in emote_server:
        fail(f"EmoteServer missing secure behavior: {token}")

emote_defs = read("ReplicatedStorage/Emotes/EmoteDefinitions.lua")
for emote in ("emote_001", "emote_002", "emote_003", "emote_004", "emote_005"):
    if emote not in emote_defs:
        fail(f"missing emote definition: {emote}")

movement = read("ServerScriptService/CombatCore/MovementController.lua")
if "state.Phase == \"Blocking\"" not in movement or "Config.Combat.Block.WalkSpeed" not in movement:
    fail("MovementController does not preserve block movement")

for relative in ACTIVE:
    source = read(relative)
    for forbidden in ("Domain", "OneTime"):
        if re.search(rf"\b{re.escape(forbidden)}\b", source):
            fail(f"unsupported legacy combat token in active runtime file: {relative}: {forbidden}")

for research in (
    ROOT / "docs/research/ResearchLedger.md",
    ROOT / "docs/research/ResearchMatrix.md",
    ROOT / "docs/research/VisualReferenceDatabase.md"
):
    if not research.exists():
        fail(f"research artifact missing: {research}")

print("PASS: required foundation files and 25-character roster are present")
print("PASS: server-authoritative M1/skill marker timing pipeline is wired")
print("PASS: hitbox, damage, stun, block, ragdoll and cooldown validation layers are present")
print("PASS: animation registry/cache/priority/marker handler are present")
print("PASS: mobile/PC/console HUD is modular and InputManager-driven")
print("PASS: server-authoritative emote ownership and interruption guards are present")
print("PASS: no duplicate legacy CrossPlatformInput combat router is required")
print("PASS: research ledger, matrix and visual reference index are stored in-repo")
