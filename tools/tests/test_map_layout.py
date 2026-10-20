from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "src/StealAnAnimal"
CONFIG = (BASE / "ReplicatedStorage/Shared/Config.lua").read_text(encoding="utf-8")
CATALOG = (BASE / "ReplicatedStorage/Shared/AnimalCatalog.lua").read_text(encoding="utf-8")
MAIN = (BASE / "ServerScriptService/Main.server.lua").read_text(encoding="utf-8")
CLIENT = (BASE / "StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")
import json
PROJECT = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
PREVIEW_PATH = BASE / "Workspace/StealAnAnimalWorld.model.json"
PREVIEW = json.loads(PREVIEW_PATH.read_text(encoding="utf-8"))

animal_ids = set(re.findall(r'Id = "([A-Za-z0-9]+)"', CATALOG))
biomes = set(re.findall(r'Id = "([A-Za-z]+)", Name = "', CONFIG))
phase_numbers = re.findall(r'Phase = ([1-8]), CenterX = ', CONFIG)
assert len(animal_ids) >= 28, "Expected at least twenty-eight original animal species"
assert len(biomes) == 8, "Expected eight sequential animal phases"
assert phase_numbers == [str(n) for n in range(1, 9)], "Phases must be numbered sequentially from 1 to 8"
assert all(biome in CATALOG for biome in biomes), "Every biome must have animals"
assert "basePositions = {" in MAIN, "Eight farms must use an explicit rectangular layout"
assert all(token in MAIN for token in ("CorridorFloor", "CorridorEdge", "MainPath", "GuardianParent_", "PAI PROTETOR")), "Central animal corridor or guardian parents missing"
assert all(token in MAIN for token in ("CorridorBoundaryWall", "EggNestBase", "WildEgg", "PenFenceBackLower", "PenFenceGateLeftLower")), "Egg-inspired map landmarks or fenced farms missing"
assert all(token in MAIN for token in ("CorridorBoundaryWall", "EggNestBase", "WildEgg", "PenFenceBackLower", "PenFenceGateLeftLower")), "Egg-stealing map landmarks, walls, or fenced farms missing"
assert all(token in MAIN for token in ("createTreadmill", "TrainingZone", "MovingBeltStripe", "UpgradeTreadmill", "TreadmillLevel")), "Functional treadmill and upgrade prompt missing"
assert "treadmillStrips" in MAIN and "TreadmillBeltSpeed" in CONFIG, "Treadmill belt animation missing"
assert "Rules.TrainingGain" in MAIN and "Rules.MoveSpeed" in MAIN and "Config.MaxSpeedPoints" in MAIN, "Training and speed cap must be server-authoritative"
assert "createAnimalModel" in MAIN and "EvolutionStages" in MAIN, "Stage-aware animal model builder missing"
assert "gui.AlwaysOnTop = false" in MAIN and "gui.MaxDistance = maxDistance or (compactLabel and 18 or 32)" in MAIN, "World labels must be occluded and distance-limited"
assert 'addLabel(pad, "ESPAÇO " .. tostring(slotIndex), "VAZIO"' not in MAIN, "Empty farm slots must not each create a large floating label"
assert "Enum.ProximityPromptStyle.Custom" in MAIN and "ProximityPromptService.PromptShown" in CLIENT and "ProximityPromptService.PromptHidden" in CLIENT, "Interaction prompts must use the compact responsive HUD rather than the oversized default card"
assert "objective.Size = UDim2.new(0.68, 0, 0, 26)" in CLIENT, "Context objective should not span most of the mobile screen"
assert all(token in MAIN for token in ("HenComb", "SwanNeck", "BearPaw", "WhaleTailFluke", "DolphinTailFluke", "MantaWing")), "Distinctive animal silhouettes are missing"
assert all(token in MAIN for token in ("GiantMushroom", "WetlandPool", "IcePillar", "SavannaBoulder", "LavaRift", "LakeReed", "OceanBubble")), "Biome landmarks are missing"
assert 'CFrame.new(biome.CenterX, -0.5, 0)' in MAIN, "Biome ground must meet the world baseline"
assert 'Vector3.new(biome.CenterX + rng:NextNumber(-28, 28), -0.12, rng:NextNumber(-20, 20))' in MAIN, "Wild animals must spawn inside the corridor"
assert "slot.Position + Vector3.new(0, 0.05, 0)" in MAIN, "Stored animals must be placed close to the slot surface"
assert "makeGuardian" in MAIN and "GuardianCatchDistance" in MAIN, "Guardian pursuit gameplay missing"
assert "StoredAnimals" in MAIN and "DepositAnimal" in MAIN and "CollectIncome" in MAIN, "Farm loop missing"
assert "renderBarn" in MAIN and "Rules.AnimalIncome" in MAIN, "Evolution and barn income need to be linked"
assert all(token in CLIENT for token in ("TreadmillLevel", "TreadmillGain", "OpenShop", "OpenIndex", "TouchEnabled", "TopDashboard", "QuickActions", "ContextObjective", "ScreenInsets", "Modal", "OpenMore", "MenuList", "Daily", "Quests", "Codes", "Stats", "Settings", "Diagnostics", "AnimalIndex", "ÍNDICE ANIMAL", "LOJA DE MELHORIAS", "mapBotReportRemote.OnClientEvent")), "Responsive HUD or progression panels missing"
assert all(token in CLIENT for token in ("makeGlyph", "Book", "Bag", "objectiveMarker", "RebirthBadge")), "Egg-style HUD icons and objective status are missing"
assert all(token in CLIENT for token in ('makeButton(gui, "BotXStatus"', 'botXChip.Activated:Connect(function()', 'botXStatusRemote.OnClientEvent:Connect(function(status)', 'formatDiagnosticReport()', 'botXStatusRemote:FireServer("request")')), "Visible BotX status and live diagnostic request/reply are missing"
assert all(token not in CLIENT for token in ("ActionDock", "helpButton.Activated", "barnButton.Activated", "collectButton.Activated", "rebirthButton.Activated")), "Removed HUD controls must not leave stale callbacks"
assert all(token in MAIN for token in ("RequestDailyReward", "RequestRedeemCode", "RequestQuest", "RequestMapBot", "PathfindingService:CreatePath")), "Daily rewards, quests, code redemption, or MapBot server remotes are missing"
assert "RebirthCoinsRequired = 100000" in CONFIG and "MaxRebirths = 25" in CONFIG and "Rules.RebirthSpeedRequirement(Config)" in MAIN, "Original rebirth requirements are missing"
assert "GAMEPASSES" not in CLIENT and "PASSES" not in CLIENT, "Gamepass UI must not exist"
assert "ActionDock" not in CLIENT, "The previous permanent bottom action dock must be removed"
assert PROJECT["tree"]["Workspace"]["$className"] == "Workspace", "Workspace must be serialized into the place"
assert PROJECT["tree"]["Workspace"]["$path"] == "src/StealAnAnimal/Workspace", "Workspace must include static map geometry"
static_json = PREVIEW_PATH.read_text(encoding="utf-8")
static_parts = len(re.findall(r'"ClassName": "Part"', static_json))
assert static_parts >= 300, f"Expected at least 300 embedded map Parts, found {static_parts}"
assert all(token in static_json for token in ("CorridorFloor", "Farm_8", "TreadmillBelt", "GuardianParent_Ocean", "PreviewBaby_Whale")), "Static map missing core landmarks"
assert all(token in static_json for token in ("CorridorBoundaryWall", "EggNestBase", "WildEgg", "PenFenceBackLower", "PenFencePost")), "Static preview missing egg nests, boundary walls, or fenced farms"
assert all(token in static_json for token in ("CorridorBoundaryWall", "EggNestBase", "WildEgg", "PenFenceBackLower", "PenFencePost")), "Static preview missing egg nests, boundary walls, or fenced farm pens"
assert 'local previewWorld = Workspace:FindFirstChild("StealAnAnimalWorld")' in MAIN, "Runtime must preserve preview while booting"
assert "previewWorld:Destroy()" in MAIN, "Runtime must remove preview only after successfully creating its world"
print(f"PASS AnimalCorridor: {len(animal_ids)} species, {len(biomes)} phases, {static_parts} embedded Parts, eight farms/treadmills, and final whale guardian.")
