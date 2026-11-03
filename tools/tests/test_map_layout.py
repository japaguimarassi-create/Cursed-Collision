from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "src/StealAnAnimal"
CONFIG = (BASE / "ReplicatedStorage/Shared/Config.lua").read_text(encoding="utf-8")
CATALOG = (BASE / "ReplicatedStorage/Shared/AnimalCatalog.lua").read_text(encoding="utf-8")
MAIN_FILE = (BASE / "ServerScriptService/Main.server.lua").read_text(encoding="utf-8")
WORLD = (BASE / "ReplicatedStorage/Shared/WorldBuilder.lua").read_text(encoding="utf-8")
ANIMAL = (BASE / "ReplicatedStorage/Shared/AnimalFactory.lua").read_text(encoding="utf-8")
GUARDIAN_CATALOG = (BASE / "ReplicatedStorage/Shared/GuardianCatalog.lua").read_text(encoding="utf-8")
ANIMATOR = (BASE / "ReplicatedStorage/Shared/AnimalAnimator.lua").read_text(encoding="utf-8")
ANIMATION_CLIENT = (BASE / "StarterPlayer/StarterPlayerScripts/AnimalAnimation.client.lua").read_text(encoding="utf-8")
TREADMILL_ANIMATOR = (BASE / "ReplicatedStorage/Shared/TreadmillAnimator.lua").read_text(encoding="utf-8")
GUARDIAN_CONTROLLER = (BASE / "ServerScriptService/Services/GuardianController.lua").read_text(encoding="utf-8")
PROFILE = (BASE / "ServerScriptService/Services/ProfileStore.lua").read_text(encoding="utf-8")
MAIN = MAIN_FILE + WORLD + ANIMAL + PROFILE + GUARDIAN_CATALOG + ANIMATOR + TREADMILL_ANIMATOR + GUARDIAN_CONTROLLER
CLIENT_FILE = (BASE / "StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")
PROMPT = (BASE / "StarterPlayer/StarterPlayerScripts/InteractionPrompt.lua").read_text(encoding="utf-8")
CLIENT = CLIENT_FILE + PROMPT
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
assert all(token in MAIN for token in ("CorridorFloor", "CorridorEdge", "MainPath", "GuardianParent_", "GUARDIÃO")), "Central animal corridor or guardian parents missing"
assert all(token in MAIN for token in ("CorridorBoundaryWall", "EggNestBase", "WildEgg", "PenFenceBackLower", "PenFenceGateLeftLower")), "Egg-inspired map landmarks or fenced farms missing"
assert all(token in WORLD for token in ("CentralHubGrid", "CentralHubTile", "SafeZoneSign", "SafeZoneLine", "RouteStartSign", "MeadowMonumentCanopy", "LakeMonumentWaterfall", "ForestMonumentStoneArchTop", "WetlandsMonumentRoof", "FrostMonumentShard", "SavannaMonumentFossilRib", "VolcanoMonumentLava", "OceanMonumentBeacon")), "Open farm hub, safe-zone route, or one of eight biome landmarks missing"
assert all(token not in WORLD for token in ("RouteStartArchTop", "CentralCarpet", "CorridorPillar")), "Old portal-heavy corridor decorations must not return"
assert "CentralHubTile" in WORLD and "tile.CastShadow = false" in WORLD, "Hub checkerboard must use lightweight non-shadow tiles"
assert "LandmarkPlaque" in WORLD and "TransitionLine" in WORLD, "Biome naming and progression boundaries missing"
assert re.findall(r'Name = "([^"]+)", Phase = [1-8], CenterX = ', CONFIG) == ["Floresta", "Lago", "Deserto", "Selva", "Neve", "Vulcão", "Oceano Abissal", "Pré-histórico"], "Biome order must match the straight Steal an Egg route"
assert all(token in WORLD for token in ("biome.MinSpeed", "SPEED MÍNIMA")), "Each biome entrance sign must display its minimum SPEED"
assert all(token in MAIN_FILE for token in ("requiredBiome", "spec.Biome", "profile.Speed < minimumSpeed", "SPEED para roubar ovos")), "Minimum speed must be checked when stealing, not by blocking map traversal"
assert "enforceBiomeSpeedGates" not in MAIN_FILE and "gateCheckAccumulator" not in MAIN_FILE, "Biome access must remain physically open"
assert all(token not in WORLD for token in ("FarmBackWall", "FarmCanopy", "FarmCanopyPost")), "Player bases must be open fenced pens without houses or shelters"
assert [int(value) for value in re.findall(r'MinSpeed = (\d+)', CONFIG)] == [10, 100, 1230, 12300, 123000, 1230000, 12300000, 123000000], "Biome minimum speeds must rise by the configured progression curve"

