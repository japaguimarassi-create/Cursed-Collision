import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "default.project.json"

REQUIRED_FILES = [
    "src/RoubeUmAnimal/ReplicatedStorage/Shared/Config.lua",
    "src/RoubeUmAnimal/ReplicatedStorage/Shared/AnimalCatalog.lua",
    "src/RoubeUmAnimal/ServerScriptService/Main.server.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/ProfileService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/WorldBuilder.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/AnimalService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/TrainingService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/ShopService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/PassService.lua",
    "src/RoubeUmAnimal/ServerScriptService/Services/GuardianService.lua",
    "src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua",
    "docs/ROUBE_UM_ANIMAL.md",
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
    profiles = read("src/RoubeUmAnimal/ServerScriptService/Services/ProfileService.lua")
    animals = read("src/RoubeUmAnimal/ServerScriptService/Services/AnimalService.lua")
    training = read("src/RoubeUmAnimal/ServerScriptService/Services/TrainingService.lua")
    passes = read("src/RoubeUmAnimal/ServerScriptService/Services/PassService.lua")
    guardians = read("src/RoubeUmAnimal/ServerScriptService/Services/GuardianService.lua")
    world = read("src/RoubeUmAnimal/ServerScriptService/Services/WorldBuilder.lua")
    client = read("src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua")

    checks = [
        ("DataStore autosave", "AutosaveSeconds = 300" in config and "UpdateAsync" in profiles),
        ("session locking", "SessionLock" in profiles and "SessionId" in profiles),
        ("leaderstats", 'ensureValue("Moedas"' in profiles and 'ensureValue("Velocidade"' in profiles and 'ensureValue("Força"' in profiles),
        ("animal capture and sale", "StealAnimal" in animals and "SellPart" in animals and "RarityMultipliers" in animals),
        ("training stations", "Treadmill" in training and "BenchPress" in training),
        ("gamepass ownership checks", "UserOwnsGamePassAsync" in passes and "PromptGamePassPurchaseFinished" in passes),
        ("guardian pathfinding", "PathfindingService" in guardians and "ComputeAsync" in guardians),
        ("generated biomes", all(token in world for token in ('"Farm"', '"Jungle"', '"Volcano"'))),
        ("upgrade and pass buttons", "RequestUpgrade" in client and "RequestGamepass" in client),
    ]

    failed = [name for name, passed in checks if not passed]
    if failed:
        fail("failed checks: " + ", ".join(failed))

    for name in REQUIRED_FILES:
        content = read(name)
        if "TODO" in content or "ADD CODE HERE" in content:
            fail(f"unfinished placeholder found in {name}")

    publish = read(".github/workflows/roblox-publish.yml")
    if "on:\n  push:" in publish or "5290480963" in publish or "15338267657" in publish:
        fail("production publisher must not auto-publish to the retired experience")

    print(f"Roube Um Animal validation passed: {len(REQUIRED_FILES)} required files checked.")
    print("Project mappings, saving, capture/sale, training, gamepasses, guardians, UI, and publish guard verified.")

if __name__ == "__main__":
    main()
