--!strict

local suites = {
    require("./PhaseASharedSpec"),
    require("./PhaseBDataSchemaSpec"),
    require("./PhaseBPersistenceRulesSpec"),
    require("./PhaseBProgressionSpec"),
    require("./PhaseBCompanionRulesSpec"),
    require("./PhaseBSkinRulesSpec"),
    require("./PhaseBShopRulesSpec"),
    require("./PhaseBCommerceSpec"),
    require("./PhaseBPvPRulesSpec"),
    require("./PhaseBMissionRulesSpec"),
    require("./PhaseBContentRulesSpec"),
    require("./PhaseCSystemsSpec"),
}

for index, suite in ipairs(suites) do
    local ok, err = pcall(suite)
    if not ok then
        error(("Phase B rules suite %d failed: %s"):format(index, tostring(err)))
    end
end

print(("PASS Phase B rules: %d suites"):format(#suites))
