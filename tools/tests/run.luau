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
    MaxTreadmillLevel = 10,
    BaseTrainingGain = 2,
    TreadmillGainMultiplier = 1.5,
    MaxSpeedPoints = 1000000,
    BaseWalkSpeed = 16,
    MaxWalkSpeed = 40,
    SpeedPerPointFactor = 0.35,
    UpgradeBaseCost = 80,
    UpgradeCostGrowth = 1.65,
    RebirthCoinsRequired = 100000,
    RebirthIncomeBonus = 0.1,
    MaxRebirths = 25,
    CoinsLimit = 2000000000,
}

equal(Rules.StageForAge(0, config).Name, "Baby", "new animal starts as a baby")
equal(Rules.StageForAge(119, config).Name, "Baby", "baby stage duration")
equal(Rules.StageForAge(120, config).Name, "Child", "baby evolves to child")
equal(Rules.StageForAge(300, config).Name, "Teen", "child evolves to teen")
equal(Rules.StageForAge(540, config).Name, "Adult", "teen evolves to adult")
equal(Rules.StageForAge(0 / 0, config).Name, "Baby", "invalid ages default safely")
near(Rules.StageMultiplier(1, config), 1, 0.00001, "baby income multiplier")
near(Rules.StageMultiplier(2, config), 1.5, 0.00001, "child income grows by 50 percent")
near(Rules.StageMultiplier(3, config), 2.25, 0.00001, "teen income grows cumulatively")
near(Rules.StageMultiplier(4, config), 3.375, 0.00001, "adult income grows cumulatively")
equal(Rules.StageMultiplier(0 / 0, config), 1, "invalid stage index defaults safely")
equal(Rules.AnimalIncome(10, 1, config), 10, "baby income")
equal(Rules.AnimalIncome(10, 2, config), 15, "child income")
equal(Rules.AnimalIncome(10, 3, config), 22, "teen income floors fractional coins")
equal(Rules.AnimalIncome(-10, 2, config), 0, "invalid income is rejected")
equal(Rules.AnimalIncome(math.huge, 2, config), 0, "infinite income is rejected")
near(Rules.CarrySpeed(20, 10, config), 18.8, 0.0001, "carrying slows movement")
equal(Rules.CarrySpeed(20, -1, config), nil, "negative weight rejected")
equal(Rules.CarrySpeed(20, 0 / 0, config), nil, "NaN weight rejected")
equal(Rules.UpgradeCost(1, config), 80, "first treadmill upgrade cost")
equal(Rules.UpgradeCost(2, config), 132, "second treadmill upgrade cost")
equal(Rules.UpgradeCost(10, config), nil, "maximum treadmill cannot be upgraded")
equal(Rules.UpgradeCost(0, config), nil, "invalid treadmill level cannot be upgraded")
equal(Rules.UpgradeCost(0 / 0, config), nil, "NaN treadmill levels cannot be upgraded")
equal(Rules.RebirthCost(0, config), 100000, "rebirth requires 100000 coins")
equal(Rules.RebirthCost(24, config), 100000, "rebirth uses the configured fixed coin requirement")
equal(Rules.RebirthCost(25, config), nil, "rebirth maximum is enforced")
equal(Rules.RebirthCost(-1, config), nil, "negative rebirth count is rejected")
equal(Rules.RebirthSpeedRequirement(config), 4703, "rebirth requires the speed points needed for maximum movement speed")
near(Rules.RebirthIncomeMultiplier(0, config), 1, 0.0001, "no rebirth starts at 1x income")
near(Rules.RebirthIncomeMultiplier(1, config), 1.1, 0.0001, "first rebirth adds 10 percent income")
near(Rules.RebirthIncomeMultiplier(25, config), 3.5, 0.0001, "maximum rebirth bonus is capped at 3.5x")
near(Rules.RebirthIncomeMultiplier(999, config), 3.5, 0.0001, "invalid rebirth counts clamp to the configured maximum")
equal(Rules.TrainingGain(1, config), 2, "basic treadmill adds two speed points each second")
equal(Rules.TrainingGain(2, config), 3, "level two increases training gain")
equal(Rules.TrainingGain(10, config), 76, "maximum treadmill gain is bounded and deterministic")
near(Rules.MoveSpeed(0, config), 16, 0.0001, "untrained character starts at normal walk speed")
near(Rules.MoveSpeed(100, config), 19.5, 0.0001, "trained speed affects character movement")
equal(Rules.MoveSpeed(1000000, config), 40, "movement speed obeys the server-side cap")

print("PASS " .. tostring(checks) .. " fresh gameplay rule assertions")
