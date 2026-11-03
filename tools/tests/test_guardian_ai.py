from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "src/StealAnAnimal"
AI = (BASE / "ServerScriptService/Services/GuardianAI.lua").read_text(encoding="utf-8")
CONTROLLER = (BASE / "ServerScriptService/Services/GuardianController.lua").read_text(encoding="utf-8")
MAIN = (BASE / "ServerScriptService/Main.server.lua").read_text(encoding="utf-8")
CLIENT = (BASE / "StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")
WORLD = (BASE / "ReplicatedStorage/Shared/WorldBuilder.lua").read_text(encoding="utf-8")

checks = {
    "every guardian brain is initially dormant": all(token in AI for token in ('self.Active = false', 'Model:SetAttribute("GuardianAIActive", false)', 'Model:SetAttribute("GuardianBrainState", "Dormant")', 'Model:SetAttribute("AnimationState", "Rest")', "setDormant()")),
    "only server-confirmed theft activates the matching biome": "guardianController:OnAnimalStolen(player, spec.Biome)" in MAIN and "function self:OnAnimalStolen(player, biomeId)" in CONTROLLER and "guardian.Biome.Id == biomeId" in CONTROLLER and "function self:Activate(player)" in AI,
    "pursuit checks the player's current animal and biome": "local carry = carried[player]" in AI and "carry.Spec.Biome ~= Biome.Id" in AI,
    "AI stepping is skipped when all guardians are dormant": "if guardianController:HasActiveGuardians() then" in MAIN and "function self:HasActiveGuardians()" in CONTROLLER and "if not self.Active then" in AI,
    "carry ending pauses the corresponding guardian brain": MAIN.count("guardianController:OnCarryEnded(player)") == 2 and "function self:OnCarryEnded(player)" in CONTROLLER and "function self:Deactivate(player)" in AI,
    "caught carriers lose their animal": "ClearCarry(targetPlayer)" in AI and "Notify(targetPlayer" in AI,
    "BotX and MapBot runtime scripts and remotes are absent": not (BASE / "ServerScriptService/BotX.server.lua").exists() and not any(token in MAIN + CLIENT for token in ("BotXStatus", "RequestMapBot", "MapBotReport", "PathfindingService:CreatePath", "BOTX_SESSION_REPORT")),
    "mobile HUD has no bot or MapBot controls": not any(token in CLIENT for token in ("BotX", "MapBot", "Diagnostics", "mapBotReportRemote")),
    "map receives more geometric details per biome": "buildBiomeGeometry(biome, biomeIndex)" in WORLD and all(token in WORLD for token in ("GateFooting", "PathEdgeSegment", "FacetedOutcrop", "GateBaseRing", "LakeBridgeSpan", "ForestMonolithLintel", "WetlandsRootRib", "FrostSculptedSpire", "VolcanoBasaltRidgeFin", "OceanCoralFan", "SavannaFossilRib")),
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS " if ok else "FAIL ") + name)
if failed:
    raise SystemExit("; ".join(failed))
print(f"PASS GuardianAIArchitecture: {len(checks)} checks.")
