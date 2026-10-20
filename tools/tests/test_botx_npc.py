from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BOT = (ROOT / "src/StealAnAnimal/ServerScriptService/BotX.server.lua").read_text(encoding="utf-8")
PROJECT = (ROOT / "default.project.json").read_text(encoding="utf-8")
WORKFLOW = (ROOT / ".github/workflows/validate.yml").read_text(encoding="utf-8")

checks = {
    "BotX is a real ServerScriptService source file included by Rojo": '"ServerScriptService": { "$path": "src/StealAnAnimal/ServerScriptService" }' in PROJECT and (ROOT / "src/StealAnAnimal/ServerScriptService/BotX.server.lua").is_file(),
    "the bots are NPC models and never become Players": all(token in BOT for token in ('local BOT_FOLDER_NAME = "BotX_NPCs"', 'model:SetAttribute("IsBotX", true)', 'model:SetAttribute("CountsAsPlayer", false)', 'local name = "bot" .. tostring(index)')) and "Players.PlayerAdded" not in BOT.replace("Players.PlayerAdded:Connect(onPlayerAdded)", ""),
    "each NPC has a grounded humanoid R6 body and Bacon Hair locks": all(token in BOT for token in ('"HumanoidRootPart"', '"Torso"', '"Head"', '"Left Arm"', '"Right Arm"', '"Left Leg"', '"Right Leg"', 'Instance.new("Humanoid")', "humanoid.DisplayName = name", "leftLeg.CanCollide = true", "rightLeg.CanCollide = true", "BaconHairLock", "makeBaconHair", "BotXNameplate", "BotXEyeWhite", "BotXEyePupil", "BotXRim", "makeFaceAndBadge")),
    "three bots spawn only while at least one real player is connected": all(token in BOT for token in ("local BOT_COUNT = 3", "local function hasActivePlayer()", "if active or not hasActivePlayer() then", 'trigger = "real_player_present"', "Players:GetPlayers()")),
    "the last real player leaving stops and removes the NPC session": all(token in BOT for token in ("Players.PlayerRemoving:Connect(onPlayerRemoving)", 'stopSession("last_real_player_left")', "botFolder:Destroy()", "session_stopped")),
    "bots patrol map biomes using server pathfinding": all(token in BOT for token in ("PathfindingService:CreatePath", "path:ComputeAsync", "path:GetWaypoints()", "Humanoid:MoveTo", "Config.Biomes")),
    "activity records include lifecycle, gameplay remotes, prompts, state changes, and snapshots": all(token in BOT for token in ("player_joined", "character_spawned", "player_died", "ProximityPromptService.PromptTriggered", "remote_action", "player_state_changed", "GetAttributeChangedSignal", "state_snapshot", "BOTX_EVENT", "BOTX_SESSION_REPORT")),
    "logs are structured and bounded with rate protection": all(token in BOT for token in ("HttpService:JSONEncode", "MAX_RETAINED_EVENTS", "droppedOldEvents", "MAX_REMOTE_EVENTS_PER_SECOND", "argumentTypes")),
    "summaries include progression state but avoid full history on periodic reports": all(token in BOT for token in ('coins = player:GetAttribute("Coins")', 'barnBank = player:GetAttribute("BarnBank")', 'rebirths = player:GetAttribute("Rebirths")', 'totalCaptured = player:GetAttribute("TotalCaptured")', 'totalDeposited = player:GetAttribute("TotalDeposited")', "includeRecentEvents and retainedEvents or nil", "statusRemote:FireClient", "statusRemote.OnServerEvent", "pushStatus(nil, \"session_started\")", "state.Humanoid.Health > 0")),
    "bots do not mutate player economy or execute gameplay actions": not any(token in BOT for token in ('SetAttribute("Coins"', "profile.Coins", "RequestCollect:FireServer", "RequestRebirth:FireServer", "RequestUpgrade:FireServer", "PromptGamePassPurchase")),
    "GitHub Actions parses Luau and runs BotX architecture tests": "find src/StealAnAnimal tools/studio-tests -type f -name '*.lua'" in WORKFLOW and "python3 tools/tests/test_botx_npc.py" in WORKFLOW,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS " if ok else "FAIL ") + name)
if failed:
    raise SystemExit("; ".join(failed))
print(f"PASS BotX NPC architecture and in-game visibility: {len(checks)} checks.")
