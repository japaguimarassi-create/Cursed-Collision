--!strict

local Test = require("./Test")

type Case = {
    name: string,
    run: () -> (),
}

local cases: {Case} = {
    {name = "CombatRulesSpec", run = function()
        require("./CombatRulesSpec")()
    end},
    {name = "WaveRulesSpec", run = function()
        require("./WaveRulesSpec")()
    end},
    {name = "EconomyRulesSpec", run = function()
        require("./EconomyRulesSpec")()
    end},
    {name = "SecurityRulesSpec", run = function()
        require("./SecurityRulesSpec")()
    end},
    {name = "PlayerStateSpec", run = function()
        require("./PlayerStateSpec")()
    end},
    {name = "HUDSpec", run = function()
        require("./HUDSpec")()
    end},
    {name = "HUDLayoutRulesSpec", run = function()
        require("./HUDLayoutRulesSpec")()
    end},
    {name = "HUDPlatformSpec", run = function()
        require("./HUDPlatformSpec")()
    end},
    {name = "FriendRulesSpec", run = function()
        require("./FriendRulesSpec")()
    end},
    {name = "CompanionRulesSpec", run = function()
        require("./CompanionRulesSpec")()
    end},
    {name = "EnemySkinRulesSpec", run = function()
        require("./EnemySkinRulesSpec")()
    end},
    {name = "ShopRulesSpec", run = function()
        require("./ShopRulesSpec")()
    end},
    {name = "InventoryRulesSpec", run = function()
        require("./InventoryRulesSpec")()
    end},
    {name = "ProgressionRulesSpec", run = function()
        require("./ProgressionRulesSpec")()
    end},
    {name = "AnalyticsRulesSpec", run = function()
        require("./AnalyticsRulesSpec")()
    end},
}

local passed = 0
for _, case in ipairs(cases) do
    local ok, err = pcall(case.run)
    if not ok then
        print(("FAIL %s: %s"):format(case.name, tostring(err)))
        error(("Test suite failed at %s"):format(case.name))
    end
    passed += 1
    print(("PASS %s"):format(case.name))
end

Test.equal(passed, #cases, "test count")
print(("PASS %d/%d tests"):format(passed, #cases))
