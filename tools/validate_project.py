from pathlib import Path
import json
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"src"/"CollisionBattlestar"

REQUIRED=[
"ReplicatedStorage/Shared/Config.lua",
"ReplicatedStorage/Shared/Util.lua",
"ReplicatedStorage/Shared/CombatDefinitions.lua",
"ReplicatedStorage/Shared/EventDefinitions.lua",
"ReplicatedStorage/Shared/AnimationDefinitions.lua",
"ReplicatedStorage/Shared/VFXDefinitions.lua",
"ReplicatedStorage/Shared/GamePassDefinitions.lua",
"ReplicatedStorage/Shared/BuildInfo.lua",
"ServerScriptService/Services/GamePassService.lua",
"StarterPlayer/StarterPlayerScripts/Client/GamePassController.client.lua",
"ServerScriptService/Security/AntiCheatService.lua",
"ServerScriptService/Services/PlayerDataService.lua",
"ServerScriptService/Services/WorldStateService.lua",
"ServerScriptService/Services/EnemyService.lua",
"ServerScriptService/Services/QuestService.lua",
"ServerScriptService/Services/CombatService.lua",
"ServerScriptService/Services/EventService.lua",
"ServerScriptService/Services/EconomyService.lua",
"ServerScriptService/Services/MovementService.lua",
"ServerScriptService/Services/NPCService.lua",
"ServerScriptService/Services/AchievementService.lua",
"ServerScriptService/Services/BattleStreakService.lua",
"ServerScriptService/Services/WorldPresentationService.lua",
"ServerScriptService/Services/DestructionService.lua",
"ServerScriptService/Services/HitboxService.lua",
"ServerScriptService/Services/AnimationService.lua",
"ServerScriptService/Services/MapAssetLoader.lua",
"ServerScriptService/Services/MapDecorationService.lua",
"ServerScriptService/World/WorldBuilder.server.lua",
"ServerScriptService/Bootstrap.server.lua",
"StarterPlayer/StarterPlayerScripts/Client/CombatController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/MovementController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/UIController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/VFXController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/AnimationClient.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/CameraController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/ProgressMenuController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/AudioController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/Bootstrap.client.lua",
]

def fail(message):
    print("FAIL:",message)
    sys.exit(1)

def read(rel):
    path=SRC/rel
    if not path.exists():
        fail("missing active file: "+str(path))
    return path.read_text(encoding="utf-8",errors="ignore")

for rel in REQUIRED:
    read(rel)

manifest=json.loads((ROOT/"default.project.json").read_text(encoding="utf-8"))
if manifest.get("name")!="CollisionBattlestar":
    fail("default.project.json is not CollisionBattlestar")
tree=manifest.get("tree",{})
if tree.get("ReplicatedStorage",{}).get("$path")!="src/CollisionBattlestar/ReplicatedStorage":
    fail("manifest ReplicatedStorage does not point at active CollisionBattlestar tree")
if tree.get("ServerScriptService",{}).get("$path")!="src/CollisionBattlestar/ServerScriptService":
    fail("manifest ServerScriptService does not point at active CollisionBattlestar tree")

active_files=list(SRC.rglob("*.lua"))
if not active_files:
    fail("active runtime contains no Lua files")

for p in active_files:
    text=p.read_text(encoding="utf-8",errors="ignore")
    for marker in ("Jujutsu","JJK","Sukuna","Gojo","Megumi","Cursed Collision","CursedCollision","PotentialMan"):
        if marker.lower() in text.lower():
            fail(f"legacy marker in active source: {p} -> {marker}")

util=read("ReplicatedStorage/Shared/Util.lua")
utility_methods=set(re.findall(r"function\s+U\.([A-Za-z_][A-Za-z0-9_]*)",util))
for p in active_files:
    text=p.read_text(encoding="utf-8",errors="ignore")
    if "Shared.Util" not in text:
        continue
    for method in sorted(set(re.findall(r"\bU\.([A-Za-z_][A-Za-z0-9_]*)",text))):
        if method not in utility_methods:
            fail(f"missing Util API U.{method}: {p}")

bootstrap=read("ServerScriptService/Bootstrap.server.lua")
remote_names=set(re.findall(r'"([A-Za-z][A-Za-z0-9_]*)"',re.search(r'for _,name in \{([^}]*)\}do',bootstrap,re.S).group(1))) if re.search(r'for _,name in \{([^}]*)\}do',bootstrap,re.S) else set()
remote_names.update(re.findall(r'FindFirstChild\("([^"]+)"\)',bootstrap))
for p in active_files:
    text=p.read_text(encoding="utf-8",errors="ignore")
    for name in set(re.findall(r'CollisionRemotes\.([A-Za-z][A-Za-z0-9_]*)',text)):
        if name not in remote_names:
            fail(f"remote contract missing: CollisionRemotes.{name} referenced by {p}")
    for name in set(re.findall(r'WaitForChild\("([^"]+)"\)',text)):
        if "CollisionRemotes" in text and name in {"CombatRequest","Feedback","WorldState","GamePassRequest"} and name not in remote_names:
            fail(f"remote WaitForChild contract missing: {name} in {p}")

build_info=read("ReplicatedStorage/Shared/BuildInfo.lua")
for token in ('B.Version=','B.BuildTag=','B.Project="Collision Battlestar"'):
    if token not in build_info:
        fail("BuildInfo contract missing: "+token)

