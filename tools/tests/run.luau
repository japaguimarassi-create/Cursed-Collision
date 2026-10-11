local Rules = require("../../src/RoubeUmAnimal/ReplicatedStorage/Shared/GameplayRules")

local assertions = 0

local function equal(actual, expected, name)
    assertions += 1
    if actual ~= expected then
        error(name .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function near(actual, expected, tolerance, name)
    assertions += 1
    if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
        error(name .. ": expected approximately " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local config = {
    CoinsLimit = 2000000000,
    MaxSpeedLevel = 80,
    Upgrades = { SpeedBaseCost = 75, SpeedCostGrowth = 1.12 },
}

equal(Rules.IsFinite(0), true, "zero is finite")
equal(Rules.IsFinite(math.huge), false, "infinity rejected")
equal(Rules.IsFinite(0 / 0), false, "NaN rejected")
equal(Rules.Integer(4.9, 0, 10, 0), 4, "integer floors")
equal(Rules.Integer(0 / 0, 0, 10, 7), 7, "invalid integer fallback")
equal(Rules.Integer(500, 0, 10, 0), 10, "integer upper bound")
equal(Rules.CanCapture(false), true, "can capture with empty hands")
equal(Rules.CanCapture(true), false, "cannot carry two animals")

local speed, penalty = Rules.CarrySpeed(20, 2, 8, 0.008, 0.55, 7)
near(speed, 20, 0.0001, "light animal does not slow player")
equal(penalty, 0, "light animal has no penalty")
local heavySpeed, heavyPenalty = Rules.CarrySpeed(20, 55, 8, 0.008, 0.55, 7)
near(heavySpeed, 20 * (1 - ((55 - 8) * 0.008)), 0.0001, "heavy animal slows player")
near(heavyPenalty, (55 - 8) * 0.008, 0.0001, "heavy carry penalty value")
equal(Rules.CarrySpeed(20, 200, 8, 0.008, 0.55, 7), 9, "penalty is capped")
equal(Rules.CarrySpeed(20, -1, 8, 0.008, 0.55, 7), nil, "invalid weight rejected")

equal(Rules.UpgradePrice("Speed", { Speed = 0 }, config), 75, "first speed upgrade")
equal(Rules.UpgradePrice("Speed", { Speed = 1 }, config), 84, "speed growth")
equal(Rules.UpgradePrice("Speed", { Speed = 79 }, config) < 700000, true, "top speed upgrade remains attainable")
equal(Rules.UpgradePrice("Speed", { Speed = 80 }, config), nil, "max speed cannot be bought")
equal(Rules.UpgradePrice("Strength", { Strength = 10 }, config), nil, "removed stat cannot be purchased")
equal(Rules.UpgradePrice("Exploit", { Speed = 0 }, config), nil, "unknown upgrade rejected")
equal(Rules.UpgradePrice("Speed", { Speed = 0 }, {}), nil, "incomplete config rejected")

print("PASS " .. tostring(assertions) .. " gameplay rule assertions")
