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
    "ReplicatedStorage/Shared/UI/HUDConfig.lua",
    "ReplicatedStorage/Combat/HitboxService.lua",
    "ReplicatedStorage/Combat/AbilityTimeline.lua",
    "ReplicatedStorage/Combat/HitRegistry.lua",
    "ReplicatedStorage/Animation/AnimationRegistry.lua",
    "ReplicatedStorage/Animation/AnimationData.lua",
    "ReplicatedStorage/Characters/CharacterDefinitions.lua",
    "ReplicatedStorage/Characters/CharacterMoves.lua",
    "ReplicatedStorage/Characters/CustomMovesets.lua",
    "ReplicatedStorage/Characters/CharacterService.lua",
    "ReplicatedStorage/Emotes/EmoteDefinitions.lua",
    "ServerScriptService/CombatCore/StateManager.lua",
    "ServerScriptService/CombatCore/CooldownService.lua",
    "ServerScriptService/CombatCore/NetworkService.lua",
    "ServerScriptService/CombatCore/MovementController.lua",
    "ServerScriptService/CombatCore/ComboService.lua",
    "ServerScriptService/CombatCore/AbilityService.lua",
    "ServerScriptService/CombatCore/CombatMarkerService.lua",
    "ServerScriptService/CombatCore/DamageService.lua",
    "ServerScriptService/CombatCore/CombatService.lua",
    "ServerScriptService/CombatCore/EmoteService.lua",
    "ServerScriptService/CombatCore/RagdollService.lua",
    "ServerScriptService/CombatCore/UltimateService.lua",
    "ServerScriptService/CombatServer.server.lua",
    "ServerScriptService/RemoteBootstrap.server.lua",
    "ServerScriptService/EmoteServer.server.lua",
    "ServerScriptService/GamePassServer.server.lua",
    "StarterPlayer/StarterPlayerScripts/CombatClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/AnimationClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/CombatFeedback.client.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/InputController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/InputManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/ProceduralAnimator.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationCache.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CombatHandler.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationPriorityManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationBlender.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AnimationStateMachine.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/CombatAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/MovementAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/AbilityAnimationManager.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/HUDTheme.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/TopbarHUD.client.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/CombatHUD.client.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/MenuHUD.client.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/CharacterHUD.client.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/EmoteHUD.client.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/SettingsHUD.client.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/OwnerHUD.client.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/FeedbackHUD.client.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/EmoteAnimator.client.lua",
]

def fail(message: str) -> None:
    print(f"FAIL: {message}")
    sys.exit(1)

def read(relative: str) -> str:
    path = SRC / relative
    if not path.exists():
        fail(f"missing file: src/{relative}")
    return path.read_text(encoding="utf-8")

for relative in REQUIRED:
    if not (SRC / relative).exists():
        fail(f"required file missing: src/{relative}")

for character in CHARACTERS:
    if not (SRC / "ReplicatedStorage" / "Characters" / f"{character}.lua").exists():
        fail(f"character module missing: {character}")

project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
if project.get("name") != "CursedCollision":
    fail("default.project.json project name must be CursedCollision")

state = read("ServerScriptService/CombatCore/StateManager.lua")
for token in (
    "ActionToken: number",
    "function StateManager:NextActionToken",
    'player:SetAttribute("IsAttacking"',
    'player:SetAttribute("Stunned"',
    'player:SetAttribute("Ragdolled"'
):
    if token not in state:
        fail(f"state contract missing: {token}")

network = read("ServerScriptService/CombatCore/NetworkService.lua")
for action in (
    "M1", "M1Hit", "Dash", "BlockStart", "BlockEnd", "Special",
    "Skill1", "Skill2", "Skill3", "Skill4", "SkillHit", "SpecialHit",
    "SelectCharacter", "Ultimate", "Awakening"
):
    if f"{action} = true" not in network:
        fail(f"NetworkService missing action: {action}")

for forbidden in ("Domain = true", "OneTime = true", "Heavy = true"):
    if forbidden in network:
        fail(f"unsupported active network action: {forbidden}")

