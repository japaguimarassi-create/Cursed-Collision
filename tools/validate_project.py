from pathlib import Path
import json
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"src"/"CollisionBattlestar"

REQUIRED=[
"ReplicatedStorage/Shared/Config.lua",
"ReplicatedStorage/Shared/BuildInfo.lua",
"ReplicatedStorage/Shared/Util.lua",
"ReplicatedStorage/Shared/CombatDefinitions.lua",
"ReplicatedStorage/Shared/MapDefinitions.lua",
"ServerScriptService/Bootstrap.server.lua",
"ServerScriptService/World/WorldBuilder.server.lua",
"ServerScriptService/Services/PlayerService.lua",
"ServerScriptService/Services/CombatService.lua",
"ServerScriptService/Services/MovementService.lua",
"ServerScriptService/Services/MapTravelService.lua",
"StarterPlayer/StarterPlayerScripts/Client/MainController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/VFXController.client.lua",
]

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
    fail("streaming must be disabled for the clean core map")
if tree.get("ReplicatedStorage",{}).get("$path")!="src/CollisionBattlestar/ReplicatedStorage":
    fail("ReplicatedStorage path mismatch")
if tree.get("ServerScriptService",{}).get("$path")!="src/CollisionBattlestar/ServerScriptService":
    fail("ServerScriptService path mismatch")

active=list(SRC.rglob("*.lua"))
if len(active)!=len(REQUIRED):
    fail(f"unexpected active Lua file count: {len(active)}")

for path in active:
    text=path.read_text(encoding="utf-8",errors="ignore").lower()
    for marker in ("jujutsu","jjk","sukuna","gojo","megumi","cursed collision","cursedcollision","potentialman","heavy"):
        if marker in text:
            fail(f"legacy or removed combat marker in {path}: {marker}")

bootstrap=read("ServerScriptService/Bootstrap.server.lua")
for name in ("CombatRequest","Feedback","MapTravelRequest","MapTravelFeedback"):
    if name not in bootstrap:
        fail("missing remote: "+name)

combat=read("ServerScriptService/Services/CombatService.lua")
for token in ("GetPartBoundsInBox","TakeDamage","BlockStart","BlockEnd","Special","Dash","RequestRate"):
    if token not in combat:
        fail("combat contract missing: "+token)

world=read("ServerScriptService/World/WorldBuilder.server.lua")
for token in ("CollisionBattlestarWorld","MapLoaded","SpawnLocation","BattleLine_Clean_v1"):
    if token not in world:
        fail("map contract missing: "+token)

ui=read("StarterPlayer/StarterPlayerScripts/Client/MainController.client.lua")
for token in ("CollisionHUD","BATTLE LINE","MAP","ATTACK","DASH","BLOCK","SPECIAL"):
    if token not in ui:
        fail("HUD contract missing: "+token)

print("PASS: clean Collision Battlestar manifest")
print(f"PASS: {len(active)} active Lua files")
print("PASS: single HUD controller")
print("PASS: standalone runtime map builder")
print("PASS: streaming disabled for deterministic map load")
print("PASS: M1/Dash/Block/Special combat core")
print("PASS: legacy fusion and Heavy combat markers absent")