config=read("ReplicatedStorage/Shared/Config.lua")
for token in ("MomentumMax","InstabilityMax","Reality","Fracture","Blade","Martial","Size=960","EventAnchor=Vector3.new(0,6,-286)"):
    if token not in config:
        fail("configuration contract missing: "+token)

combat=read("ServerScriptService/Services/CombatService.lua")
for token in ("Hitbox.Query","TakeDamage","Parry","Overdrive","IsBlocking","StyleToggle"):
    if token not in combat:
        fail("combat contract missing: "+token)

hitbox=read("ServerScriptService/Services/HitboxService.lua")
for token in ("GetPartBoundsInBox","workspace:Raycast","MaxParts"):
    if token not in hitbox:
        fail("hitbox contract missing: "+token)

animation=read("ServerScriptService/Services/AnimationService.lua")
for token in ("Animator","LoadAnimation","GetMarkerReachedSignal"):
    if token not in animation:
        fail("animation service contract missing: "+token)

animation_client=read("StarterPlayer/StarterPlayerScripts/Client/AnimationClient.client.lua")
for token in ("Animator","LoadAnimation","RenderStepped"):
    if token not in animation_client:
        fail("animation client contract missing: "+token)

vfx=read("StarterPlayer/StarterPlayerScripts/Client/VFXController.client.lua")
for token in ("TweenService","ParticleEmitter","Beam"):
    if token not in vfx:
        fail("vfx contract missing: "+token)

world=read("ServerScriptService/Services/WorldStateService.lua")
for token in ("Stable","Unstable","Distorted","Invaded","Collapsed","Recovering","Resonating"):
    if f'"{token}"' not in world:
        fail("Collision State missing: "+token)

map_builder=read("ServerScriptService/World/WorldBuilder.server.lua")
map_files=list((SRC/"ServerScriptService/World/Map").glob("*.lua"))
if len(map_files)<3:
    fail("map must be split across at least 3 modules under ServerScriptService/World/Map")
if len(map_builder.splitlines())>220:
    fail("WorldBuilder.server.lua is too large; keep geometry in map modules")
if map_builder.find("T.Init(")==-1 or map_builder.find("local Districts=require")<map_builder.find("T.Init("):
    fail("WorldBuilder must initialize MapContext before loading map modules")
map_text="\n".join(p.read_text(encoding="utf-8",errors="ignore") for p in map_files+[SRC/"ServerScriptService/World/WorldBuilder.server.lua"])
for token in ("AsterRoofLadder","VantaRoofLadder","ObservationRoofLadder","GroundWest","GroundEast","GroundNorth","GroundSouth","MetroFloor","SkybridgeWest","SkybridgeNorth","ShatterPark","CanalWater","RiftCore","BossArena","CollisionBattlestarWorld","NeonHeights","IndustrialVerge","ShatterPark","CanalMarket","ArchiveQuarter","OldMetro","RiftCrater"):
    if token not in map_text:
        fail("map contract missing: "+token)

battle=read("ServerScriptService/Services/BattleStreakService.lua")
for token in ("BattleStreak","spawnWave","makeWave","SetBattleStreakBest","BATTLE STREAK","SpawnBoss","SpawnMiniBoss"):
    if token.lower() not in battle.lower():
        fail("Battle Streak contract missing: "+token.lower())

event=read("ServerScriptService/Services/EventService.lua")
for token in ("RealityBreak","CollisionChain","Warning","Escalation","Climax","Resolved"):
    if token.lower() not in event.lower():
        fail("event pipeline missing: "+token)

movement=read("ServerScriptService/Services/MovementService.lua")
for token in ("SprintStart","SprintEnd"):
    if token not in movement:
        fail("movement action missing: "+token)

passes=read("ReplicatedStorage/Shared/GamePassDefinitions.lua")
for token in ("Passes","ActionRequirements","MinPrice","MaxPrice"):
    if token not in passes:
        fail("game pass definitions missing: "+token)
prices=[int(x) for x in re.findall(r"TargetPrice=(\d+)",passes)]
if not prices or any(price<20 or price>60 for price in prices):
    fail("game pass target price outside 20-60")
ids=[int(x) for x in re.findall(r"Id=(\d+),TargetPrice=",passes) if int(x)>0]
if len(ids)!=len(set(ids)):
    fail("duplicate configured game pass IDs detected")
pass_service=read("ServerScriptService/Services/GamePassService.lua")
for token in ("UserOwnsGamePassAsync","PromptGamePassPurchase","PromptGamePassPurchaseFinished","RequireAction","HasAction"):
    if token not in pass_service:
        fail("game pass service contract missing: "+token)

ui=read("StarterPlayer/StarterPlayerScripts/Client/UIController.client.lua")
for token in ("Momentum","Instability","REALITY BREAK","TouchEnabled","CollisionBattlestarPlaceVersion"):
    if token not in ui:
        fail("UI contract missing: "+token)

print("PASS: Collision Battlestar active manifest")
print(f"PASS: {len(active_files)} active Lua files")
print(f"PASS: {len(map_files)} modular map modules")
print(f"PASS: {len(utility_methods)} shared Util APIs validated")
print("PASS: remote references resolve against Bootstrap")
print("PASS: legacy franchise markers absent from active tree")
print("PASS: combat, movement, persistence, world-state, event, UI and map contracts present")
print("PASS: game pass ownership, purchase prompting, capability gating and 20-60 target price contract present")
