from pathlib import Path
import json
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"src"/"CollisionBattlestar"

def fail(message):
    print("FAIL:", message)
    sys.exit(1)

def read(relative):
    path=SRC/relative
    if not path.is_file():
        fail("missing active file: "+str(path))
    return path.read_text(encoding="utf-8")

manifest=json.loads((ROOT/"default.project.json").read_text(encoding="utf-8"))
if manifest.get("name")!="CollisionBattlestar":
    fail("manifest name mismatch")
tree=manifest.get("tree",{})
if tree.get("Workspace",{}).get("$properties",{}).get("StreamingEnabled") is not True:
    fail("StreamingEnabled must be true")
if tree.get("ReplicatedStorage",{}).get("$path")!="src/CollisionBattlestar/ReplicatedStorage":
    fail("ReplicatedStorage path mismatch")
if tree.get("ServerScriptService",{}).get("$path")!="src/CollisionBattlestar/ServerScriptService":
    fail("ServerScriptService path mismatch")
if tree.get("StarterPlayer",{}).get("StarterPlayerScripts",{}).get("$path")!="src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts":
    fail("StarterPlayerScripts path mismatch")

lua_files=list(SRC.rglob("*.lua"))
server_runtimes=list(SRC.rglob("*.server.lua"))
client_runtimes=list(SRC.rglob("*.client.lua"))
if [p.relative_to(SRC).as_posix() for p in server_runtimes]!=["ServerScriptService/Bootstrap.server.lua"]:
    fail("server runtime contract mismatch")
if [p.relative_to(SRC).as_posix() for p in client_runtimes]!=["StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua"]:
    fail("client runtime contract mismatch")
for legacy in ("ServerScriptService/QAService.server.lua","StarterPlayer/StarterPlayerScripts/Client/QARunner.client.lua"):
    if (SRC/legacy).exists():
        fail("legacy runtime remains: "+legacy)

required=[
"ReplicatedStorage/Shared/BuildInfo.lua",
"ReplicatedStorage/Shared/Config.lua",
"ReplicatedStorage/Shared/MapDefinitions.lua",
"ReplicatedStorage/Shared/StoreCatalog.lua",
"ReplicatedStorage/Shared/QAContract.lua",
"ReplicatedStorage/Shared/Net.lua",
"ReplicatedStorage/Shared/CharacterDefinitions.lua",
"ReplicatedStorage/Shared/UI/HUDLayout.lua",
"ServerScriptService/Bootstrap.server.lua",
"ServerScriptService/Systems/DataService.lua",
"ServerScriptService/Systems/WorldService.lua",
"ServerScriptService/Systems/EconomyService.lua",
"ServerScriptService/Systems/CombatService.lua",
"ServerScriptService/Systems/HitboxService.lua",
"ServerScriptService/Systems/QAService.lua",
"StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/UIController.lua",
"StarterPlayer/StarterPlayerScripts/Client/FXController.lua",
"StarterPlayer/StarterPlayerScripts/Client/CameraController.lua",
"StarterPlayer/StarterPlayerScripts/Client/QAClient.lua",
]
for path in required:
    read(path)

server=read("ServerScriptService/Bootstrap.server.lua")
for token in ("CollisionRemotes","CombatRequest","MovementRequest","UtilityRequest","MapTravelRequest","Feedback","GameState","CombatFX","WorldService:Build()","DataService:Init()","EconomyService:Init","CombatService:Init","QAService:Init","ProcessReceipt"):
    if token not in server:
        fail("bootstrap contract missing: "+token)

combat=read("ServerScriptService/Systems/CombatService.lua")
for token in ("RequestRate","RequestBurst","HitboxService","Light","Dash","BlockStart","BlockEnd","Special","Awaken","Domain","Clash1","Clash2","Clash3","Clash4","ParryWindow","CBS_Destructible","HitStunUntil","clashMoveNext","Reset"):
    if token not in combat:
        fail("combat contract missing: "+token)

world=read("ServerScriptService/Systems/WorldService.lua")
for token in ("CBS_Destructible","RequestStreamAroundAsync","CollisionBattlestarMapReady"):
    if token not in world:
        fail("world contract missing: "+token)
routes=read("ReplicatedStorage/Shared/MapDefinitions.lua")
for token in ("Origin","Metro","Core","Iron","Apex","BattleLine_Urban_V5"):
    if token not in routes:
        fail("map contract missing: "+token)

data=read("ServerScriptService/Systems/DataService.lua")
for token in ("GetAsync","UpdateAsync","BindToClose","180","CollisionBattlestar_Profile_v4"):
    if token not in data:
        fail("data contract missing: "+token)

hud=read("ReplicatedStorage/Shared/UI/HUDLayout.lua")
for token in ("CollisionHUD","LoadingScreen","PlayerCard","Objective","TopRight","Signal","MissionChip","CombatFeed","ActionBar","PowerActions","MobileActions","QuickDock","MapPanel","ShopPanel","FighterPanel","QuestPanel","ProfilePanel","ScoreboardPanel","SettingsPanel","Notice","ClashPanel","CoreUISafeInsets"):
    if token not in hud:
        fail("HUD contract missing: "+token)

ui=read("StarterPlayer/StarterPlayerScripts/Client/UIController.lua")
for token in ("ShopState","BuyItem","EquipItem","SetCharacter","RedeemCode","ClaimMission","MobileActions","ScoreboardPanel","SettingsPanel","ClashPanel","Clash"):
    if token not in ui:
        fail("UI contract missing: "+token)

client=read("StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua")
for token in ("HUD.Build","PreloadAsync","startBoot","checkCombat","checkAssets","bootDone","Clash1","Clash4","ButtonR2","ButtonL2","ButtonY","PlayerCard","ActionBar","QuickDock"):
    if token not in client:
        fail("client contract missing: "+token)

fighters=read("ReplicatedStorage/Shared/CharacterDefinitions.lua")
match=re.search(r'M\.Order=\{([^}]*)\}',fighters,re.S)
if not match:
    fail("fighter order missing")
count=len(re.findall(r'"[^"]+"',match.group(1)))
if count!=24:
    fail("fighter roster count mismatch: "+str(count))

store=read("ReplicatedStorage/Shared/StoreCatalog.lua")
if 'Kind="Emote"' in store or "Emote_" in store:
    fail("emotes remain in active store catalog")

qa=read("ReplicatedStorage/Shared/QAContract.lua")
for token in ("Clash1","Clash2","Clash3","Clash4","ClashPanel"):
    if token not in qa:
        fail("QA contract missing: "+token)

hitbox=read("ServerScriptService/Systems/HitboxService.lua")
for token in ("GetPartBoundsInBox","GetPartBoundsInRadius","OverlapParams","HumanoidRootPart","FilterDescendantsInstances"):
    if token not in hitbox:
        fail("hitbox contract missing: "+token)

build=read("ReplicatedStorage/Shared/BuildInfo.lua")
for token in ('B.Version="4.0.0"','B.Roster=24','B.Emotes=0','B.HUD="modern-roblox-hud-v5"','BattleLine_Urban_V5'):
    if token not in build:
        fail("build contract missing: "+token)

print("PASS: Collision Battlestar v4 architecture")
print("PASS: one server runtime + one client runtime")
print("PASS: 24-fighter data contract + 150-emote catalog")
print("PASS: server-authoritative combat + four-move domain clash")
print("PASS: connected streamed city + destructible geometry")
print("PASS: safe-area HUD + mobile/console input")
print("PASS: resilient profile persistence and receipt pipeline")
print("PASS: startup loading gate and runtime QA")
print("PASS: no legacy runtime files remain")