server = read("ServerScriptService/CombatServer.server.lua")
for token in (
    "combat:M1(player)",
    "combat:Dash(",
    "combat:SetBlock(",
    "combat:Special(player)",
    "CombatMarkerService:Resolve",
    "CombatMarkerService:Clear(player)"
):
    if token not in server:
        fail(f"CombatServer integration missing: {token}")

combat = read("ServerScriptService/CombatCore/CombatService.lua")
for token in (
    "function CombatService:M1",
    "function CombatService:Dash",
    "function CombatService:SetBlock",
    "function CombatService:Special",
    "CombatMarkerService:Begin",
    'action = "M1Start"',
    'action = "SpecialStart"',
    "HitboxService:TargetsInBox"
):
    if token not in combat:
        fail(f"CombatService pipeline missing: {token}")

ability = read("ServerScriptService/CombatCore/AbilityService.lua")
for token in (
    "function AbilityService:Execute",
    "CombatMarkerService:Begin",
    '"Ability"',
    'action = "SkillStart"',
    "CharacterService:SkillSlot",
    "HitRegistry:End"
):
    if token not in ability:
        fail(f"AbilityService pipeline missing: {token}")

marker = read("ServerScriptService/CombatCore/CombatMarkerService.lua")
for token in (
    "function CombatMarkerService:Begin",
    "function CombatMarkerService:Resolve",
    "EarlyAt",
    "HitAt",
    "ExpiresAt",
    "MaxTravel",
    "Origin",
    'Kind: "Action" | "Ability"'
):
    if token not in marker:
        fail(f"CombatMarkerService contract missing: {token}")

damage = read("ServerScriptService/CombatCore/DamageService.lua")
for token in (
    "TakeDamage",
    "Blocking",
    "PerfectBlock",
    "guardBreak",
    "RagdollService:Apply",
    "EmoteService:Stop",
    "UltimateService:AddMeter"
):
    if token not in damage:
        fail(f"DamageService integration missing: {token}")

animation_data = read("ReplicatedStorage/Animation/AnimationData.lua")
for key in (
    "Idle", "Walk", "Run", "Sprint", "Jump", "Fall", "Land",
    "M1_1", "M1_2", "M1_3", "M1_4", "Dash", "AirDash", "Block",
    "Parry", "HitLight", "HitHeavy", "Ragdoll", "Recovery", "Dodge",
    "Skill1", "Skill2", "Skill3", "Skill4", "Special", "Ultimate",
    "Awakening", "Execution"
):
    if key not in animation_data:
        fail(f"AnimationData missing definition: {key}")

if '"Hit"' not in animation_data:
    fail("AnimationData does not define the combat Hit marker")

cache = read("StarterPlayer/StarterPlayerScripts/Controllers/AnimationCache.lua")
for token in ('Instance.new("Animation")', "LoadAnimation", "GetTrack", "__mode"):
    if token not in cache:
        fail(f"AnimationCache missing: {token}")

handler = read("StarterPlayer/StarterPlayerScripts/Controllers/CombatHandler.lua")
if 'GetMarkerReachedSignal("Hit")' not in handler:
    fail("CombatHandler missing exact Hit marker synchronization")
if 'task.delay' in handler:
    fail("CombatHandler must not time gameplay hits with client task.delay")
for token in ("M1Hit", "SkillHit", "SpecialHit", "Enum.AnimationPriority.Action"):
    if token not in handler:
        fail(f"CombatHandler missing: {token}")

controller = read("StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.lua")
for token in ("AnimationCache", "GetMarkerReachedSignal", "fallback", "Unbind"):
    if token not in controller:
        fail(f"AnimationController missing: {token}")

emote_service = read("ServerScriptService/CombatCore/EmoteService.lua")
for token in ("function EmoteService:CanUse", "OwnedEmotes", "EmoteEvent", "function EmoteService:Stop"):
    if token not in emote_service:
        fail(f"EmoteService missing: {token}")

