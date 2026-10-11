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
    MaxStrength = 200,
    Upgrades = {
        SpeedBaseCost = 75,
        SpeedCostGrowth = 1.12,
        StrengthBaseCost = 100,
        StrengthCostGrowth = 1.16,
        StrengthCostStart = 10,
        StrengthCostStep = 5,
    },
}

equal(Rules.IsFinite(0), true, "zero is finite")
equal(Rules.IsFinite(math.huge), false, "infinity rejected")
equal(Rules.IsFinite(0 / 0), false, "NaN rejected")
equal(Rules.Integer(4.9, 0, 10, 0), 4, "integer floors")
equal(Rules.Integer(0 / 0, 0, 10, 7), 7, "invalid integer fallback")
equal(Rules.Integer(500, 0, 10, 0), 10, "integer upper bound")
equal(Rules.CanCapture(10, 10, false), true, "strength requirement met")
equal(Rules.CanCapture(9, 10, false), false, "strength requirement blocks capture")
equal(Rules.CanCapture(100, 10, true), false, "cannot carry two animals")

local speed, penalty = Rules.CarrySpeed(20, 2, 10, 0.45, 0.28, 5)
near(speed, 20, 0.0001, "light carry has no penalty")
equal(penalty, 0, "light carry penalty")
local heavySpeed, heavyPenalty = Rules.CarrySpeed(20, 20, 10, 0.45, 0.28, 5)
near(heavySpeed, 20 * (1 - ((2 - 0.45) * 0.28)), 0.0001, "heavy carry penalty")
near(heavyPenalty, (2 - 0.45) * 0.28, 0.0001, "heavy carry penalty value")
equal(Rules.CarrySpeed(20, 55, 1, 0.45, 0.28, 5), 5, "minimum carry speed")
equal(Rules.CarrySpeed(20, -1, 10, 0.45, 0.28, 5), nil, "invalid weight rejected")

equal(Rules.SalePrice(25, 1, false, config.CoinsLimit), 25, "common sale value")
equal(Rules.SalePrice(6000, 20, false, config.CoinsLimit), 120000, "mythic sale value")
equal(Rules.SalePrice(6000, 20, true, config.CoinsLimit), 240000, "double coins applied")
equal(Rules.SalePrice(6000, 20, true, 200000), 200000, "sale respects coin cap")
equal(Rules.SalePrice(100, nil, false, config.CoinsLimit), nil, "invalid rarity rejected")

equal(Rules.UpgradePrice("Speed", { Speed = 0 }, config), 75, "first speed upgrade")
equal(Rules.UpgradePrice("Speed", { Speed = 1 }, config), 84, "speed growth")
equal(Rules.UpgradePrice("Strength", { Strength = 10 }, config), 100, "first strength upgrade")
equal(Rules.UpgradePrice("Strength", { Strength = 15 }, config), 116, "strength growth")
equal(Rules.UpgradePrice("Speed", { Speed = 79 }, config) < 700000, true, "top speed upgrade remains attainable")
equal(Rules.UpgradePrice("Strength", { Strength = 195 }, config) < 120000, true, "top strength upgrade remains attainable")
equal(Rules.UpgradePrice("Speed", { Speed = 80 }, config), nil, "max speed cannot be bought")
equal(Rules.UpgradePrice("Strength", { Strength = 200 }, config), nil, "max strength cannot be bought")
equal(Rules.UpgradePrice("Exploit", { Speed = 0 }, config), nil, "unknown upgrade rejected")
equal(Rules.UpgradePrice("Speed", { Speed = 0 }, {}), nil, "incomplete config rejected")

print("PASS " .. tostring(assertions) .. " gameplay rule assertions")
