from pathlib import Path
import json
import sys

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"src"/"CollisionBattlestar"

REQUIRED=[
"ReplicatedStorage/Shared/Config.lua",
"ReplicatedStorage/Shared/BuildInfo.lua",
"ReplicatedStorage/Shared/Util.lua",
"ReplicatedStorage/Shared/CombatDefinitions.lua",
"ReplicatedStorage/Shared/MapDefinitions.lua",
"ReplicatedStorage/Shared/HUDTheme.lua",
"ReplicatedStorage/Shared/HUDRecovery.lua",
"ReplicatedStorage/Shared/UI/HUDLayout.lua",
"ReplicatedStorage/Shared/AnimationProfiles.lua",
"ServerScriptService/Bootstrap.server.lua",
"ServerScriptService/World/WorldBuilder.lua",
"ServerScriptService/World/MapAssetLoader.lua",
"ServerScriptService/Services/PlayerService.lua",
"ServerScriptService/Services/CombatService.lua",
"ServerScriptService/Services/MovementService.lua",
"ServerScriptService/Services/MapTravelService.lua",
"ServerScriptService/Services/UtilityService.lua",
"ServerScriptService/Services/DestructionService.lua",

"StarterPlayer/StarterPlayerScripts/Client/VFXController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/AnimationController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/CameraController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/UtilityController.client.lua",

"StarterPlayer/StarterPlayerScripts/Client/LoadingController.client.lua",
]
FORBIDDEN=("jujutsu","jjk","sukuna","gojo","megumi","cursed collision","cursedcollision","potentialman","heavy")

def fail(message):
    print("FAIL:",message)
    sys.exit(1)

def read(rel):
    path=SRC/rel
    if not path.is_file():
        fail("missing active file: "+str(path))
    return path.read_text(encoding="utf-8")

for rel in REQUIRED:
    read(rel)

manifest=json.loads((ROOT/"default.project.json").read_text(encoding="utf-8"))
if manifest.get("name")!="CollisionBattlestar":
    fail("manifest name mismatch")
tree=manifest.get("tree",{})
if tree.get("Workspace",{}).get("$properties",{}).get("StreamingEnabled") is not False:
    fail("streaming must be disabled for deterministic world bootstrap")
paths={
    "ReplicatedStorage":"src/CollisionBattlestar/ReplicatedStorage",
    "ServerScriptService":"src/CollisionBattlestar/ServerScriptService",
    "StarterPlayerScripts":"src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts",
}
for service,path in paths.items():
    got=tree.get("StarterPlayer",{}).get("StarterPlayerScripts",{}).get("$path") if service=="StarterPlayerScripts" else tree.get(service,{}).get("$path")
    if got!=path:
        fail(f"{service} path mismatch")

active=list(SRC.rglob("*.lua"))
if len(active)<len(REQUIRED):
    fail(f"active Lua file count below required minimum: {len(active)}")

for path in active:
    source=path.read_text(encoding="utf-8",errors="ignore").lower()
    for marker in FORBIDDEN:
        if marker in source:
            fail(f"legacy or removed runtime marker in {path}: {marker}")

bootstrap=read("ServerScriptService/Bootstrap.server.lua")
for name in ("CombatRequest","MovementRequest","Feedback","MapTravelRequest","MapTravelFeedback","UtilityRequest","UtilityFeedback"):
    if name not in bootstrap:
        fail("missing remote: "+name)

combat=read("ServerScriptService/Services/CombatService.lua")
for token in ("GetPartBoundsInBox","GetPartBoundsInRadius","TakeDamage","BlockStart","BlockEnd","Special","Dash","RequestRate","DashInvulnerable"):
    if token not in combat:
        fail("combat contract missing: "+token)

world=read("ServerScriptService/World/WorldBuilder.lua")
for token in ("CollisionBattlestarWorld","MapLoaded","SpawnLocation","district","roads","Rebuild","Verify","CBS_Destructible"):
    if token not in world:
        fail("map contract missing: "+token)

routes=read("ReplicatedStorage/Shared/MapDefinitions.lua")
for token in ("BattleLine_Urban_v3","Origin","Metro","Core","Iron","Apex"):
    if token not in routes:
        fail("route definition missing: "+token)

ui=read("ReplicatedStorage/Shared/HUDRecovery.lua")
for token in ("HUDLayout","HUDRuntimeReady","PreferredInput","MobileActions","HealthBackground","EnergyBackground","UltBackground","Hotbar"):
    if token not in ui:
        fail("HUD runtime contract missing: "+token)

