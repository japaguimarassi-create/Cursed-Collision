from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "src/StealAnAnimal"
CONFIG = (BASE / "ReplicatedStorage/Shared/Config.lua").read_text(encoding="utf-8")
CATALOG = (BASE / "ReplicatedStorage/Shared/AnimalCatalog.lua").read_text(encoding="utf-8")
MAIN = (BASE / "ServerScriptService/Main.server.lua").read_text(encoding="utf-8")
CLIENT = (BASE / "StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")

animal_ids = set(re.findall(r'Id = "([A-Za-z0-9]+)"', CATALOG))
biomes = set(re.findall(r'Id = "([A-Za-z]+)", Name = "', CONFIG))
phase_numbers = re.findall(r'Phase = ([1-8]), CenterX = ', CONFIG)
assert len(animal_ids) >= 28, "Expected at least twenty-eight original animal species"
assert len(biomes) == 8, "Expected eight sequential animal phases"
assert phase_numbers == [str(n) for n in range(1, 9)], "Phases must be numbered sequentially from 1 to 8"
assert all(biome in CATALOG for biome in biomes), "Every biome must have animals"
assert "basePositions = {" in MAIN, "Eight farms must use an explicit rectangular layout"
assert all(token in MAIN for token in ("CorridorFloor", "CorridorEdge", "MainPath", "GuardianParent_", "PAI PROTETOR")), "Central animal corridor or guardian parents missing"
assert all(token in MAIN for token in ("createTreadmill", "TrainingZone", "MovingBeltStripe", "UpgradeTreadmill", "TreadmillLevel")), "Functional treadmill and upgrade prompt missing"
assert "treadmillStrips" in MAIN and "TreadmillBeltSpeed" in CONFIG, "Treadmill belt animation missing"
assert "Rules.TrainingGain" in MAIN and "Rules.MoveSpeed" in MAIN and "Config.MaxSpeedPoints" in MAIN, "Training and speed cap must be server-authoritative"
assert "createAnimalModel" in MAIN and "EvolutionStages" in MAIN, "Stage-aware animal model builder missing"
assert all(token in MAIN for token in ("HenComb", "SwanNeck", "BearPaw", "WhaleTailFluke", "DolphinTailFluke", "MantaWing")), "Distinctive animal silhouettes are missing"
assert all(token in MAIN for token in ("GiantMushroom", "WetlandPool", "IcePillar", "SavannaBoulder", "LavaRift", "LakeReed", "OceanBubble")), "Biome landmarks are missing"
assert 'CFrame.new(biome.CenterX, -0.5, 0)' in MAIN, "Biome ground must meet the world baseline"
assert 'Vector3.new(biome.CenterX + rng:NextNumber(-28, 28), -0.12, rng:NextNumber(-20, 20))' in MAIN, "Wild animals must spawn inside the corridor"
assert "slot.Position + Vector3.new(0, 0.05, 0)" in MAIN, "Stored animals must be placed close to the slot surface"
assert "makeGuardian" in MAIN and "GuardianCatchDistance" in MAIN, "Guardian pursuit gameplay missing"
assert "StoredAnimals" in MAIN and "DepositAnimal" in MAIN and "CollectIncome" in MAIN, "Farm loop missing"
assert "renderBarn" in MAIN and "Rules.AnimalIncome" in MAIN, "Evolution and barn income need to be linked"
assert "TreadmillStatus" in CLIENT and "MELHORAR ESTEIRA" in CLIENT and "TouchEnabled" in CLIENT, "Mobile treadmill UI missing"
assert "GAMEPASSES" not in CLIENT and "PASSES" not in CLIENT, "Gamepass UI must not exist"
print(f"PASS AnimalCorridor: {len(animal_ids)} species, {len(biomes)} phases, rectangular farms, original models, animated treadmills, and server-side speed training.")
