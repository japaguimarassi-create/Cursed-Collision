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
    "src/RoubeUmAnimal/ServerScriptService/Services/BarnService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/ProgressionService.lua",
    "src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua",
    "tools/tests/run.luau",
    "tools/tests/test_map_layout.py",
    "tools/tests/test_monetization.py",
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
    if project.get("name") != "StealAnAnimal":
        fail("default.project.json must target StealAnAnimal")

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
    rules = read("src/RoubeUmAnimal/ReplicatedStorage/Shared/GameplayRules.lua")
    ids = read("src/RoubeUmAnimal/ReplicatedStorage/Shared/MonetizationIds.lua")
    profiles = read("src/RoubeUmAnimal/ServerScriptService/Services/ProfileService.lua")
    animals = read("src/RoubeUmAnimal/ServerScriptService/Services/AnimalService.lua")
    training = read("src/RoubeUmAnimal/ServerScriptService/Services/TrainingService.lua")
    shop = read("src/RoubeUmAnimal/ServerScriptService/Services/ShopService.lua")
    passes = read("src/RoubeUmAnimal/ServerScriptService/Services/PassService.lua")
    products = read("src/RoubeUmAnimal/ServerScriptService/Services/StackableProductService.lua")
    rebirth = read("src/RoubeUmAnimal/ServerScriptService/Services/RebirthService.lua")
    guardians = read("src/RoubeUmAnimal/ServerScriptService/Services/GuardianService.lua")
    world = read("src/RoubeUmAnimal/ServerScriptService/Services/WorldBuilder.lua")
    barn = read("src/RoubeUmAnimal/ServerScriptService/Services/BarnService.lua")
    progression = read("src/RoubeUmAnimal/ServerScriptService/Services/ProgressionService.lua")
    client = read("src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua")
    main = read("src/RoubeUmAnimal/ServerScriptService/Main.server.lua")

    checks = [
        ("release identifier", 'ReleaseTag = "StealAnAnimal-2026.10.11"' in config),
        ("DataStore session lock and atomic writes", "UpdateAsync" in profiles and "SessionLock" in profiles and "function transact" in profiles),
        ("legacy strength data is discarded safely", "current.Strength = nil" in profiles and "Config.SchemaVersion" in profiles),
        ("barn data persists", all(token in profiles for token in ("BarnAnimals", "BarnBank", "LastIncomeAt", "AddBarnAnimal", "CollectBarnIncome")) and "ExtraPassSlots" not in profiles and "ExtraBarnSlots" in profiles),
        ("one barn capacity setting across runtime", "ExtraPassSlots" not in world and "ExtraPassSlots" not in barn and "ExtraBarnSlots" in world and "ExtraBarnSlots" in barn),
        ("offline income is bounded and atomically claimed", "ClaimOfflineIncome" in profiles and "OfflineIncomeCapSeconds" in config and "current.LastIncomeAt = now" in profiles),
        ("capture-to-barn gameplay", all(token in animals for token in ("Rules.CanCapture", "AnimalService.Deposit", "scheduleRespawn", "CarryingAnimal")) and "AddBarnAnimal" in barn),
        ("no immediate animal sale", "SellPart" not in world and "salePrice" not in animals and "function deposit" in barn),
        ("passive income economy", all(token in barn for token in ("IncomePerSecond", "AccrueBarnIncome", "CollectBarnIncome", "BarnIncomeRate"))),
        ("six world regions", all(token in world for token in ('"Meadow"', '"Forest"', '"Wetlands"', '"Snow"', '"Savannah"', '"Volcano"')) and "BiomeCount" in world),
        ("eight player farms", "for index = 1, 8 do" in world and "OwnerUserId" in world),
        ("giant animal guardians", "createGuardianBeast" in world and "IsGiantAnimal" in world and "BeastTorso" in world),
        ("guardian pathfinding", "PathfindingService" in guardians and "ComputeAsync" in guardians and "AgentRadius = Config.Guardian.AgentRadius" in guardians),
        ("map errors are isolated", "xpcall(callback, debug.traceback)" in world and "MapReady" in world and "FallbackGround" in world),
        ("speed-only progression", "Rules.UpgradePrice" in shop and "Rules.CanCapture" in animals and "Treadmill" in training and "BenchPress" not in training and "Strength" not in config),
        ("catalog species support passive income", "IncomePerSecond" in catalog and "Catalog.All()" in catalog),
        ("distinct server-owned gamepasses", all(token in passes for token in ("UserOwnsGamePassAsync", "PromptGamePassPurchaseFinished", "DoubleIncome", "DoubleSpeed", "VIPFarm", "ExtraBarnSlots"))),
        ("repeatable receipts are idempotent", all(token in products for token in ("ProcessReceipt", "PurchaseId", "PurchaseGranted", "NotProcessedYet", "SpeedBoost", "CoinBundle")) and "ProcessedPurchases" in profiles),
        ("rebirth persists an income bonus", "PerformRebirth" in profiles and "RebirthCoinsRequired" in config and "RebirthIncomeBonusPerRebirth" in config),
        ("daily rewards, quest claims and codes persist", all(token in progression for token in ("ClaimDailyReward", "ClaimQuest", "RedeemCode", "FARMFAMILY", "WILDSTART", "BARNBOOST"))),
        ("adapted UI pack features", all(token in client for token in ("UIGradient", "renderBarn", "renderAnimals", "renderPasses", "renderQuests", "renderDaily", "renderSettings", "renderStats", "StealAnAnimalHUD"))),
        ("mobile input and safe area", all(token in client for token in ("CoreUISafeInsets", ".Activated:Connect", "ViewportSize", "ScrollingFrame"))),
        ("client-server remote wiring", all(token in main for token in ("RequestUpgrade", "RequestGamepass", "RequestStackableProduct", "RequestDailyReward", "RequestRedeemCode", "RequestQuest", "RequestCollectBarnIncome"))),
        ("barn collection UI checks ownership and distance", "collectBarnRemote:FireServer()" in client and "local function collectFromUI(player)" in barn and "validAtPad(player, base, pad)" in barn),
        ("no strength in client-facing gameplay", "Strength" not in catalog and "RequiredStrength" not in catalog and "Strength" not in client and "Força" not in client),
    ]
    failed = [name for name, ok in checks if not ok]
    if failed:
        fail("failed checks: " + ", ".join(failed))

    definitions = re.findall(r'^\s{4}(\w+) = table\.freeze\(\{\s*\n\s{8}Id = "([^"]+)"', catalog, re.MULTILINE)
    catalog_ids = {animal_id for _, animal_id in definitions}
    spawn_ids = set(re.findall(r'\{\s*"([A-Za-z0-9]+)",\s*CFrame\.new\(', world))
    if len(catalog_ids) < 20:
        fail("animal catalogue should contain at least 20 species")
    missing_spawns = sorted(catalog_ids - spawn_ids)
    if missing_spawns:
        fail("catalog species without world spawns: " + ", ".join(missing_spawns))

    pass_section = re.search(r"Passes = table\.freeze\(\{(.*?)\}\)", ids, re.S)
    product_section = re.search(r"Products = table\.freeze\(\{(.*?)\}\)", ids, re.S)
    if not pass_section or not product_section:
        fail("monetization ID registry could not be parsed")
    pass_ids = dict((name, int(value)) for name, value in re.findall(r"(\w+)\s*=\s*(\d+)", pass_section.group(1)))
    product_ids = dict((name, int(value)) for name, value in re.findall(r"(\w+)\s*=\s*(\d+)", product_section.group(1)))
    if set(pass_ids) != {"DoubleIncome", "DoubleSpeed", "VIPFarm", "ExtraBarnSlots"}:
        fail("gamepass keys do not match the implemented benefits")
    if set(product_ids) != {"SpeedBoost", "CoinBundle"}:
        fail("developer product keys do not match the implemented receipt handlers")
    configured = [value for value in list(pass_ids.values()) + list(product_ids.values()) if value > 0]
    if len(configured) != len(set(configured)):
        fail("nonzero monetization IDs must be unique")

    publisher = read(".github/workflows/roblox-publish.yml")
    for token in ("workflow_dispatch:", "ROBLOX_API_KEY", "ROUBE_ANIMAL_UNIVERSE_ID", "ROUBE_ANIMAL_PLACE_ID", "15338267657", "5290480963"):
        if token not in publisher:
            fail("publisher is missing a target safety setting: " + token)
    if "contains(github.event.head_commit.message, '[publish-roube-um-animal]')" not in publisher:
        fail("production publishing must require explicit release confirmation")

    for name in REQUIRED_FILES:
        if name.endswith((".lua", ".luau")):
            content = read(name)
            if any(marker in content for marker in ("<<<<<<<", "=======", ">>>>>>>")):
                fail("merge marker found in " + name)
            if "TODO" in content or "ADD CODE HERE" in content:
                fail("unfinished placeholder found in " + name)
            if "src/CollisionBattlestar/" in content:
                fail("legacy runtime reference found in " + name)

    print(f"Steal An Animal validation passed: {len(REQUIRED_FILES)} required files and {len(checks)} architecture checks.")
    print("Verified: barn storage and income, six biomes, animal spawns, giant guardians, speed-only progression, remotes and monetization separation.")

if __name__ == "__main__":
    main()