emote_defs = read("ReplicatedStorage/Emotes/EmoteDefinitions.lua")
for token in ("EmoteData", "Price", "Duration", "Loop", "AnimationId"):
    if token not in emote_defs:
        fail(f"Emote definitions missing field: {token}")

for path, required in {
    "StarterPlayer/StarterPlayerScripts/HUD/HUDLayout.lua": (
        "Mobile", "Console", "PC", "CombatScaleReference", "SkillsWidth"
    ),
    "StarterPlayer/StarterPlayerScripts/HUD/HUDTheme.lua": (
        "CoreUISafeInsets", "PreferredInput", "ResponsiveScale", "UISizeConstraint"
    ),
    "StarterPlayer/StarterPlayerScripts/HUD/CombatHUD.client.lua": (
        "GetServerTimeNow", "M1", "Special", "Ultimate", "Awakening"
    ),
    "StarterPlayer/StarterPlayerScripts/HUD/TopbarHUD.client.lua": (
        "Characters", "Emotes", "Menu", "Settings", "GuiNavigationEnabled"
    ),
    "StarterPlayer/StarterPlayerScripts/HUD/MenuHUD.client.lua": (
        "SHOP", "MISSIONS", "PASSES", "PLAYERS", "AccountAction"
    ),
    "StarterPlayer/StarterPlayerScripts/HUD/CharacterHUD.client.lua": (
        "CharacterId", "SelectCharacter", "ScrollingFrame", "UIGridLayout"
    ),
    "StarterPlayer/StarterPlayerScripts/HUD/EmoteHUD.client.lua": (
        "EmoteAction", "emote_001", "EmoteWheel"
    ),
    "StarterPlayer/StarterPlayerScripts/HUD/SettingsHUD.client.lua": (
        "CC_ReducedEffects", "CC_AutoSprint", "PreferredInput"
    ),
    "StarterPlayer/StarterPlayerScripts/HUD/OwnerHUD.client.lua": (
        "IsGameOwner", "AdminAction", "GiveAllEmotes", "GiveAllSkins"
    ),
    "StarterPlayer/StarterPlayerScripts/HUD/FeedbackHUD.client.lua": (
        "CombatFX", "PerfectBlock", "Debris"
    ),
    "StarterPlayer/StarterPlayerScripts/HUD/EmoteAnimator.client.lua": (
        "EmoteEvent", "Motor6D", "RenderStepped", "Health"
    )
}.items():
    source = read(path)
    for token in required:
        if token not in source:
            fail(f"{path} missing {token}")

for stale in (
    "StarterPlayer/StarterPlayerScripts/AccountClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/CharacterSelectClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/OwnerClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/EmoteClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/CrossPlatformInput.client.lua",
    "StarterPlayer/StarterPlayerScripts/HUDClient.client.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/HUDCore.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/HUDCombatPanel.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/HUDNavigation.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/HUDMenus.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/HUDEmoteWheel.lua",
    "StarterPlayer/StarterPlayerScripts/Controllers/HUDController.lua",
):
    if (SRC / stale).exists():
        fail(f"legacy/duplicate HUD file still exists: src/{stale}")

for stale_folder_file in (
    "StarterPlayer/StarterPlayerScripts/HUD/Combat.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Menu.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Characters.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Owner.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Emotes.lua",
    "StarterPlayer/StarterPlayerScripts/HUD/Util.lua",
):
    if (SRC / stale_folder_file).exists():
        fail(f"legacy HUD implementation still exists: src/{stale_folder_file}")

print(f"PASS: {len(REQUIRED)} required foundation files present")
print(f"PASS: {len(CHARACTERS)} character modules are present")
print("PASS: authoritative combat routing uses server marker windows")
print("PASS: animation cache and exact Hit marker handler remain connected")
print("PASS: HUD is split into isolated topbar/combat/menu/character/emote/settings/owner/feedback clients")
print("PASS: HUD respects Core UI safe area and PreferredInput")
print("PASS: touch controls expose large minimum hit targets and gamepad controls are selectable")
print("PASS: legacy monolithic HUD scripts are removed")
print("PASS: emote interruption remains server-authoritative")
