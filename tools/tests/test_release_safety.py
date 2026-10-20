from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "src/StealAnAnimal"
MAIN = (BASE / "ServerScriptService/Main.server.lua").read_text(encoding="utf-8")
PROFILE = (BASE / "ServerScriptService/Services/ProfileStore.lua").read_text(encoding="utf-8")
WORLD = (BASE / "ReplicatedStorage/Shared/WorldBuilder.lua").read_text(encoding="utf-8")
ANIMAL = (BASE / "ReplicatedStorage/Shared/AnimalFactory.lua").read_text(encoding="utf-8")
CLIENT = (BASE / "StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")
PROMPT = (BASE / "StarterPlayer/StarterPlayerScripts/InteractionPrompt.lua").read_text(encoding="utf-8")
PUBLISH = (ROOT / ".github/workflows/roblox-publish.yml").read_text(encoding="utf-8")
AUTO_PUBLISH = ROOT / ".github/workflows/publish-roblox.yml"

removal_start = MAIN.find("Players.PlayerRemoving:Connect(function(player)")
removal_end = MAIN.find("\nend)\n\nfor _, player in ipairs(Players:GetPlayers()) do", removal_start)
assert removal_start >= 0 and removal_end > removal_start, "PlayerRemoving handler is missing"
removal = MAIN[removal_start:removal_end]

shutdown_start = MAIN.find("game:BindToClose(function()")
assert shutdown_start >= 0, "Shutdown handler is missing"
shutdown = MAIN[shutdown_start:]

checks = {
    "server-side world, animal, profile, and prompt code is modularized": all(token in MAIN for token in ('require(Shared:WaitForChild("WorldBuilder"))', 'require(Shared:WaitForChild("AnimalFactory"))', 'require(Shared:WaitForChild("ProfileStore"))')) and 'require(script.Parent:WaitForChild("InteractionPrompt"))' in CLIENT,
    "farm slots are released without clearing their index first": "releaseBase(player)" in removal and "playerBases[player] = nil" not in removal,
    "duplicate PlayerAdded races cannot consume extra farms": all(token in MAIN for token in ("local playerSetupDone = {}", "if player.Parent ~= Players or playerSetupDone[player] then return end", "playerSetupDone[player] = nil")),
    "failed final saves keep the session lease until expiry": all(token in removal for token in ("local saved = saveProfile(player)", "if saved then", "releaseSession(player)", "abandonSession(player)")) and "sessionTokens[player] = nil" in PROFILE and "function abandonSession(player)" in PROFILE,
    "shutdown does not release a lease after failed persistence": all(token in shutdown for token in ("local saved = saveProfile(player)", "if saved then", "releaseSession(player)", "abandonSession(player)")),
    "world billboards do not render through walls and are bounded": "gui.AlwaysOnTop = false" in WORLD and "gui.MaxDistance = maxDistance or (compactLabel and 18 or 32)" in WORLD,
    "empty barn slots do not generate floating text labels": 'addLabel(pad, "ESPAÇO " .. tostring(slotIndex), "VAZIO"' not in WORLD and "StoredAnimals" in MAIN,
    "Swan guardian has a dedicated neck/head/feet and no duplicate generic head": all(token in ANIMAL for token in ("SwanNeck", "SwanHead", "SwanFoot", 'if spec.Id ~= "Swan" then')),
    "mobile prompt sits above the lower touch zone and ends holds globally": all(token in PROMPT for token in ("AnchorPoint = Vector2.new(0.5, 0)", "UDim2.new(0.68, 0, 0, 48)", "UserInputService.InputEnded:Connect", "InputHoldBegin()", "InputHoldEnd()")),
    "production publisher is manual and confirmation-gated": "workflow_dispatch:" in PUBLISH and "default: false" in PUBLISH and "inputs.confirm == true && inputs.confirm_studio_runtime_qa == true" in PUBLISH and "confirm_studio_runtime_qa:" in PUBLISH,
    "there is no automatic workflow that publishes after every successful CI run": not AUTO_PUBLISH.exists() and "workflow_run:" not in PUBLISH,
    "production destination is configured rather than hardcoded": "STEAL_ANIMAL_UNIVERSE_ID" in PUBLISH and "STEAL_ANIMAL_PLACE_ID" in PUBLISH and "15338267657" not in PUBLISH and "5290480963" not in PUBLISH,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS " if ok else "FAIL ") + name)
if failed:
    raise SystemExit("; ".join(failed))
print(f"PASS ReleaseSafety: {len(checks)} checks.")
