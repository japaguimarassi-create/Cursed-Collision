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
assert '"Farm", Vector3.new(160, -1, 0)' in WORLD, "Farm biome missing"
assert '"Jungle", Vector3.new(320, -1, 0)' in WORLD, "Jungle biome missing"
assert '"Volcano", Vector3.new(495, -1, 0)' in WORLD, "Volcano biome missing"
assert "PORTAL_DA_FAZENDA" in WORLD and "PORTAL_DA_SELVA" in WORLD and "PORTAL_DO_VULCAO" in WORLD, "Biome gateways missing"
assert "createFlowerPatch" in WORLD and "createMushroom" in WORLD and "createCrystalCluster" in WORLD, "Biome landmarks missing"
assert "xpcall(callback, debug.traceback)" in WORLD and "MapReady" in WORLD, "Map build diagnostics missing"
assert "FallbackGround" in WORLD and "FallbackSpawn" in WORLD, "Map fallback missing"
assert "LavaRiver" in WORLD and "TakeDamage(12)" in WORLD, "Lava damage behaviour missing"
print("PASS RoubeUmAnimalMapSpec")
