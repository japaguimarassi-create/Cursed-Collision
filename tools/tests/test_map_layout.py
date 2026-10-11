from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
WORLD = (ROOT / "src/RoubeUmAnimal/ServerScriptService/Services/WorldBuilder.lua").read_text(encoding="utf-8")
CATALOG = (ROOT / "src/RoubeUmAnimal/ReplicatedStorage/Shared/AnimalCatalog.lua").read_text(encoding="utf-8")
CONFIG = (ROOT / "src/RoubeUmAnimal/ReplicatedStorage/Shared/Config.lua").read_text(encoding="utf-8")
ANIMALS = (ROOT / "src/RoubeUmAnimal/ServerScriptService/Services/AnimalService.lua").read_text(encoding="utf-8")
BARN = (ROOT / "src/RoubeUmAnimal/ServerScriptService/Services/BarnService.lua").read_text(encoding="utf-8")
CLIENT = (ROOT / "src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")

definitions = re.findall(r'^\s{4}(\w+) = table\.freeze\(\{\s*\n\s{8}Id = "([^"]+)"', CATALOG, re.MULTILINE)
animal_ids = {animal_id for _, animal_id in definitions}
spawn_ids = set(re.findall(r'\{\s*"([A-Za-z0-9]+)",\s*CFrame\.new\(', WORLD))
assert len(animal_ids) >= 20, "Expected a varied animal catalogue"
assert animal_ids.issubset(spawn_ids), "Every catalog animal must have a world spawn"
assert "for index = 1, 8 do" in WORLD, "Expected eight player farms"
assert 'part(base, "BarnDepositPad"' in WORLD, "Barn deposit pad missing"
assert 'part(base, "IncomeCollectPad"' in WORLD, "Income collection pad missing"
assert 'SetAttribute("TrainingType", "Treadmill")' in WORLD, "Speed treadmill missing"
assert 'createBarnAnimalDisplay' in WORLD and 'SetBarnAnimals(player, animalIds)' in WORLD, "Barn display renderer missing"
assert "ExtraBarnSlots" in WORLD, "Extra barn slots need visible lock state"
for biome in ("Meadow", "Forest", "Wetlands", "Snow", "Savannah", "Volcano"):
    assert '"' + biome + '"' in WORLD, f"{biome} zone missing"
assert 'biomeName .. "Ground"' in WORLD, "Biome floors missing"
assert "MapReady" in WORLD and "BiomeCount" in WORLD and "AnimalCount" in WORLD, "Map readiness metrics missing"
assert "xpcall(callback, debug.traceback)" in WORLD, "Map build steps must fail independently"
assert "CFrame.new(495, 0.09, 0)" in WORLD, "Main path must sit above biome ground"
assert "createGuardianBeast" in WORLD and "IsGiantAnimal" in WORLD, "Giant animal guardians missing"
assert "IncomePerSecond" in CATALOG and "BarnBank" in BARN, "Passive barn income missing"
assert "ClaimOfflineIncome" in BARN and "OfflineIncomeCapSeconds" in CONFIG, "Offline income cap missing"
assert "Rules.CanCapture" in ANIMALS and "AnimalService.Deposit" in ANIMALS, "Capture-to-barn loop missing"
assert "BenchPress" not in WORLD and "RequiredStrength" not in CATALOG, "Strength progression must be removed"
assert "Strength" not in CLIENT and "Força" not in CLIENT, "Strength UI must be removed"
assert "UIGradient" in CLIENT and "renderBarn" in CLIENT and "renderQuests" in CLIENT, "Adapted pack-style UI screens missing"
print(f"PASS StealAnAnimalMapSpec: {len(animal_ids)} species, 6 biomes, 8 farms, giant guardians and barn income.")
