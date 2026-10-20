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
assert len(animal_ids) >= 20, "Expected at least twenty original animal species"
assert len(biomes) == 6, "Expected six distinct biomes"
assert all(biome in CATALOG for biome in biomes), "Every biome must have animals"
assert "createAnimalModel" in MAIN and "EvolutionStages" in MAIN, "Stage-aware animal model builder missing"
assert "buildScenery" in MAIN and "TreeCanopy" in MAIN and "Crystal" in MAIN, "Procedural scenery systems missing"
assert "makeGuardian" in MAIN and "GuardianCatchDistance" in MAIN, "Guardian pursuit gameplay missing"
assert "StoredAnimals" in MAIN and "DepositAnimal" in MAIN and "CollectIncome" in MAIN, "Farm loop missing"
assert "renderBarn" in MAIN and "StageMultiplier" in MAIN, "Evolution and barn income need to be linked"
assert "GAMEPASSES" not in CLIENT and "PASSES" not in CLIENT, "Gamepass UI must not exist"
print(f"PASS FreshWorld: {len(animal_ids)} species, {len(biomes)} biomes, procedural animal models, guardians and barn evolution.")
