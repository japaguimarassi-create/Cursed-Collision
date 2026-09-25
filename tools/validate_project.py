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
for token in ("Hitbox.Query","TakeDamage","Parry","Overdrive","IsBlocking","StyleToggle"):
    if token not in combat:
        fail("combat contract missing: "+token)

hitbox=(SRC/"ServerScriptService/Services/HitboxService.lua").read_text()
for token in ("GetPartBoundsInBox","workspace:Raycast","MaxParts"):
    if token not in hitbox:
        fail("hitbox contract missing: "+token)

animation=(SRC/"ServerScriptService/Services/AnimationService.lua").read_text()
for token in ("Animator","LoadAnimation","GetMarkerReachedSignal"):
    if token not in animation:
        fail("animation service contract missing: "+token)

animation_client=(SRC/"StarterPlayer/StarterPlayerScripts/Client/AnimationClient.client.lua").read_text()
for token in ("Animator","LoadAnimation","RenderStepped"):
    if token not in animation_client:
        fail("animation client contract missing: "+token)

vfx=(SRC/"StarterPlayer/StarterPlayerScripts/Client/VFXController.client.lua").read_text()
for token in ("TweenService","ParticleEmitter","Beam"):
    if token not in vfx:
        fail("vfx contract missing: "+token)

world=(SRC/"ServerScriptService/Services/WorldStateService.lua").read_text()
for token in ("Stable","Unstable","Distorted","Invaded","Collapsed","Recovering","Resonating"):
    if f'"{token}"' not in world:
        fail("Collision State missing: "+token)

world_builder=(SRC/"ServerScriptService/World/WorldBuilder.server.lua").read_text()
for token in ("AsterRoofLadder","VantaRoofLadder","ObservationRoofLadder"):
    if token not in world_builder:
        fail("map verticality contract missing: "+token)
battle=(SRC/"ServerScriptService/Services/BattleStreakService.lua").read_text()
if "BattleStreakArena" not in battle:
    fail("Battle Streak arena integration missing")
world_text=world_builder
if world_text.count("Start Streak")!=0:
    fail("Battle Streak prompt must be owned by BattleStreakService only")

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

passes=(SRC/"ReplicatedStorage/Shared/GamePassDefinitions.lua").read_text()
for token in ("Passes","ActionRequirements","MinPrice","MaxPrice"):
    if token not in passes:
        fail("game pass definitions missing: "+token)
for match in re.finditer(r"TargetPrice=(\d+)",passes):
    price=int(match.group(1))
    if price<20 or price>60:
        fail("game pass target price outside 20-60: "+str(price))
pass_service=(SRC/"ServerScriptService/Services/GamePassService.lua").read_text()
for token in ("UserOwnsGamePassAsync","PromptGamePassPurchase","PromptGamePassPurchaseFinished","RequireAction","HasAction"):
    if token not in pass_service:
        fail("game pass service contract missing: "+token)
ui=(SRC/"StarterPlayer/StarterPlayerScripts/Client/UIController.client.lua").read_text()
for token in ("Momentum","Instability","REALITY BREAK","TouchEnabled"):
    if token not in ui:
        fail("UI contract missing: "+token)

print("PASS: Collision Battlestar active manifest")
print(f"PASS: {len(REQUIRED)} active runtime files")
print("PASS: legacy franchise/runtime markers absent from active tree")
print("PASS: combat, movement, persistence, world-state, event, UI contracts present")
print("PASS: game pass ownership, purchase prompting, capability gating and 20-60 target price contract present")
