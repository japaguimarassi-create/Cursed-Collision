from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT / path).read_text(encoding="utf-8")

shell = read("src/RoubeUmAnimal/ServerScriptService/CoreShell.server.lua")
main = read("src/RoubeUmAnimal/ServerScriptService/Main.server.lua")
kernel = read("src/RoubeUmAnimal/ServerScriptService/Services/CoreKernel.lua")
world = read("src/RoubeUmAnimal/ServerScriptService/Services/WorldBuilder.lua")
probe = read("src/RoubeUmAnimal/ServerScriptService/Services/MapProbe.lua")
brain = read("src/RoubeUmAnimal/ServerScriptService/Services/AnimalBrain.lua")
guardian = read("src/RoubeUmAnimal/ServerScriptService/Services/GuardianService.lua")
boot = read("src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/BootHUD.client.lua")
client = read("src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua")

checks = [
    ("CoreShell has no gameplay ModuleScript dependencies", "require(" not in shell),
    ("CoreShell creates fallback ground and spawn", "FallbackGround" in shell and "WorldSpawn" in shell),
    ("CoreShell creates all game remotes before gameplay loading", all(name in shell for name in (
        "Notify", "RequestUpgrade", "RequestStackableProduct",
        "PromptStackableProduct", "RequestRebirth", "RequestDailyReward", "RequestRedeemCode",
        "RequestQuest", "RequestCollectBarnIncome"
    ))),
    ("CoreShell receives bounded client diagnostics", "lastProbeAt" in shell and "ClientProbeReport" in shell and "viewportWidth" in shell),
    ("client diagnostic payload excludes personal identity", "playerName = string.sub(player.Name" not in shell and "userId = player.UserId" not in shell),
    ("CoreShell watchdog restores fallback and remotes", "task.wait(5)" in shell and "Active map root disappeared" in shell),
    ("Main delegates to a small CoreKernel entry point", "CoreKernel" in main and "require(Services:WaitForChild(\"ProfileService\"))" not in main),
    ("CoreKernel isolates module loads and startup", "pcall(require, module)" in kernel and "safeCall" in kernel and "ServiceStatusJson" in kernel),
    ("Kernel retains fallback when map build is not ready", "safe fallback retained" in kernel and "MapReady" in kernel),
    ("world is built into a staging root", 'folder(workspace, "StealAnAnimal_Staging")' in world),
    ("world is activated only after farm/biome/animal/guardian validation", "guardianCount == #guardians" in world and 'root.Name = "StealAnAnimal"' in world),
    ("animal home metadata exists for bounded roaming", 'SetAttribute("HomePosition"' in world and 'SetAttribute("HomeRadius"' in world),
    ("MapProbe reports active/staging map and missing remotes", all(token in probe for token in ("activeRoot", "stagingRoot", "missingRemotes", "CollectServerReport"))),
    ("MapProbe uses a diagnostic virtual player for biome traversal", all(token in probe for token in ("StartVirtualPlayer", "CoreVirtualPlayer", "PathfindingService", "virtualPlayerCount", "startAndReturn"))),
    ("virtual player never claims to be a real Roblox Player", "CountsAsRealPlayer" in probe and "countsAsPlayer = false" in probe and 'Instance.new("Player")' not in probe),
    ("AnimalBrain supports bounded wildlife and guardian behavior", all(token in brain for token in ("StartWildlife", "StartGuardians", "Flee", "Wander", "Chase", "Patrol"))),
    ("AnimalBrain registry prevents duplicate wildlife loops", "wildlifeRegistry" in brain and "ChildAdded:Connect(attach)" in brain),
    ("GuardianService delegates to AnimalBrain", "AnimalBrain.StartGuardians" in guardian),
    ("Boot HUD exists independently of gameplay remotes", "StealAnAnimalBootstrapHUD" in boot and 'WaitForChild("RoubeAnimalRemotes")' not in boot),
    ("Boot HUD reports client-observed status", "ClientProbeReport" in boot and "mainHudReady" in boot and "viewportHeight" in boot),
    ("main HUD completion flag is set after UI creation", 'gui:SetAttribute("CoreBootstrapComplete", true)' in client and 'sendClientProbe("HudReady")' in client),
    ("MapBot report is available inside the game HUD", "Diagnostics = renderDiagnostics" in client and "CORE HEALTH & MAPBOT" in client and "InvokeServer" in client),
    ("client reacquires the active map after fallback is replaced", 'workspace:FindFirstChild("StealAnAnimal")' in client and 'worldState == "Degraded"' in client),
]
failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("PASS " if ok else "FAIL ") + name)
if failed:
    raise SystemExit(f"{len(failed)} core reliability checks failed: " + "; ".join(failed))
print(f"PASS CoreReliability: {len(checks)} assertions.")
