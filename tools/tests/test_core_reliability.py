from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "src/StealAnAnimal"
MAIN = (BASE / "ServerScriptService/Main.server.lua").read_text(encoding="utf-8")
CLIENT = (BASE / "StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")
CONFIG = (BASE / "ReplicatedStorage/Shared/Config.lua").read_text(encoding="utf-8")

checks = {
    "profiles load from DataStore": "Store:GetAsync" in MAIN,
    "profiles save atomically": "Store:UpdateAsync" in MAIN,
    "offline income is capped": "OfflineIncomeCapSeconds" in MAIN and "OfflineIncomeCapSeconds = 21600" in CONFIG,
    "autosave and shutdown save exist": "AutosaveSeconds" in MAIN and "BindToClose" in MAIN,
    "capture is server-validated": "wildRecords[model]" in MAIN and "ProximityPromptService.PromptTriggered" in MAIN,
    "deposit checks farm ownership": 'base:GetAttribute("OwnerUserId") ~= player.UserId' in MAIN,
    "guardian catches carriers": "GuardianCatchDistance" in MAIN and "clearCarry(targetPlayer" in MAIN,
    "carrying speed is server-applied": "Rules.CarrySpeed" in MAIN and "humanoid.WalkSpeed = baseSpeed" in MAIN,
    "client HUD is responsive": "TouchEnabled" in CLIENT and "StealAnAnimalHUD" in CLIENT,
    "HUD has no gamepass navigation": "PASSES" not in CLIENT and "renderPasses" not in CLIENT,
}
failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS " if ok else "FAIL ") + name)
if failed:
    raise SystemExit("; ".join(failed))
print(f"PASS FreshCoreReliability: {len(checks)} checks.")
