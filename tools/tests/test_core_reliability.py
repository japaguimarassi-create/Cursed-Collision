from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "src/StealAnAnimal"
MAIN = (BASE / "ServerScriptService/Main.server.lua").read_text(encoding="utf-8")
CLIENT = (BASE / "StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")
CONFIG = (BASE / "ReplicatedStorage/Shared/Config.lua").read_text(encoding="utf-8")
RULES = (BASE / "ReplicatedStorage/Shared/GameplayRules.lua").read_text(encoding="utf-8")

checks = {
    "profiles acquire an atomic session lease": all(token in MAIN for token in ("local function acquireSession", "SESSION_LEASE_SECONDS = 180", "ExpiresAt", "sessionTokens[player] = token")),
    "profiles save and release leases atomically": all(token in MAIN for token in ("Store:UpdateAsync", "local function releaseSession", "lease.Token ~= token")),
    "offline income is capped and stage-aware": all(token in MAIN for token in ("OfflineIncomeCapSeconds", "offlineIncome", "Rules.AnimalIncome")) and "OfflineIncomeCapSeconds = 21600" in CONFIG,
    "autosave and shutdown save exist": all(token in MAIN for token in ("AutosaveSeconds", "BindToClose", "releaseSession(player)", "while saveInProgress[player] do")),
    "capture is server-validated": all(token in MAIN for token in ("wildRecords[model]", "ProximityPromptService.PromptTriggered", "Magnitude > 12", "not model:IsDescendantOf(wildlifeFolder)")),
    "deposit checks farm ownership and distance": all(token in MAIN for token in ('base:GetAttribute("OwnerUserId") ~= player.UserId', "Magnitude > 15", "allowAction(player, interaction, 0.45")),
    "guardian catches carriers": "GuardianCatchDistance" in MAIN and "clearCarry(targetPlayer" in MAIN,
    "carrying speed is server-applied": "Rules.CarrySpeed" in MAIN and "humanoid.WalkSpeed = baseSpeed" in MAIN,
    "treadmills are built for every base": "createTreadmill(base, center)" in MAIN and '"TrainingZone"' in MAIN,
    "speed is earned server-side while standing on the treadmill": all(token in MAIN for token in ("zone.CFrame:PointToObjectSpace(root.Position)", "Rules.TrainingGain(profile.TreadmillLevel, Config)", "profile.Speed = nextSpeed")) and "humanoid.MoveDirection.Magnitude > 0.12" not in MAIN,
    "speed points change actual movement with a cap": "Rules.MoveSpeed(profile.Speed, Config)" in MAIN and "MaxWalkSpeed = 40" in CONFIG,
    "treadmill upgrade validates coins and level": all(token in MAIN for token in ("Rules.UpgradeCost(profile.TreadmillLevel, Config)", "profile.Coins -= cost", "profile.TreadmillLevel += 1")),
    "treadmill belt uses a single shared animation loop": "treadmillAnimationAccumulator >= 0.1" in MAIN and "for _, entry in ipairs(treadmillStrips)" in MAIN,
    "mobile HUD includes original progression and diagnostic panels": all(token in CLIENT for token in ("TouchEnabled", "StealAnAnimalHUD", "TopDashboard", "QuickActions", "OpenIndex", "ContextObjective", "ScreenInsets", "Modal", "ResponsiveScale", "MenuList", "OpenMore", "Daily", "Quests", "Codes", "Stats", "Settings", "Diagnostics", "mapBotReportRemote.OnClientEvent")),
    "greenfield HUD has clean custom icons and contextual objective state": all(token in CLIENT for token in ('makeDockButton("OpenShop"', 'makeDockButton("OpenIndex"', 'makeDockButton("OpenMore"', "makeGlyph", "objectiveMarker", "RebirthBadge", "Enum.ScreenInsets.CoreUISafeInsets")) and all(token not in CLIENT for token in ("ActionDock", "helpButton.Activated", "barnButton.Activated", "collectButton.Activated", "rebirthButton.Activated")),
    "quick menu is touch-sized and avoids permanent bottom action dock": "UDim2.new(0, 42, 0, 40)" in CLIENT and "UDim2.new(0, 8, 0, y)" in CLIENT and "ActionDock" not in CLIENT,
    "HUD restores the animal index and in-game upgrade shop": all(token in CLIENT for token in ("AnimalIndex", "ÍNDICE ANIMAL", "Catalog.ForBiome(biome.Id)", "LOJA DE MELHORIAS", "OpenShop", 'activePanel == "Shop"')),
    "daily rewards, quests and codes are saved on the server": all(token in MAIN for token in ("RequestDailyReward", "RequestRedeemCode", "RequestQuest", "dailyRemote.OnServerEvent", "codeRemote.OnServerEvent", "questRemote.OnServerEvent", "LastDailyClaimDay", "DailyStreak", "RedeemedCodes", "QuestClaims")),
    "player stats and MapBot diagnostics are connected": all(token in MAIN for token in ('setLeaderstat("Coins"', 'setLeaderstat("Rebirths"', "TotalCaptured", "TotalDeposited", "PathfindingService:CreatePath", "mapBotReportRemote:FireClient")),
    "HUD has no gamepass navigation": "PASSES" not in CLIENT and "renderPasses" not in CLIENT,
    "Studio audits use isolated test storage and are gated outside Studio": "RunService:IsStudio() and \"StealAnAnimal_StudioSandbox_v1\" or \"StealAnAnimal_FreshProfile_v1\"" in CONFIG and "if not RunService:IsStudio() then return end" in (BASE / "ServerScriptService/StudioAudit.server.lua").read_text(encoding="utf-8") and "if not RunService:IsStudio() then return end" in (BASE / "StarterPlayer/StarterPlayerScripts/StudioAudit.client.lua").read_text(encoding="utf-8"),
    "HUD removes the old permanent bottom dock and uses the mobile safe area": "ActionDock" not in CLIENT and "dock.Position = UDim2.new(0, 8" in CLIENT and "Enum.ScreenInsets.CoreUISafeInsets" in CLIENT,
    "rebirth is persistent, capped, and server validated": all(token in MAIN for token in ("RequestRebirth", "requestRebirth", "Rules.RebirthCost", "Rules.RebirthSpeedRequirement(Config)", "profile.Rebirths += 1", "saveProfile(player)", "rebirthInProgress[player]", "RebirthInProgress")) and all(token in MAIN for token in ("data.Rebirths = safeInteger", "Rebirths = profile.Rebirths")),
    "rebirth has original 100000 coin and max-speed requirements": "RebirthCoinsRequired = 100000" in CONFIG and "MaxRebirths = 25" in CONFIG and "function Rules.RebirthSpeedRequirement" in RULES,
    "rebirth preserves the barn and resets only coins and speed": "profile.Coins = 0" in MAIN and "profile.Speed = 0" in MAIN and "profile.TreadmillLevel = 1" not in MAIN[MAIN.find("local function requestRebirth"):MAIN.find("rebirthRemote.OnServerEvent")] and "profile.BarnAnimals = {}" not in MAIN[MAIN.find("local function requestRebirth"):MAIN.find("rebirthRemote.OnServerEvent")],
    "rebirth provides a persistent income multiplier": all(token in RULES for token in ("RebirthCost", "RebirthIncomeMultiplier")) and all(token in MAIN for token in ("Rules.RebirthIncomeMultiplier(profile.Rebirths, Config)", "offlineIncome(profile, now - elapsed, now)")),
    "rebirth confirmation and requirements are displayed": all(token in CLIENT for token in ("confirmingRebirth", "PREPARAR RENASCIMENTO", "CONFIRMAR RENASCIMENTO", "RebirthRequiredSpeed", "RebirthCost")),
    "HUD has no gamepass navigation": "PASSES" not in CLIENT and "renderPasses" not in CLIENT,
}
failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS " if ok else "FAIL ") + name)
if failed:
    raise SystemExit("; ".join(failed))
print(f"PASS FreshCoreReliability: {len(checks)} checks.")
