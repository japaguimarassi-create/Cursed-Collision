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
    "src/StealAnAnimal/ReplicatedStorage/Shared/WorldBuilder.lua",
    "src/StealAnAnimal/ReplicatedStorage/Shared/AnimalFactory.lua",
    "src/StealAnAnimal/ReplicatedStorage/Shared/GuardianCatalog.lua",
    "src/StealAnAnimal/ReplicatedStorage/Shared/AnimalAnimator.lua",
    "src/StealAnAnimal/ReplicatedStorage/Shared/TreadmillAnimator.lua",
    "src/StealAnAnimal/ServerScriptService/Services/GuardianController.lua",
    "src/StealAnAnimal/ServerScriptService/Services/GuardianAI.lua",
    "src/StealAnAnimal/ServerScriptService/Services/ProfileStore.lua",
    "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/InteractionPrompt.lua",
    "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/AnimalAnimation.client.lua",
    "tools/tests/test_release_safety.py",
    "src/StealAnAnimal/ServerScriptService/Main.server.lua",
    "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua",
    "src/StealAnAnimal/Workspace/StealAnAnimalWorld.model.json",
    "tools/tests/test_rbxl_file.py",
    "tools/tests/run.luau",
    "tools/tests/test_map_layout.py",
    "tools/tests/test_monetization.py",
    "tools/tests/test_core_reliability.py",
    "tools/tests/test_guardian_ai.py",
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
    client = read("src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua")
    world_builder = read("src/StealAnAnimal/ReplicatedStorage/Shared/WorldBuilder.lua")
    animal_factory = read("src/StealAnAnimal/ReplicatedStorage/Shared/AnimalFactory.lua")
    guardian_catalog = read("src/StealAnAnimal/ReplicatedStorage/Shared/GuardianCatalog.lua")
    animal_animator = read("src/StealAnAnimal/ReplicatedStorage/Shared/AnimalAnimator.lua")
    treadmill_animator = read("src/StealAnAnimal/ReplicatedStorage/Shared/TreadmillAnimator.lua")
    guardian_controller = read("src/StealAnAnimal/ServerScriptService/Services/GuardianController.lua")
    guardian_ai = read("src/StealAnAnimal/ServerScriptService/Services/GuardianAI.lua")
    profile_store = read("src/StealAnAnimal/ServerScriptService/Services/ProfileStore.lua")
    interaction_prompt = read("src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/InteractionPrompt.lua")
    animation_client = read("src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/AnimalAnimation.client.lua")
    server_all = main_source + world_builder + animal_factory + profile_store + guardian_catalog + animal_animator + treadmill_animator + guardian_controller + guardian_ai
    client_all = client + interaction_prompt

    checks = [
        ("fresh release tag", 'ReleaseTag = "StealAnAnimal-FromScratch-2026.10.20-r7"' in config),
        ("four life stages", all(token in config for token in ('Name = "Baby"', 'Name = "Child"', 'Name = "Teen"', 'Name = "Adult"'))),
        ("fifty-percent income evolution", "EvolutionIncomeMultiplier = 1.5" in config and "EvolutionIncomeMultiplier" in rules and "StageMultiplier" in rules and "growth ^" in rules),
        ("eight sequential biomes", all(token in config for token in ('Id = "Meadow"', 'Id = "Lake"', 'Id = "Forest"', 'Id = "Wetlands"', 'Id = "Frost"', 'Id = "Savanna"', 'Id = "Volcano"', 'Id = "Ocean"', 'Phase = 1, CenterX = 170', 'Phase = 8, CenterX = 1430'))),
        ("eight biome speed requirements checked on egg capture", all(token in config for token in ("MinSpeed = 10", "MinSpeed = 100", "MinSpeed = 1230", "MinSpeed = 12300", "MinSpeed = 123000", "MinSpeed = 1230000", "MinSpeed = 12300000", "MinSpeed = 123000000", "MaxSpeedPoints = 150000000")) and all(token in main_source for token in ("requiredBiome", "profile.Speed < minimumSpeed", "spec.Biome")) and all(token in world_builder for token in ("biome.MinSpeed", "SPEED MÍNIMA")) and "enforceBiomeSpeedGates" not in main_source),
        ("preview is retained until runtime map is built", all(token in server_all for token in ('local previewWorld = Workspace:FindFirstChild("StealAnAnimalWorld")', 'world.Name = "StealAnAnimalRuntimeWorld"', 'previewWorld:Destroy()'))),
        ("rectangular farms and clear corridor", all(token in server_all for token in ("basePositions = {", "CorridorFloor", "CorridorEdge", "MainPath"))),
        ("egg-stealing map landmarks and fenced farms", all(token in server_all for token in ("CorridorBoundaryWall", "EggNestBase", "WildEgg", "PenFenceBackLower", "PenFenceGateLeftLower"))),
        ("original chicken, swan, and whale models", all(token in server_all for token in ("HenComb", "SwanNeck", "WhaleTailFluke"))),
        ("eight high-detail flagship pets", all(token in catalog for token in (
            'Id = "CrystalbackGecko"', 'Id = "BloomforgedBeetle"', 'Id = "RunebillBluejay"',
            'Id = "AstralJackalope"', 'Id = "SpiritwoodPanda"', 'Id = "Novafox"',
            'Id = "StarforgedSunlion"', 'Id = "VerdantSkyWhale"',
        )) and all(token in animal_factory for token in (
            'spec.Id == "CrystalbackGecko"', 'spec.Id == "BloomforgedBeetle"',
            'spec.Id == "RunebillBluejay"', 'spec.Id == "AstralJackalope"',
            'spec.Id == "SpiritwoodPanda"', 'spec.Id == "Novafox"',
            'spec.Id == "StarforgedSunlion"', 'spec.Id == "VerdantSkyWhale"',
            "Gecko raised scale", "Beetle armored elytra", "Bluejay layered wing feather",
            "Jackalope antler branch", "Spirit panda lantern", "Novafox giant star tail",
            "Sunlion crown mane crystal", "Sky whale ancient tree trunk",
        ))),
        ("all catalogue species have explicit species-specific visual detail branches", set(re.findall(r'spec\.Id == "([A-Za-z0-9]+)"', animal_factory)).issuperset(set(re.findall(r'Id = "([A-Za-z0-9]+)"', catalog)))),
        ("flagship material layers, rarity tiers, evolved halos, and elite lighting", all(token in animal_factory for token in (
            "local function crystal(", "local function glow(", "local rarityRanks", "model:SetAttribute(\"RarityTier\", rarityTier)",
            "Gecko tail band", "Beetle antenna stem", "Bluejay covert feather", "Jackalope antler jewel",
            "Spirit panda lantern frame", "Novafox tail luminous tip", "Sunlion radial mane plate",
            "Sky whale gill engraving", "Rarity ground halo", "RaritySparkles", "RarityCoreLight",
        ))),
        ("session-locked profiles and stage-aware offline income", all(token in server_all for token in ("acquireSession", "sessionTokens", "SESSION_LEASE_SECONDS", "ExpiresAt", "Store:UpdateAsync", "offlineIncome", "OfflineIncomeCapSeconds"))),
        ("server validated capture and deposit", all(token in server_all for token in ("ProximityPromptService.PromptTriggered", "wildRecords[model]", "depositAnimal", 'OwnerUserId") ~= player.UserId'))),
        ("eight dedicated guardians with rest/run/walk pursuit states", all(token in guardian_catalog for token in ("GuardianHen", "GuardianSwan", "GuardianScorpion", "GuardianTiger", "GuardianYeti", "GuardianHellhound", "GuardianWhale", "GuardianTyrannosaur")) and all(token in guardian_controller for token in ("GuardianCatalog.Get(biome.Id)", "Config.GuardianCatchDistance", 'model:SetAttribute("AnimationState", "Run")', 'model:SetAttribute("AnimationState", "Walk")', 'model:SetAttribute("AnimationState", "Rest")', "ClearCarry(targetPlayer)")) and all(token in main_source for token in ("guardianController:SpawnAll()", "guardianController:Step(deltaTime, carried)"))),
        ("animal walk rest run animations and custom guardian anatomy", all(token in animal_animator for token in ("Walk = true", "Rest = true", "Run = true", "self:Register(model", "self:SetState(model", "self:Step(deltaTime)", "self:SetViewPosition", "MaxDistance")) and all(token in animation_client for token in ("Workspace.DescendantAdded", 'GetAttributeChangedSignal("AnimationState")', "TreadmillAnimator.Step(treadmillEntries, os.clock())")) and all(token in animal_factory for token in ("GuardianHenTailFeather", "GuardianSwanWingFeather", "GuardianScorpionTailSegment", "GuardianTigerFlankStripe", "GuardianYetiFurTuft", "GuardianHellhoundHead", "GuardianWhaleBioluminescentSpot", "GuardianTyrannosaurDorsalPlate"))),
        ("treadmill belt, rollers, and level visuals use a dedicated module", all(token in treadmill_animator for token in ('Kind == "Roller"', "TreadmillBeltLength", "TreadmillBeltSpeed", "TreadmillLevel", "TrainingGain")) and ("TreadmillAnimator.ApplyLevel(treadmill, level, gain)" in main_source) and ("TreadmillAnimator.Step(treadmillEntries, os.clock())" in animation_client)),
        ("eight biomes receive the layered native geometry pass", all(token in world_builder for token in ("buildBiomeGeometry", "GateFooting", "GateFootInlay", "PathEdgeSegment", "PathEdgeFacet", "FacetedOutcrop", "GateBaseRing", "LakeBridgeSpan", "ForestMonolithLintel", "WetlandsRootRib", "FrostSculptedSpire", "VolcanoBasaltRidgeFin", "OceanCoralFan", "SavannaFossilRib"))),
        ("original procedural models and scenery", all(token in server_all for token in ("createAnimalModel", "buildScenery", "TreeCanopy", "Crystal", "HubSpawnMarker"))),
        ("server-side treadmill training and capped movement", all(token in server_all for token in ("createTreadmill", "TrainingZone", "Rules.TrainingGain", "Rules.MoveSpeed", "Config.MaxSpeedPoints", "MaxTreadmillLevel"))),
        ("standing training does not require forced movement", "zone.CFrame:PointToObjectSpace(root.Position)" in server_all and "humanoid.MoveDirection.Magnitude > 0.12" not in server_all),
        ("animated belts and farm-owned treadmill upgrades", all(token in server_all for token in ("TreadmillBeltSpeed", "UpgradeTreadmill", 'ownerBase:GetAttribute("OwnerUserId") ~= player.UserId')) and all(token in animation_client for token in ("MovingBeltStripe", "BeltRoller", "TreadmillAnimator.Step"))),
        ("shop UI reports speed and upgrade levels", all(token in client_all for token in ("TreadmillLevel", "TreadmillGain", "TreadmillUpgradeCost", "EffectiveWalkSpeed", "OpenShop", "LOJA DE MELHORIAS"))),
        ("animal index is available by biome", all(token in client_all for token in ("AnimalIndex", "ÍNDICE ANIMAL", "Catalog.ForBiome(biome.Id)"))),
        ("responsive HUD and gameplay actions", all(token in client_all for token in ("TouchEnabled", "StealAnAnimalHUD", "RequestUpgrade", "RequestCollect", "TopDashboard", "QuickActions", "OpenIndex", "ContextObjective", "ScreenInsets", "Modal"))),
        ("Studio-only QA bots and sandbox profiles", "RunService:IsStudio()" in config and "StealAnAnimal_StudioSandbox_v1" in config and "if not RunService:IsStudio() then return end" in read("src/StealAnAnimal/ServerScriptService/StudioAudit.server.lua") and "if not RunService:IsStudio() then return end" in read("src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/StudioAudit.client.lua") and "StudioTestService:ExecuteMultiplayerTestAsync(2" in read("tools/studio-tests/StealAnAnimalAudit.plugin.lua")),
        ("Studio QA audits live local animal and treadmill animations", all(token in read("src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/StudioAudit.client.lua") for token in ("Animal selvagem executa animação Walk local", "Faixa da esteira anima localmente")) and all(token in read("src/StealAnAnimal/ServerScriptService/StudioAudit.server.lua") for token in ("Oito guardiões distintos começam em repouso", "Esteiras têm metadados de animação local"))),
        ("BotX NPCs and MapBot diagnostics are removed from runtime", not any(token in main_source + client for token in ("BotXStatus", "RequestMapBot", "MapBotReport", "BOTX_SESSION_REPORT", "PathfindingService:CreatePath")) and not (SOURCE_ROOT / "ServerScriptService/BotX.server.lua").exists()),
        ("CI source simulator produces structured non-Studio reports", '"studioRuntimeExecuted": False' in read("tools/simulate_studio_run.py") and '"source_and_layout_simulation"' in read("tools/simulate_studio_run.py") and "studio-run-simulation.json" in read("tools/simulate_studio_run.py")),
        ("minimal greenfield HUD and custom icon actions", all(token in client_all for token in ("makeGlyph", 'makeDockButton("OpenShop"', 'makeDockButton("OpenIndex"', 'makeDockButton("OpenMore"', "objectiveMarker", "RebirthBadge")) and all(token not in client_all for token in ("ActionDock", "helpButton.Activated", "barnButton.Activated", "collectButton.Activated", "rebirthButton.Activated"))),
        ("persistent server-validated rebirth progression", all(token in server_all for token in ("RequestRebirth", "requestRebirth", "Rules.RebirthCost", "Rules.RebirthSpeedRequirement(Config)", "profile.Rebirths += 1", "saveProfile(player)", "Rebirths = profile.Rebirths")) and all(token in rules for token in ("RebirthCost", "RebirthIncomeMultiplier", "RebirthSpeedRequirement")) and "RebirthCoinsRequired = 100000" in config and "MaxRebirths = 25" in config),
        ("rebirth confirmation and original reset semantics", all(token in client_all for token in ("confirmingRebirth", "CONFIRMAR RENASCIMENTO", "RebirthMultiplier", "RebirthRequiredSpeed", "RebirthCost")) and "profile.Coins = 0" in server_all and "profile.Speed = 0" in server_all),
        ("daily rewards quests codes and statistics remain connected", all(token in server_all for token in ("RequestDailyReward", "RequestRedeemCode", "RequestQuest", "DailyStreak", "RedeemedCodes", "QuestClaims")) and all(token in client_all for token in ("Daily", "Quests", "Codes", "Stats", "Settings"))),
        ("no monetization in fresh runtime", not any(token in config + catalog + rules + server_all + client_all for token in ("MarketplaceService", "PromptGamePassPurchase", "UserOwnsGamePassAsync", "RequestGamepass", "VIPFarm", "DoubleIncome", "DoubleSpeed", "HasExtraBarnSlots"))),
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
    if "inputs.confirm == true && inputs.confirm_studio_runtime_qa == true" not in publisher:
        fail("production publishing must require manual confirmation plus real Studio/mobile QA")
    if "confirm_studio_runtime_qa:" not in publisher or "default: false" not in publisher:
        fail("real Studio/mobile QA confirmation must be required and default to false")
    if "STEAL_ANIMAL_STUDIO_QA_SHA" not in publisher or '"${STUDIO_QA_SHA}" = "${GITHUB_SHA}"' not in publisher:
        fail("publishing must be blocked unless runtime QA attestation matches the exact commit SHA")
    if "STEAL_ANIMAL_UNIVERSE_ID" not in publisher or "STEAL_ANIMAL_PLACE_ID" not in publisher:
        fail("production publishing must use explicitly configured destination IDs")
    if "5290480963" in publisher or "15338267657" in publisher:
        fail("production publishing must not guess Roblox destination IDs")
    if (ROOT / ".github/workflows/publish-roblox.yml").exists():
        fail("automatic Roblox publishing is disabled; use the explicit confirmation-gated workflow")
    if "abandonSession" not in profile_store or "local function releaseBase(player)" not in server_all:
        fail("profile lock recovery or farm cleanup service is missing")

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
    if any(token in preview_text for token in ("FarmBackWall", "FarmCanopy", "FarmCanopyPost", "BarnSign", "SpeedGateBarrier")):
        fail("static map must use open farm pens and passable biome signs, without houses or solid speed gates")
    if not all(token in preview_text for token in ("CorridorFloor", "Farm_8", "TreadmillBelt", "GuardianParent_Ocean", "PreviewBaby_Whale", "CorridorBoundaryWall", "EggNestBase", "WildEgg", "PenFenceBackLower", "MeadowSpeedRequirementSign", "OceanSpeedRequirementSign", "SavannaSpeedRequirementSign")):
        fail("static map preview is missing core map landmarks")
    print(f"Steal An Animal validation passed: {len(animal_ids)} species, {len(checks)} architecture checks, and {part_count} embedded Workspace Parts.")

if __name__ == "__main__":
    main()
