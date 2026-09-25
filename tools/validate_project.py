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
"ServerScriptService/World/WorldBuilder.server.lua",
"ServerScriptService/Bootstrap.server.lua",
"StarterPlayer/StarterPlayerScripts/Client/CombatController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/MovementController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/UIController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/VFXController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/CameraController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/ProgressMenuController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/AudioController.client.lua",
"StarterPlayer/StarterPlayerScripts/Client/Bootstrap.client.lua",
]

def fail(message):
    print("FAIL:",message)
    sys.exit(1)

for rel in REQUIRED:
    p=SRC/rel
    if not p.exists():
        fail("missing active file: "+str(p))

manifest=json.loads((ROOT/"default.project.json").read_text())
if manifest.get("name")!="CollisionBattlestar":
    fail("default.project.json is not CollisionBattlestar")
tree=manifest.get("tree",{})
if tree.get("ReplicatedStorage",{}).get("$path")!="src/CollisionBattlestar/ReplicatedStorage":
    fail("manifest ReplicatedStorage does not point at active CollisionBattlestar tree")
if tree.get("ServerScriptService",{}).get("$path")!="src/CollisionBattlestar/ServerScriptService":
    fail("manifest ServerScriptService does not point at active CollisionBattlestar tree")

for p in SRC.rglob("*"):
    if p.is_file():
        text=p.read_text(encoding="utf-8", errors="ignore")
        for marker in ("Jujutsu","Sukuna","Gojo","Megumi","Cursed Collision","CursedCollision","PotentialMan"):
            if marker.lower() in text.lower():
                fail(f"legacy marker in active source: {p} -> {marker}")

config=(SRC/"ReplicatedStorage/Shared/Config.lua").read_text()
for token in ("MomentumMax","InstabilityMax","Reality","Fracture","Blade","Martial","Size=960","EventAnchor=Vector3.new(0,6,-286)"):
    if token not in config:
        fail("configuration contract missing: "+token)

combat=(SRC/"ServerScriptService/Services/CombatService.lua").read_text()
for token in ("GetPartBoundsInBox","TakeDamage","Parry","Overdrive","IsBlocking","StyleToggle"):
    if token not in combat:
        fail("combat contract missing: "+token)

world=(SRC/"ServerScriptService/Services/WorldStateService.lua").read_text()
for token in ("Stable","Unstable","Distorted","Invaded","Collapsed","Recovering","Resonating"):
    if f'"{token}"' not in world:
        fail("Collision State missing: "+token)

world_builder=(SRC/"ServerScriptService/World/WorldBuilder.server.lua").read_text()
for token in ("AsterRoofLadder","VantaRoofLadder","ObservationRoofLadder","BattleStreakArena"):
    if token not in world_builder:
        fail("map verticality contract missing: "+token)

for token in ("CollisionBattlestarWorld","NeonHeights","IndustrialVerge","ShatterPark","CanalMarket","ArchiveQuarter","OldMetro","RiftCrater"):
    if token not in world_builder:
        fail("district contract missing: "+token)

for token in ("GroundWest","GroundEast","GroundNorth","GroundSouth","MetroFloor","SkybridgeWest","SkybridgeNorth","ShatterPark","CanalWater","RiftCore","BossArena"):
    if token not in world_builder:
        fail("map contract missing: "+token)
battle=(SRC/"ServerScriptService/Services/BattleStreakService.lua").read_text()
for token in ("BattleStreak","spawnWave","makeWave","SetBattleStreakBest","BATTLE STREAK"):
    if token.lower() not in battle.lower():
        fail("Battle Streak contract missing: "+token)
event=(SRC/"ServerScriptService/Services/EventService.lua").read_text()
for token in ("RealityBreak","CollisionChain","Warning","Escalation","Climax","Resolved"):
    if token.lower() not in event.lower():
        fail("event pipeline missing: "+token)

movement=(SRC/"ServerScriptService/Services/MovementService.lua").read_text()
if "SprintStart" not in movement or "SprintEnd" not in movement:
    fail("movement sprint actions missing")

ui=(SRC/"StarterPlayer/StarterPlayerScripts/Client/UIController.client.lua").read_text()
for token in ("Momentum","Instability","REALITY BREAK","TouchEnabled"):
    if token not in ui:
        fail("UI contract missing: "+token)

print("PASS: Collision Battlestar active manifest")
print(f"PASS: {len(REQUIRED)} active runtime files")
print("PASS: legacy franchise/runtime markers absent from active tree")
print("PASS: combat, movement, persistence, world-state, event, UI contracts present")
