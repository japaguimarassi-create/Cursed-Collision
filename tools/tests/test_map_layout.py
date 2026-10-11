from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
WORLD = (ROOT / "src/RoubeUmAnimal/ServerScriptService/Services/WorldBuilder.lua").read_text(encoding="utf-8")
CATALOG = (ROOT / "src/RoubeUmAnimal/ReplicatedStorage/Shared/AnimalCatalog.lua").read_text(encoding="utf-8")

definitions = re.findall(r'^\s{4}(\w+) = table\.freeze\(\{\s*\n\s{8}Id = "([^"]+)"', CATALOG, re.MULTILINE)
animal_ids = {animal_id for _, animal_id in definitions}
spawn_ids = set(re.findall(r'\{\s*"([A-Za-z0-9]+)",\s*CFrame\.new\(', WORLD))
assert animal_ids, "No animal definitions found"
assert animal_ids.issubset(spawn_ids), "Every catalog animal must have a map spawn"
assert "for index = 1, 8 do" in WORLD, "Expected eight player bases"
assert 'part(base, "SellPart"' in WORLD, "Sell area missing"
assert 'SetAttribute("TrainingType", "Treadmill")' in WORLD, "Treadmill station missing"
assert 'SetAttribute("TrainingType", "BenchPress")' in WORLD, "Bench press missing"
assert 'createBiome(mapFolder, "Farm"' in WORLD, "Farm biome missing"
assert 'createBiome(mapFolder, "Jungle"' in WORLD, "Jungle biome missing"
assert 'createBiome(mapFolder, "Volcano"' in WORLD, "Volcano biome missing"
assert "LavaRiver" in WORLD and "TakeDamage(12)" in WORLD, "Lava damage behaviour missing"
print("PASS RoubeUmAnimalMapSpec")
