from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "src/StealAnAnimal"
MAIN = (BASE / "ServerScriptService/Main.server.lua").read_text(encoding="utf-8")
CLIENT = (BASE / "StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")
CONFIG = (BASE / "ReplicatedStorage/Shared/Config.lua").read_text(encoding="utf-8")

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
    "speed is earned on the server while moving on the treadmill": all(token in MAIN for token in ("humanoid.MoveDirection.Magnitude > 0.12", "Rules.TrainingGain(profile.TreadmillLevel, Config)", "profile.Speed = nextSpeed")),
    "speed points change actual movement with a cap": "Rules.MoveSpeed(profile.Speed, Config)" in MAIN and "MaxWalkSpeed = 40" in CONFIG,
    "treadmill upgrade validates coins and level": all(token in MAIN for token in ("Rules.UpgradeCost(profile.TreadmillLevel, Config)", "profile.Coins -= cost", "profile.TreadmillLevel += 1")),
    "treadmill belt uses a single shared animation loop": "treadmillAnimationAccumulator >= 0.1" in MAIN and "for _, entry in ipairs(treadmillStrips)" in MAIN,
    "client HUD is responsive": "TouchEnabled" in CLIENT and "StealAnAnimalHUD" in CLIENT,
    "HUD has no gamepass navigation": "PASSES" not in CLIENT and "renderPasses" not in CLIENT,
}
failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS " if ok else "FAIL ") + name)
if failed:
    raise SystemExit("; ".join(failed))
print(f"PASS FreshCoreReliability: {len(checks)} checks.")
