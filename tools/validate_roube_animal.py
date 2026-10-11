import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "default.project.json"

REQUIRED_FILES = [
    "src/RoubeUmAnimal/ReplicatedStorage/Shared/Config.lua",
    "src/RoubeUmAnimal/ReplicatedStorage/Shared/AnimalCatalog.lua",
    "src/RoubeUmAnimal/ReplicatedStorage/Shared/GameplayRules.lua",
    "src/RoubeUmAnimal/ReplicatedStorage/Shared/MonetizationIds.lua",
    "src/RoubeUmAnimal/ServerScriptService/Main.server.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/ProfileService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/WorldBuilder.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/AnimalService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/TrainingService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/ShopService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/PassService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/StackableProductService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/RebirthService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/GuardianService.lua",
    "src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua",
    "tools/tests/run.luau",
    "docs/ROUBE_UM_ANIMAL.md",
]

RETIRED_WORKFLOWS = [
    ".github/workflows/developer-product-provision.yml",
    ".github/workflows/gamepass-provision.yml",
]

def fail(message):
    print("ERROR:", message)
    sys.exit(1)

def read(path):
    try:
        return (ROOT / path).read_text(encoding="utf-8")
    except OSError as exc:
        fail(f"cannot read {path}: {exc}")

def main():
    missing = [name for name in REQUIRED_FILES if not (ROOT / name).is_file()]
    if missing:
        fail("missing required files: " + ", ".join(missing))
    for path in RETIRED_WORKFLOWS:
        if (ROOT / path).exists():
            fail("retired workflow still enabled: " + path)

    try:
        project = json.loads(PROJECT.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"invalid default.project.json: {exc}")
    if project.get("name") != "RoubeUmAnimal":
        fail("default.project.json must target RoubeUmAnimal")

    tree = project.get("tree", {})
    expected = {
        "ReplicatedStorage": "src/RoubeUmAnimal/ReplicatedStorage",
        "ServerScriptService": "src/RoubeUmAnimal/ServerScriptService",
        "StarterPlayer.StarterPlayerScripts": "src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts",
    }
    for route, path in expected.items():
        node = tree
        for part_name in route.split("."):
            node = node.get(part_name, {})
        if node.get("$path") != path:
            fail(f"project mapping mismatch for {route}")

    config = read("src/RoubeUmAnimal/ReplicatedStorage/Shared/Config.lua")
    catalog = read("src/RoubeUmAnimal/ReplicatedStorage/Shared/AnimalCatalog.lua")
    profiles = read("src/RoubeUmAnimal/ServerScriptService/Services/ProfileService.lua")
    animals = read("src/RoubeUmAnimal/ServerScriptService/Services/AnimalService.lua")
    training = read("src/RoubeUmAnimal/ServerScriptService/Services/TrainingService.lua")
    shop = read("src/RoubeUmAnimal/ServerScriptService/Services/ShopService.lua")
    passes = read("src/RoubeUmAnimal/ServerScriptService/Services/PassService.lua")
    product_service = read("src/RoubeUmAnimal/ServerScriptService/Services/StackableProductService.lua")
    rebirth_service = read("src/RoubeUmAnimal/ServerScriptService/Services/RebirthService.lua")
    monetization_ids = read("src/RoubeUmAnimal/ReplicatedStorage/Shared/MonetizationIds.lua")
    guardians = read("src/RoubeUmAnimal/ServerScriptService/Services/GuardianService.lua")
    world = read("src/RoubeUmAnimal/ServerScriptService/Services/WorldBuilder.lua")
    client = read("src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua")
    rules = read("src/RoubeUmAnimal/ReplicatedStorage/Shared/GameplayRules.lua")

    checks = [
        ("DataStore update and session locking", "UpdateAsync" in profiles and "SessionLock" in profiles),
        ("leaderstats", all(token in profiles for token in ('ensureValue("Moedas"', 'ensureValue("Velocidade"', 'ensureValue("Força"'))),
        ("capture and sale rules", "Rules.CanCapture" in animals and "Rules.SalePrice" in animals and "RarityMultipliers" in catalog),
        ("weight movement rule", "Rules.CarrySpeed" in animals and "CarryPenaltyStartRatio" in config),
        ("shared upgrade rule", "Rules.UpgradePrice" in shop),
        ("training stations", "Treadmill" in training and "BenchPress" in training),
        ("gamepass checks", all(token in passes for token in ("UserOwnsGamePassAsync", "PromptGamePassPurchaseFinished", "DoubleSpeed", "DoubleStrength", "DoubleCoins", "VIPSpeed"))),
        ("monetization ID registry", all(token in monetization_ids for token in ("DoubleSpeed", "DoubleStrength", "DoubleCoins", "VIPSpeed", "StackableSpeed", "StackableStrength"))),
        ("stackable purchase receipts", all(token in product_service for token in ("ProcessReceipt", "PurchaseGranted", "NotProcessedYet", "GrantStackableProduct", "PurchaseId")) and "ProcessedPurchases" in profiles),
        ("rebirth persistence", all(token in profiles and token in rebirth_service for token in ("PerformRebirth", "MaxRebirths")) and "RebirthCoinBonusPerRebirth" in config),
        ("cross-platform HUD", all(token in client for token in ("DeviceSafeInsets", ".Activated:Connect", "ViewportSize", "RequestStackableProduct", "RequestRebirth"))),
        ("guardian pathfinding", "PathfindingService" in guardians and "ComputeAsync" in guardians),
        ("all three biomes", all(token in world for token in ('"Farm"', '"Jungle"', '"Volcano"'))),
        ("HUD remotes", 'gui.Name = "RoubeUmAnimalHUD"' in client and "RequestUpgrade" in client and "RequestGamepass" in client),
        ("shared rules API", all(name in rules for name in ("IsFinite", "Integer", "CanCapture", "CarrySpeed", "SalePrice", "UpgradePrice"))),
    ]
    failed = [name for name, passed in checks if not passed]
    if failed:
        fail("failed checks: " + ", ".join(failed))

    catalog_definitions = re.findall(r'^\s{4}(\w+) = table\.freeze\(\{\s*\n\s{8}Id = "([^"]+)"', catalog, re.MULTILINE)
    catalog_ids = {animal_id for _, animal_id in catalog_definitions}
    spawn_ids = set(re.findall(r'\{\s*"([A-Za-z0-9]+)",\s*CFrame\.new\(', world))
    if not catalog_ids:
        fail("animal catalogue could not be parsed")
    missing_spawns = sorted(catalog_ids - spawn_ids)
    if missing_spawns:
        fail("catalog animals without map spawns: " + ", ".join(missing_spawns))

    max_strength_match = re.search(r"MaxStrength\s*=\s*(\d+)", config)
    requirements = [int(value) for value in re.findall(r"RequiredStrength\s*=\s*(\d+)", catalog)]
    if not max_strength_match or not requirements:
        fail("strength limits could not be validated")
    if max(requirements) > int(max_strength_match.group(1)):
        fail("an animal requires more strength than the configured maximum")

    publisher = read(".github/workflows/roblox-publish.yml")
    for token in ("workflow_dispatch:", "ROBLOX_API_KEY", "ROUBE_ANIMAL_UNIVERSE_ID", "ROUBE_ANIMAL_PLACE_ID"):
        if token not in publisher:
            fail("publisher is missing required safety setting: " + token)
    if "push:" in publisher and "contains(github.event.head_commit.message, '[publish-roube-um-animal]')" not in publisher:
        fail("production push publishing must require the explicit release marker")
    if "5290480963" not in publisher or "15338267657" not in publisher:
        fail("publisher must explicitly block the retired experience IDs")

    for name in REQUIRED_FILES:
        if name.endswith((".lua", ".luau")):
            content = read(name)
            if any(marker in content for marker in ("<<<<<<<", "=======", ">>>>>>>")):
                fail("merge marker found in " + name)
            if "TODO" in content or "ADD CODE HERE" in content:
                fail("unfinished placeholder found in " + name)
            if "src/CollisionBattlestar/" in content:
                fail("legacy runtime reference found in " + name)

    print(f"Roube Um Animal validation passed: {len(REQUIRED_FILES)} required files checked.")
    print("DataStore, authoritative economy, capture, movement, upgrades, training, passes, guardians, map spawns and publisher controls verified.")

if __name__ == "__main__":
    main()