assert all(token in MAIN for token in ("CorridorBoundaryWall", "EggNestBase", "WildEgg", "PenFenceBackLower", "PenFenceGateLeftLower")), "Egg-stealing map landmarks, walls, or fenced farms missing"
assert all(token in MAIN for token in ("createTreadmill", "TrainingZone", "MovingBeltStripe", "UpgradeTreadmill", "TreadmillLevel")), "Functional treadmill and upgrade prompt missing"
assert "TreadmillBeltSpeed" in CONFIG and "TreadmillAnimator.Step(treadmillEntries, os.clock())" in ANIMATION_CLIENT, "Client treadmill belt and roller animation missing"
assert all(token in WORLD for token in ('Kind = "Stripe"', 'Kind = "Roller"', "BaseCFrame = roller.CFrame")), "Treadmill stripes and rollers need separate animation tracks"
assert "TreadmillAnimator.ApplyLevel(treadmill, level, gain)" in MAIN_FILE, "Treadmill upgrade level must update its live visuals"
assert "Rules.TrainingGain" in MAIN and "Rules.MoveSpeed" in MAIN and "Config.MaxSpeedPoints" in MAIN, "Training and speed cap must be server-authoritative"
assert "createAnimalModel" in MAIN and "EvolutionStages" in MAIN, "Stage-aware animal model builder missing"
assert "gui.AlwaysOnTop = false" in WORLD and "gui.MaxDistance = maxDistance or (compactLabel and 18 or 32)" in WORLD, "World labels must be occluded and distance-limited"
assert 'addLabel(pad, "ESPAÇO " .. tostring(slotIndex), "VAZIO"' not in MAIN, "Empty farm slots must not each create a large floating label"
assert "Enum.ProximityPromptStyle.Custom" in MAIN and "ProximityPromptService.PromptShown" in CLIENT and "ProximityPromptService.PromptHidden" in CLIENT, "Interaction prompts must use the compact responsive HUD rather than the oversized default card"
assert "objective.Size = UDim2.new(0.68, 0, 0, 26)" in CLIENT, "Context objective should not span most of the mobile screen"
assert all(token in MAIN for token in ("HenComb", "SwanNeck", "BearPaw", "WhaleTailFluke", "DolphinTailFluke", "MantaWing")), "Distinctive animal silhouettes are missing"
assert all(token in MAIN for token in ("DesertCactus", "WetlandPool", "IcePillar", "SavannaBoulder", "PrehistoricFossilRib", "LavaRift", "LakeReed", "OceanBubble")), "Biome landmarks are missing"
assert 'CFrame.new(biome.CenterX, -0.5, 0)' in MAIN, "Biome ground must meet the world baseline"
assert 'Vector3.new(biome.CenterX + rng:NextNumber(-28, 28), -0.12, rng:NextNumber(-20, 20))' in MAIN, "Wild animals must spawn inside the corridor"
assert "slot.Position + Vector3.new(0, 0.05, 0)" in MAIN, "Stored animals must be placed close to the slot surface"
assert "SwanFoot" in ANIMAL and 'spec.Id ~= "Swan"' in ANIMAL and 'chestColor = spec.Id == "Swan" and spec.Color' in ANIMAL, "Swan guardian must use its dedicated silhouette without generic duplicated bird parts"
assert "local function releaseBase(player)" in MAIN_FILE and "releaseBase(player)" in MAIN_FILE[MAIN_FILE.find("Players.PlayerRemoving:Connect"):MAIN_FILE.find("for _, player in ipairs(Players:GetPlayers()) do")], "PlayerRemoving must release the assigned farm"
assert all(token in GUARDIAN_CATALOG for token in ("GuardianHen", "GuardianSwan", "GuardianScorpion", "GuardianTiger", "GuardianYeti", "GuardianHellhound", "GuardianWhale", "GuardianTyrannosaur")), "Eight biome guardians need explicit identities"
assert all(token in GUARDIAN_CONTROLLER for token in ("GuardianCatalog.Get(biome.Id)", 'model:SetAttribute("AnimationState", "Rest")', 'model:SetAttribute("AnimationState", "Run")', 'model:SetAttribute("AnimationState", "Walk")', "Config.GuardianCatchDistance", "ClearCarry(targetPlayer)", "self:SpawnAll()", "self:Step(deltaTime, carried)")), "Guardian controller must spawn, rest, pursue, run, return home and trigger the escape"
assert all(token in ANIMAL for token in ("GuardianHenTailFeather", "GuardianSwanWingFeather", "GuardianScorpionTailSegment", "GuardianTigerFlankStripe", "GuardianYetiFurTuft", "GuardianHellhoundHead", "GuardianWhaleBioluminescentSpot", "GuardianTyrannosaurDorsalPlate")), "Guardian-specific 3D anatomy branches are missing"
assert all(token in ANIMATOR for token in ("Walk = true", "Rest = true", "Run = true", "self:Register(model", "self:SetState(model", "StepInterval = 0.05")), "Animal procedural animation states are missing"
assert all(token in TREADMILL_ANIMATOR for token in ("Kind == \"Roller\"", "TreadmillLevel", "TrainingGain", "MovingBeltStripe")), "Treadmill belt, roller and upgrade visuals must animate"
assert "guardianController:SpawnAll()" in MAIN_FILE and "guardianController:Step(deltaTime, carried)" in MAIN_FILE and "animalAnimator:Step(deltaTime)" in ANIMATION_CLIENT, "Server guardian AI and client animal animation must both be wired"
assert all(token in ANIMATION_CLIENT for token in ("Workspace.DescendantAdded", "GetAttributeChangedSignal(\"AnimationState\")", "SetViewPosition", "MaxDistance")), "Client animation discovery and distance culling are missing"
assert all(token in WORLD for token in ('SetAttribute("TreadmillOrigin"', 'SetAttribute("AnimationPhase"', 'SetAttribute("AnimationSpeed"')), "Treadmill geometry must publish local animation metadata"
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
assert all(token in static_json for token in ("CentralHubGrid", "CentralHubTile", "SafeZoneLine", "SafeZoneSign", "RouteStartSign", "MeadowEntryStrip", "LakeEntryStrip", "MeadowMonumentPetal", "LakeMonumentWaterfall", "ForestMonumentCanopy", "WetlandsMonumentRoof", "FrostMonumentShard", "SavannaMonumentCanopy", "VolcanoMonumentLava", "OceanMonumentBeacon", "LandmarkPlaque")), "Static Workspace preview does not contain the open safe hub, route and biome landmarks"
assert "FarmBackWall" not in static_json and "FarmCanopy" not in static_json and "BarnSign" not in static_json, "Static farms must be open pens, not houses"
assert all(token in static_json for token in ("MeadowSpeedRequirementSign", "LakeSpeedRequirementSign", "ForestSpeedRequirementSign", "WetlandsSpeedRequirementSign", "FrostSpeedRequirementSign", "VolcanoSpeedRequirementSign", "OceanSpeedRequirementSign", "SavannaSpeedRequirementSign")), "Static preview must show open biome speed signs without solid barriers"
assert static_json.count('"Name": "CentralHubTile"') == 121, "Static hub preview must preserve the complete 11-by-11 checkerboard"
assert static_json.count("LandmarkPlaque") == 8, "Static hub preview must include one landmark plaque per biome"
assert all(token in static_json for token in ("CorridorBoundaryWall", "EggNestBase", "WildEgg", "PenFenceBackLower", "PenFencePost")), "Static preview missing egg nests, boundary walls, or fenced farm pens"
assert 'local previewWorld = Workspace:FindFirstChild("StealAnAnimalWorld")' in MAIN, "Runtime must preserve preview while booting"
assert "previewWorld:Destroy()" in MAIN, "Runtime must remove preview only after successfully creating its world"
print(f"PASS AnimalCorridor: {len(animal_ids)} species, {len(biomes)} phases, {static_parts} embedded Parts, eight farms/treadmills, and final whale guardian.")
