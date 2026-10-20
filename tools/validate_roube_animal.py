import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "default.project.json"
SOURCE_ROOT = ROOT / "src/StealAnAnimal"

REQUIRED_FILES = [
    "src/StealAnAnimal/ReplicatedStorage/Shared/Config.lua",
    "src/StealAnAnimal/ReplicatedStorage/Shared/AnimalCatalog.lua",
    "src/StealAnAnimal/ReplicatedStorage/Shared/GameplayRules.lua",
    "src/StealAnAnimal/ServerScriptService/Main.server.lua",
    "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua",
    "src/StealAnAnimal/Workspace/StealAnAnimalWorld.model.json",
    "tools/tests/test_rbxl_file.py",
    "tools/tests/run.luau",
    "tools/tests/test_map_layout.py",
    "tools/tests/test_monetization.py",
    "tools/tests/test_core_reliability.py",
    "README.md",
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

    if project.get("name") != "StealAnAnimal":
        fail("Rojo project name must be StealAnAnimal")

    tree = project.get("tree", {})
    expected = {
        "ReplicatedStorage": "src/StealAnAnimal/ReplicatedStorage",
        "ServerScriptService": "src/StealAnAnimal/ServerScriptService",
        "StarterPlayer.StarterPlayerScripts": "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts",
        "Workspace": "src/StealAnAnimal/Workspace",
    }
    for route, path in expected.items():
        node = tree
        for part in route.split("."):
            node = node.get(part, {})
        if node.get("$path") != path:
            fail(f"Rojo mapping mismatch for {route}")

    config = read("src/StealAnAnimal/ReplicatedStorage/Shared/Config.lua")
    catalog = read("src/StealAnAnimal/ReplicatedStorage/Shared/AnimalCatalog.lua")
    rules = read("src/StealAnAnimal/ReplicatedStorage/Shared/GameplayRules.lua")
    main_source = read("src/StealAnAnimal/ServerScriptService/Main.server.lua")
    client = read("src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua")

    checks = [
        ("fresh release tag", 'ReleaseTag = "StealAnAnimal-FromScratch-2026.10.20-r7"' in config),
        ("four life stages", all(token in config for token in ('Name = "Baby"', 'Name = "Child"', 'Name = "Teen"', 'Name = "Adult"'))),
        ("fifty-percent income evolution", "EvolutionIncomeMultiplier = 1.5" in config and "EvolutionIncomeMultiplier" in rules and "StageMultiplier" in rules and "growth ^" in rules),
        ("eight sequential biomes", all(token in config for token in ('Id = "Meadow"', 'Id = "Lake"', 'Id = "Forest"', 'Id = "Wetlands"', 'Id = "Frost"', 'Id = "Savanna"', 'Id = "Volcano"', 'Id = "Ocean"', 'Phase = 1, CenterX = 170', 'Phase = 8, CenterX = 1430'))),
        ("preview is retained until runtime map is built", all(token in main_source for token in ('local previewWorld = Workspace:FindFirstChild("StealAnAnimalWorld")', 'world.Name = "StealAnAnimalRuntimeWorld"', 'previewWorld:Destroy()'))),
        ("rectangular farms and clear corridor", all(token in main_source for token in ("basePositions = {", "CorridorFloor", "CorridorEdge", "PAI PROTETOR"))),
        ("original chicken, swan, and whale models", all(token in main_source for token in ("HenComb", "SwanNeck", "WhaleTailFluke"))),
        ("session-locked profiles and stage-aware offline income", all(token in main_source for token in ("acquireSession", "sessionTokens", "SESSION_LEASE_SECONDS", "ExpiresAt", "Store:UpdateAsync", "offlineIncome", "OfflineIncomeCapSeconds"))),
        ("server validated capture and deposit", all(token in main_source for token in ("ProximityPromptService.PromptTriggered", "wildRecords[model]", "depositAnimal", 'OwnerUserId") ~= player.UserId'))),
        ("guardian pursuit and escape", all(token in main_source for token in ("makeGuardian", "GuardianCatchDistance", "GuardianSpeed", "clearCarry(targetPlayer"))),
        ("original procedural models and scenery", all(token in main_source for token in ("createAnimalModel", "buildScenery", "TreeCanopy", "Crystal", "FountainGem"))),
        ("server-side treadmill training and capped movement", all(token in main_source for token in ("createTreadmill", "TrainingZone", "Rules.TrainingGain", "Rules.MoveSpeed", "Config.MaxSpeedPoints", "MaxTreadmillLevel"))),
        ("standing training does not require forced movement", "zone.CFrame:PointToObjectSpace(root.Position)" in main_source and "humanoid.MoveDirection.Magnitude > 0.12" not in main_source),
        ("animated belts and farm-owned treadmill upgrades", all(token in main_source for token in ("treadmillStrips", "TreadmillBeltSpeed", "UpgradeTreadmill", 'ownerBase:GetAttribute("OwnerUserId") ~= player.UserId'))),
        ("treadmill UI reports speed and upgrade levels", all(token in client for token in ("TreadmillStatus", "TreadmillLevel", "TreadmillGain", "EffectiveWalkSpeed", "MELHORAR ESTEIRA"))),
        ("responsive HUD and gameplay actions", all(token in client for token in ("TouchEnabled", "StealAnAnimalHUD", "RequestUpgrade", "RequestCollect", "TopDashboard", "ActionDock", "Modal"))),
        ("persistent server-validated rebirth progression", all(token in main_source for token in ("RequestRebirth", "requestRebirth", "Rules.RebirthCost", "profile.Rebirths += 1", "saveProfile(player)", "Rebirths = profile.Rebirths")) and all(token in rules for token in ("RebirthCost", "RebirthIncomeMultiplier"))),
        ("rebirth confirmation, bonus, and reset explained", all(token in client for token in ("confirmingRebirth", "CONFIRMAR E REINICIAR", "RebirthMultiplier", "RebirthCost"))),
        ("no monetization in fresh runtime", not any(token in config + catalog + rules + main_source + client for token in ("MarketplaceService", "PromptGamePassPurchase", "UserOwnsGamePassAsync", "RequestGamepass", "VIPFarm", "DoubleIncome", "DoubleSpeed", "HasExtraBarnSlots"))),
    ]
    failed = [name for name, ok in checks if not ok]
    for name, ok in checks:
        print(("PASS " if ok else "FAIL ") + name)
    if failed:
        fail("failed checks: " + ", ".join(failed))

    animal_ids = set(re.findall(r'Id = "([A-Za-z0-9]+)"', catalog))
    if len(animal_ids) < 20:
        fail("fresh animal catalogue must contain at least 20 species")
    for path in SOURCE_ROOT.rglob("*.lua"):
        content = path.read_text(encoding="utf-8")
        if any(marker in content for marker in ("<<<<<<<", "=======", ">>>>>>>")):
            fail("merge marker found in " + str(path.relative_to(ROOT)))

    publisher = read(".github/workflows/roblox-publish.yml")
    if "workflow_dispatch:" not in publisher or "ROBLOX_API_KEY" not in publisher:
        fail("publishing workflow must remain manual and key-protected")
    if "inputs.confirm == true" not in publisher:
        fail("production publishing must require an explicit manual confirmation")
    if "STEAL_ANIMAL_UNIVERSE_ID" not in publisher or "STEAL_ANIMAL_PLACE_ID" not in publisher:
        fail("production publishing must use explicitly configured destination IDs")
    if "5290480963" in publisher or "15338267657" in publisher:
        fail("production publishing must not guess Roblox destination IDs")

    preview = json.loads(read("src/StealAnAnimal/Workspace/StealAnAnimalWorld.model.json"))
    part_count = 0
    def count_parts(node):
        nonlocal part_count
        if node.get("ClassName") == "Part":
            part_count += 1
        for child in node.get("Children", []):
            count_parts(child)
    count_parts(preview)
    if part_count < 300:
        fail(f"static map preview contains only {part_count} Parts")
    preview_text = json.dumps(preview)
    if not all(token in preview_text for token in ("CorridorFloor", "Farm_8", "TreadmillBelt", "GuardianParent_Ocean", "PreviewBaby_Whale")):
        fail("static map preview is missing core map landmarks")
    print(f"Steal An Animal validation passed: {len(animal_ids)} species, {len(checks)} architecture checks, and {part_count} embedded Workspace Parts.")

if __name__ == "__main__":
    main()