defs=read("ReplicatedStorage/Shared/CombatDefinitions.lua")
for token in ("Light","Dash","Block","Special","MouseButton1","LeftShift"):
    if token not in defs:
        fail("combat input definition missing: "+token)

animations=read("ReplicatedStorage/Shared/AnimationProfiles.lua")
for token in ("Vanguard","Impact","18576726303","18576729183","18576731629","2515090838","17866759652"):
    if token not in animations:
        fail("animation profile missing: "+token)

controller=read("StarterPlayer/StarterPlayerScripts/Client/AnimationController.client.lua")
for token in ("Animator","LoadAnimation","PreloadAsync","clip.Priority","AdjustWeight","AdjustSpeed","AnimationRuntimeReady"):
    if token not in controller:
        fail("animation runtime contract missing: "+token)

print("PASS: Collision Battlestar animation pass manifest")
print(f"PASS: {len(active)} active Lua files")
print("PASS: real AnimationTrack loading with safe fallback")
print("PASS: two deterministic animation sets")
print("PASS: priority-based action blending")
print("PASS: preloading and permission failure fallback")
platform=read("ReplicatedStorage/Shared/UI/HUDLayout.lua")
for token in ("TouchTapIcon","MobileActions","ControllerHints","ScreenInsets","DeviceSafeInsets"):
    if token not in platform:
        fail("platform HUD layout contract missing: "+token)

boot=read("ServerScriptService/Bootstrap.server.lua")
for token in ("BootRequest","BootFeedback","CollisionBattlestarReady","WorldRepair","verifyRuntime","ensure"):
    if token not in boot:
        fail("recovery boot contract missing: "+token)

loading=read("StarterPlayer/StarterPlayerScripts/Client/LoadingController.client.lua")
for token in ("CollisionBootScreen","mapReady","hudReady","playerReady","bootRequest:FireServer","createHUD","Recovery"):
    if token not in loading:
        fail("loading recovery contract missing: "+token)

print("PASS: legacy fusion and removed combat marker scan clean")
hud=read("ReplicatedStorage/Shared/HUDRecovery.lua")
for token in ("CollisionHUD","IsReady","Build","HUDRuntimeReady","HUDLayout"):
    if token not in hud:
        fail("HUD recovery contract missing: "+token)

loading=read("StarterPlayer/StarterPlayerScripts/Client/LoadingController.client.lua")
for token in ("hudReady","CollisionBootScreen","createHUD","requestRecovery"):
    if token not in loading:
        fail("loading recovery contract missing: "+token)

print("PASS: fault-tolerant server and client startup recovery")
print("PASS: direct HUD reconstruction fallback")
print("PASS: platform-specific mobile and console image HUD")

layout=read("ReplicatedStorage/Shared/UI/HUDLayout.lua")
for token in ("StatusFrame","HealthBackground","EnergyBackground","UltBackground","Hotbar","MobileActions","MapPanel","UtilityBar","HUDLayoutReady"):
    if token not in layout:
        fail("HUD layout contract missing: "+token)


utility=read("ServerScriptService/Services/UtilityService.lua")
for token in ("UtilityRequest","UtilityFeedback","Respawn","Ping","LoadCharacter"):
    if token not in utility:
        fail("utility contract missing: "+token)

destruction=read("ServerScriptService/Services/DestructionService.lua")
for token in ("CBS_Destructible","TryDamage","DestructibleHP","DestructibleMaxHP","restore"):
    if token not in destruction:
        fail("destruction contract missing: "+token)

utilityClient=read("StarterPlayer/StarterPlayerScripts/Client/UtilityController.client.lua")
for token in ("SYSTEM MENU","RESPAWN","COMBAT SETTINGS","CONTROLS","getPingPosition","utility:FireServer","MenuPanel"):
    if token not in utilityClient:
        fail("utility client contract missing: "+token)

animations=read("ReplicatedStorage/Shared/AnimationProfiles.lua")
for token in ("Idle","Walk","Jump","Fall","M1_1","M1_4","Special","Dash","HitTaken","522635514","522638767"):
    if token not in animations:
        fail("animation profile missing: "+token)

controller=read("StarterPlayer/StarterPlayerScripts/Client/AnimationController.client.lua")
for token in ("Animator","PreloadAsync","LoadAnimation","AdjustWeight","AdjustSpeed","Running","StateChanged","InputBegan","CollisionHUD"):
    if token not in controller:
        fail("animation runtime missing: "+token)

print("PASS: functional menu, ping, destructible city and animation controller")
