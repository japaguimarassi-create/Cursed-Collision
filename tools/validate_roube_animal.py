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
    "src/StealAnAnimal/ServerScriptService/BotX.server.lua",
    "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua",
    "src/StealAnAnimal/Workspace/StealAnAnimalWorld.model.json",
    "tools/tests/test_rbxl_file.py",
    "tools/tests/run.luau",
    "tools/tests/test_map_layout.py",
    "tools/tests/test_monetization.py",
    "tools/tests/test_core_reliability.py",
    "tools/tests/test_botx_npc.py",
    "src/StealAnAnimal/ServerScriptService/StudioAudit.server.lua",
    "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/StudioAudit.client.lua",
    "tools/studio-tests/StealAnAnimalAudit.plugin.lua",
    "tools/tests/test_studio_audit.py",
    "tools/simulate_studio_run.py",
    "docs/STUDIO_AUTOMATED_AUDIT.md",
    "README.md",
    "docs/ROUBE_UM_ANIMAL.md",
    "docs/HUD_DESIGN_RESEARCH_2026-10-20.md",
    "docs/STEAL_AN_EGG_MAP_RESEARCH_2026-10-20.md",
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
    bot_x = read("src/StealAnAnimal/ServerScriptService/BotX.server.lua")
    client = read("src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua")

    checks = [
        ("fresh release tag", 'ReleaseTag = "StealAnAnimal-FromScratch-2026.10.20-r7"' in config),
        ("four life stages", all(token in config for token in ('Name = "Baby"', 'Name = "Child"', 'Name = "Teen"', 'Name = "Adult"'))),
        ("fifty-percent income evolution", "EvolutionIncomeMultiplier = 1.5" in config and "EvolutionIncomeMultiplier" in rules and "StageMultiplier" in rules and "growth ^" in rules),
        ("eight sequential biomes", all(token in config for token in ('Id = "Meadow"', 'Id = "Lake"', 'Id = "Forest"', 'Id = "Wetlands"', 'Id = "Frost"', 'Id = "Savanna"', 'Id = "Volcano"', 'Id = "Ocean"', 'Phase = 1, CenterX = 170', 'Phase = 8, CenterX = 1430'))),
        ("preview is retained until runtime map is built", all(token in main_source for token in ('local previewWorld = Workspace:FindFirstChild("StealAnAnimalWorld")', 'world.Name = "StealAnAnimalRuntimeWorld"', 'previewWorld:Destroy()'))),
        ("rectangular farms and clear corridor", all(token in main_source for token in ("basePositions = {", "CorridorFloor", "CorridorEdge", "PAI PROTETOR"))),
        ("egg-stealing map landmarks and fenced farms", all(token in main_source for token in ("CorridorBoundaryWall", "EggNestBase", "WildEgg", "PenFenceBackLower", "PenFenceGateLeftLower"))),
        ("original chicken, swan, and whale models", all(token in main_source for token in ("HenComb", "SwanNeck", "WhaleTailFluke"))),
        ("session-locked profiles and stage-aware offline income", all(token in main_source for token in ("acquireSession", "sessionTokens", "SESSION_LEASE_SECONDS", "ExpiresAt", "Store:UpdateAsync", "offlineIncome", "OfflineIncomeCapSeconds"))),
        ("server validated capture and deposit", all(token in main_source for token in ("ProximityPromptService.PromptTriggered", "wildRecords[model]", "depositAnimal", 'OwnerUserId") ~= player.UserId'))),
        ("guardian pursuit and escape", all(token in main_source for token in ("makeGuardian", "GuardianCatchDistance", "GuardianSpeed", "clearCarry(targetPlayer"))),
        ("original procedural models and scenery", all(token in main_source for token in ("createAnimalModel", "buildScenery", "TreeCanopy", "Crystal", "FountainGem"))),
        ("server-side treadmill training and capped movement", all(token in main_source for token in ("createTreadmill", "TrainingZone", "Rules.TrainingGain", "Rules.MoveSpeed", "Config.MaxSpeedPoints", "MaxTreadmillLevel"))),
        ("standing training does not require forced movement", "zone.CFrame:PointToObjectSpace(root.Position)" in main_source and "humanoid.MoveDirection.Magnitude > 0.12" not in main_source),
        ("animated belts and farm-owned treadmill upgrades", all(token in main_source for token in ("treadmillStrips", "TreadmillBeltSpeed", "UpgradeTreadmill", 'ownerBase:GetAttribute("OwnerUserId") ~= player.UserId'))),
        ("shop UI reports speed and upgrade levels", all(token in client for token in ("TreadmillLevel", "TreadmillGain", "TreadmillUpgradeCost", "EffectiveWalkSpeed", "OpenShop", "LOJA DE MELHORIAS"))),
        ("animal index is available by biome", all(token in client for token in ("AnimalIndex", "ÍNDICE ANIMAL", "Catalog.ForBiome(biome.Id)"))),
        ("responsive HUD and gameplay actions", all(token in client for token in ("TouchEnabled", "StealAnAnimalHUD", "RequestUpgrade", "RequestCollect", "TopDashboard", "QuickActions", "OpenIndex", "ContextObjective", "ScreenInsets", "Modal"))),
        ("Studio-only QA bots and sandbox profiles", "RunService:IsStudio()" in config and "StealAnAnimal_StudioSandbox_v1" in config and "if not RunService:IsStudio() then return end" in read("src/StealAnAnimal/ServerScriptService/StudioAudit.server.lua") and "if not RunService:IsStudio() then return end" in read("src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/StudioAudit.client.lua") and "StudioTestService:ExecuteMultiplayerTestAsync(2" in read("tools/studio-tests/StealAnAnimalAudit.plugin.lua")),
        ("BotX human Bacon Hair NPCs are player-gated, non-player, grounded, pathfinding observers, and session-logged", all(token in bot_x for token in (
            "local BOT_COUNT = 3", "CountsAsPlayer", "custom_bacon_hair", "PathfindingService:CreatePath",
            "Players.PlayerAdded", "Players.PlayerRemoving", "ProximityPromptService.PromptTriggered",
            "leftLeg.CanCollide = true", "rightLeg.CanCollide = true",
            "GetAttributeChangedSignal", "player_state_changed", 'coins = player:GetAttribute("Coins")',
            'barnBank = player:GetAttribute("BarnBank")', 'rebirths = player:GetAttribute("Rebirths")',
            "remote_action", "state_snapshot", "BOTX_SESSION_REPORT", "MAX_RETAINED_EVENTS",
            "includeRecentEvents and retainedEvents or nil"))),
        ("CI source simulator produces structured non-Studio reports", '"studioRuntimeExecuted": False' in read("tools/simulate_studio_run.py") and '"source_and_layout_simulation"' in read("tools/simulate_studio_run.py") and "studio-run-simulation.json" in read("tools/simulate_studio_run.py")),
        ("minimal greenfield HUD and custom icon actions", all(token in client for token in ("makeGlyph", 'makeDockButton("OpenShop"', 'makeDockButton("OpenIndex"', 'makeDockButton("OpenMore"', "objectiveMarker", "RebirthBadge")) and all(token not in client for token in ("ActionDock", "helpButton.Activated", "barnButton.Activated", "collectButton.Activated", "rebirthButton.Activated"))),
        ("persistent server-validated rebirth progression", all(token in main_source for token in ("RequestRebirth", "requestRebirth", "Rules.RebirthCost", "Rules.RebirthSpeedRequirement(Config)", "profile.Rebirths += 1", "saveProfile(player)", "Rebirths = profile.Rebirths")) and all(token in rules for token in ("RebirthCost", "RebirthIncomeMultiplier", "RebirthSpeedRequirement")) and "RebirthCoinsRequired = 100000" in config and "MaxRebirths = 25" in config),
        ("rebirth confirmation and original reset semantics", all(token in client for token in ("confirmingRebirth", "CONFIRMAR RENASCIMENTO", "RebirthMultiplier", "RebirthRequiredSpeed", "RebirthCost")) and "profile.Coins = 0" in main_source and "profile.Speed = 0" in main_source),
        ("daily rewards quests redeem codes stats and MapBot are restored", all(token in main_source for token in ("RequestDailyReward", "RequestRedeemCode", "RequestQuest", "RequestMapBot", "DailyStreak", "RedeemedCodes", "QuestClaims", "PathfindingService:CreatePath")) and all(token in client for token in ("Daily", "Quests", "Codes", "Stats", "Settings", "Diagnostics", "mapBotReportRemote.OnClientEvent"))),
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
    if not all(token in preview_text for token in ("CorridorFloor", "Farm_8", "TreadmillBelt", "GuardianParent_Ocean", "PreviewBaby_Whale", "CorridorBoundaryWall", "EggNestBase", "WildEgg", "PenFenceBackLower")):
        fail("static map preview is missing core map landmarks")
    print(f"Steal An Animal validation passed: {len(animal_ids)} species, {len(checks)} architecture checks, and {part_count} embedded Workspace Parts.")

if __name__ == "__main__":
    main()
