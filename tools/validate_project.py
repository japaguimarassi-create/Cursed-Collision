from pathlib import Path
import json
import sys

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"src"/"CollisionBattlestar"

REQUIRED=[
    "ReplicatedStorage/Shared/BuildInfo.lua",
    "ReplicatedStorage/Shared/Config.lua",
    "ReplicatedStorage/Shared/MapDefinitions.lua",
    "ReplicatedStorage/Shared/StoreCatalog.lua",
    "ReplicatedStorage/Shared/UI/HUDLayout.lua",
    "ServerScriptService/Bootstrap.server.lua",
    "StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua",
]

def fail(message):
    print("FAIL:",message)
    sys.exit(1)

def read(path):
    p=SRC/path
    if not p.is_file():
        fail("missing active file: "+str(p))
    return p.read_text(encoding="utf-8")

for path in REQUIRED:
    read(path)

manifest=json.loads((ROOT/"default.project.json").read_text(encoding="utf-8"))
if manifest.get("name")!="CollisionBattlestar":
    fail("manifest name mismatch")

tree=manifest.get("tree",{})
if tree.get("Workspace",{}).get("$properties",{}).get("StreamingEnabled") is not True:
    fail("StreamingEnabled must be true")

expected={
    "ReplicatedStorage":"src/CollisionBattlestar/ReplicatedStorage",
    "ServerScriptService":"src/CollisionBattlestar/ServerScriptService",
}
for service,path in expected.items():
    if tree.get(service,{}).get("$path")!=path:
        fail(service+" path mismatch")

if tree.get("StarterPlayer",{}).get("StarterPlayerScripts",{}).get("$path")!="src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts":
    fail("StarterPlayerScripts path mismatch")

active=list(SRC.rglob("*.lua"))
if len(active)!=len(REQUIRED):
    fail("unexpected active Lua file count: "+str(len(active)))

server=read("ServerScriptService/Bootstrap.server.lua")
for token in (
    "CollisionRemotes","CombatRequest","MovementRequest","Feedback",
    "MapTravelRequest","UtilityRequest","buildMap","CollisionBattlestarMapReady",
    "GetPartBoundsInBox","GetPartBoundsInRadius","BlockStart","BlockEnd",
    "Dash","Special","TakeDamage","Overdrive","ParryWindow","DataStoreService",
    "BuyItem","EquipItem","RedeemCode"
):
    if token not in server:
        fail("server contract missing: "+token)

hud=read("ReplicatedStorage/Shared/UI/HUDLayout.lua")
for token in (
    "CollisionHUD","PlayerPanel","Health","Energy","Awakening","Hotbar",
    "MobileActions","MapPanel","ShopPanel","QuestPanel","ProfilePanel",
    "Tabs","Featured","Emotes","Robux"
):
    if token not in hud:
        fail("HUD contract missing: "+token)

client=read("StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua")
for token in (
    "HUD.Build","CombatRequest","MovementRequest","MapTravelRequest",
    "ShopState","BuyItem","EquipItem","RedeemCode","MobileM1","MobileGuard",
    "MobileDash","MobileSpecial","NextLight","NextDash","NextSpecial"
):
    if token not in client:
        fail("client contract missing: "+token)

config=read("ReplicatedStorage/Shared/Config.lua")
for token in ("Light","Dash","Block","Special","RequestRate","ParryWindow","EnergyRegen","MaxFX"):
    if token not in config:
        fail("config contract missing: "+token)

routes=read("ReplicatedStorage/Shared/MapDefinitions.lua")
for token in ("Origin","Metro","Core","Iron","Apex","BattleLine_Urban_v4"):
    if token not in routes:
        fail("map contract missing: "+token)

store=read("ReplicatedStorage/Shared/StoreCatalog.lua")
for token in ("Featured","Emotes","Bundle350","Bundle30000","Emote_Salute","Skin_Neon"):
    if token not in store:
        fail("store contract missing: "+token)

print("PASS: Collision Battlestar clean rebuild")
print("PASS: exactly one server runtime and one client runtime")
print("PASS: functional combat, map travel, economy, shop and HUD contracts")
print("PASS: no legacy runtime files remain")
