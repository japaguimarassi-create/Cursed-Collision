local Rules = require("../../src/StealAnAnimal/ReplicatedStorage/Shared/GameplayRules")

local checks = 0

local function equal(actual, expected, label)
    checks += 1
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function near(actual, expected, tolerance, label)
    checks += 1
    if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local config = {
    EvolutionIncomeMultiplier = 1.5,
    EvolutionStages = {
        { Name = "Baby", AgeSeconds = 0 },
        { Name = "Child", AgeSeconds = 120 },
        { Name = "Teen", AgeSeconds = 300 },
        { Name = "Adult", AgeSeconds = 540 },
    },
    CarrySpeedMinimum = 8,
    CarryWeightPenalty = 0.006,
    CarryPenaltyCap = 0.48,
    MaxSpeedLevel = 60,
    UpgradeBaseCost = 80,
    UpgradeCostGrowth = 1.13,
}

equal(Rules.StageForAge(0, config).Name, "Baby", "new animal starts as a baby")
equal(Rules.StageForAge(119, config).Name, "Baby", "baby stage duration")
equal(Rules.StageForAge(120, config).Name, "Child", "baby evolves to child")
equal(Rules.StageForAge(300, config).Name, "Teen", "child evolves to teen")
equal(Rules.StageForAge(540, config).Name, "Adult", "teen evolves to adult")
near(Rules.StageMultiplier(1, config), 1, 0.00001, "baby income multiplier")
near(Rules.StageMultiplier(2, config), 1.5, 0.00001, "child income grows by 50 percent")
near(Rules.StageMultiplier(3, config), 2.25, 0.00001, "teen income grows cumulatively")
near(Rules.StageMultiplier(4, config), 3.375, 0.00001, "adult income grows cumulatively")
equal(Rules.AnimalIncome(10, 1, config), 10, "baby income")
equal(Rules.AnimalIncome(10, 2, config), 15, "child income")
equal(Rules.AnimalIncome(10, 3, config), 22, "teen income floors fractional coins")
equal(Rules.AnimalIncome(-10, 2, config), 0, "invalid income is rejected")
near(Rules.CarrySpeed(20, 10, config), 18.8, 0.0001, "carrying slows movement")
equal(Rules.CarrySpeed(20, -1, config), nil, "negative weight rejected")
equal(Rules.UpgradeCost(0, config), 80, "first speed upgrade cost")
equal(Rules.UpgradeCost(60, config), nil, "maximum speed cannot be upgraded")

print("PASS " .. tostring(checks) .. " fresh gameplay rule assertions")
