from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFIG = (ROOT / "src/StealAnAnimal/ReplicatedStorage/Shared/Config.lua").read_text(encoding="utf-8")
SERVER = (ROOT / "src/StealAnAnimal/ServerScriptService/StudioAudit.server.lua").read_text(encoding="utf-8")
CLIENT = (ROOT / "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/StudioAudit.client.lua").read_text(encoding="utf-8")
HUD = (ROOT / "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")
PLUGIN = (ROOT / "tools/studio-tests/StealAnAnimalAudit.plugin.lua").read_text(encoding="utf-8")
DOCS = (ROOT / "docs/STUDIO_AUTOMATED_AUDIT.md").read_text(encoding="utf-8")
SIMULATOR = (ROOT / "tools/simulate_studio_run.py").read_text(encoding="utf-8")

checks = {
    "Studio uses a separate DataStore name": 'RunService:IsStudio() and "StealAnAnimal_StudioSandbox_v1" or "StealAnAnimal_FreshProfile_v1"' in CONFIG,
    "server QA bot is disabled outside Studio and requires explicit opt-in": 'if not RunService:IsStudio() then return end' in SERVER and 'Workspace:GetAttribute("EnableStealAnimalAudit") ~= true then return end' in SERVER,
    "client QA bot is disabled outside Studio and requires explicit opt-in": 'if not RunService:IsStudio() then return end' in CLIENT and 'Workspace:GetAttribute("EnableStealAnimalAudit") ~= true then return end' in CLIENT,
    "plugin launches only two Studio simulated clients": 'StudioTestService:ExecuteMultiplayerTestAsync(2, "StealAnAnimalAudit-v1")' in PLUGIN,
    "server emits a structured report and ends the Studio test": 'HttpService:JSONEncode(summary)' in SERVER and 'StudioTestService:EndTest(encoded)' in SERVER and '[STEAL_ANIMAL_AUDIT_REPORT]' in SERVER,
    "client reports viewport, touch state, and UI checks": all(token in CLIENT for token in ("touchEnabled = UserInputService.TouchEnabled", "viewport = {", "ContextObjective", "QuickActions", "CreateVirtualInput", 'reportRemote:FireServer(report)')),
    "server checks the world, farms, guardians, remotes, and profiles": all(token in SERVER for token in ("StealAnAnimalRuntimeWorld", "PlayerFarms", "GuardianParent_", "StealAnimalRemotes", "ProfileLoaded", "DepositPrompt", "CollectPrompt")),
    "audit avoids economy-changing button actions": all(token not in CLIENT for token in ("collectRemote:FireServer()", "rebirthRemote:FireServer()", "upgradeRemote:FireServer()")),
    "plugin does not call external endpoints": all(token not in PLUGIN for token in ("RequestAsync(", "GetAsync(", "PostAsync(", "HttpGet(")),
    "instructions document the supported Studio test flow": all(token in DOCS for token in ("StudioTestService", "VirtualInput", "StudioSandbox", "Output", "API Services")),
    "CI simulator identifies itself as a simulation, not a real Studio run": '"studioRuntimeExecuted": False' in SIMULATOR and '"source_and_layout_simulation"' in SIMULATOR and "This is a deterministic source-level simulation" in SIMULATOR,
    "CI simulator creates full JSON and Markdown reports": all(token in SIMULATOR for token in ("studio-run-simulation.json", "studio-run-simulation.md", '"layoutProfiles"', '"sourceSha256"', '"compiledPlace"')),
    "CI simulator models phone, landscape, tablet, and desktop sizes": all(token in SIMULATOR for token in ("Phone small portrait", "Android portrait", "Large phone portrait", "Phone landscape", "Tablet landscape", "Desktop window")),
    "Desktop and mobile shortcuts share the objective-safe vertical offset": "dock.Position = UDim2.new(0, 8, 0, 88)" in HUD and "objectiveDoesNotOverlapQuickActions" in SIMULATOR and "local y = touchDevice and 110 or 56" not in HUD,
    "CI simulator fails the run if any modelled assertion fails": 'return 1 if failed else 0' in SIMULATOR and '"status": "FAIL" if failed else "PASS_SIMULATION_WITH_LIMITS"' in SIMULATOR,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS " if ok else "FAIL ") + name)
if failed:
    raise SystemExit("; ".join(failed))
print(f"PASS StudioAudit: {len(checks)} checks.")
