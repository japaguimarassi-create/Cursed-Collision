--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CombatRules = require(ReplicatedStorage.Shared.CombatRules)
local DataSchema = require(ReplicatedStorage.Shared.DataSchema)
local ProgressionRules = require(ReplicatedStorage.Shared.ProgressionRules)

local PlayerState = {}
PlayerState.__index = PlayerState

type State = {
    profile: any,
    credits: number,
    powerLevel: number,
    lastAttackAt: number,
    lastDashAt: number,
    comboStep: number,
    lastComboAt: number,
    kills: number,
}

function PlayerState.new(persistenceService)
    return setmetatable({
        persistence = persistenceService,
        states = {} :: {[Player]: State},
    }, PlayerState)
end

function PlayerState:Start()
    Players.CharacterAutoLoads = false

    Players.PlayerAdded:Connect(function(player)
        task.spawn(function()
            self:AddPlayer(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.states[player] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:AddPlayer(player)
        end)
    end
end

function PlayerState:AddPlayer(player: Player)
    if self.states[player] or not player.Parent then
        return
    end

    local profile, err = self.persistence:Load(player)
    if not profile then
        warn(("Profile load failed for %s: %s"):format(player.Name, tostring(err)))
        if player.Parent then
            player:Kick("Your data could not be loaded safely. Please rejoin.")
        end
        return
    end

    if not player.Parent then
        return
    end

    local normalized = DataSchema.Sanitize(profile)

    local state: State = {
        profile = normalized,
        credits = normalized.Credits,
        powerLevel = normalized.PowerLevel,
        lastAttackAt = -math.huge,
        lastDashAt = -math.huge,
        comboStep = 0,
        lastComboAt = -math.huge,
        kills = normalized.Kills,
    }

    self.states[player] = state

    player:SetAttribute("CBS_Credits", state.credits)
    player:SetAttribute("CBS_PowerLevel", state.powerLevel)
    player:SetAttribute("CBS_Kills", state.kills)
    player:SetAttribute("CBS_PlayerStateReady", true)

    local function onCharacter(character: Model)
        self:ApplyCharacterStats(player, character)
    end

    player.CharacterAdded:Connect(onCharacter)

    if player.Character then
        onCharacter(player.Character)
    else
        local ok = pcall(function()
            player:LoadCharacter()
        end)
        if not ok and player.Parent then
            player:Kick("Character initialization failed safely.")
        end
    end
end

function PlayerState:Get(player: Player): State?
    return self.states[player]
end

function PlayerState:GetProfile(player: Player)
    local state = self.states[player]
    return state and state.profile or nil
end

function PlayerState:TryNamedUpgrade(player: Player, upgradeId: string, definition, cost: number)
    local state = self.states[player]
    if not state then
        return false, "state_unavailable"
    end

    local currentLevel = self:GetUpgradeLevel(player, upgradeId)

    if currentLevel >= definition.MaxLevel then
        return false, "max_level"
    end

    if state.credits < cost then
        return false, "insufficient_credits"
    end

    state.credits -= cost
    state.profile.Credits = state.credits
    state.profile.Upgrades[upgradeId] = currentLevel + 1

    player:SetAttribute("CBS_Credits", state.credits)
    player:SetAttribute("CBS_" .. upgradeId .. "Level", currentLevel + 1)

    if player.Character then
        self:ApplyCharacterStats(player, player.Character)
    end

    return true, currentLevel + 1
end

function PlayerState:GetUpgradeLevel(player: Player, upgradeId: string)
    local state = self.states[player]
    if not state then
        return 0
    end

    local upgrades = state.profile.Upgrades
    return upgrades[upgradeId] or 0
end

function PlayerState:ApplyCharacterStats(player: Player, character: Model)
    local state = self.states[player]
    if not state then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local healthLevel = self:GetUpgradeLevel(player, "MaxHealth")
    local speedLevel = self:GetUpgradeLevel(player, "Dash")
    local recoveryLevel = self:GetUpgradeLevel(player, "Recovery")
    local maxHealth = Config.Player.BaseHealth + (state.powerLevel - 1) * 10 + healthLevel * 15
    local speed = Config.Player.BaseWalkSpeed + (state.powerLevel - 1) * 0.75 + speedLevel * 0.3

    humanoid.MaxHealth = maxHealth
    humanoid.Health = maxHealth
    humanoid.WalkSpeed = speed

    player:SetAttribute("CBS_RecoveryLevel", recoveryLevel)
end

function PlayerState:AddCredits(player: Player, amount: number)
    local state = self.states[player]
    if not state or amount <= 0 then
        return false
    end

    local gained = math.floor(amount)
    state.credits += gained
    state.profile.Credits = state.credits
    player:SetAttribute("CBS_Credits", state.credits)
    return true
end

function PlayerState:TryUpgrade(player: Player)
    local state = self.states[player]
    if not state then
        return false, "state_unavailable"
    end

    local cost = self:GetUpgradeCost(player)
    if state.credits < cost then
        return false, "insufficient_credits"
    end

    state.credits -= cost
    state.powerLevel += 1
    state.profile.Credits = state.credits
    state.profile.PowerLevel = state.powerLevel

    player:SetAttribute("CBS_Credits", state.credits)
    player:SetAttribute("CBS_PowerLevel", state.powerLevel)

    if player.Character then
        self:ApplyCharacterStats(player, player.Character)
    end

    return true, state.powerLevel
end

function PlayerState:GetUpgradeCost(player: Player): number
    local state = self.states[player]
    if not state then
        return math.huge
    end

    return math.floor(
        Config.Economy.UpgradeBaseCost
            * Config.Economy.UpgradeCostGrowth ^ (state.powerLevel - 1)
    )
end

function PlayerState:MarkAttack(player: Player, now: number)
    local state = self.states[player]
    if not state then
        return nil
    end

    if now - state.lastAttackAt < Config.Combat.AttackCooldown then
        return nil
    end

    if now - state.lastComboAt > Config.Combat.ComboResetWindow then
        state.comboStep = CombatRules.nextCombo(
            state.comboStep,
            math.huge,
            Config.Combat.ComboResetWindow,
            Config.Combat.ComboSteps
        )
    else
        state.comboStep = CombatRules.nextCombo(
            state.comboStep,
            now - state.lastComboAt,
            Config.Combat.ComboResetWindow,
            Config.Combat.ComboSteps
        )
    end

    state.lastAttackAt = now
    state.lastComboAt = now

    return state.comboStep
end

function PlayerState:CanDash(player: Player, now: number)
    local state = self.states[player]
    if not state then
        return false
    end

    local cooldown = Config.Combat.DashCooldown * ProgressionRules.dashCooldownMultiplier(
        self:GetUpgradeLevel(player, "Dash")
    )

    if now - state.lastDashAt < cooldown then
        return false
    end

    state.lastDashAt = now
    return true
end

function PlayerState:MarkKill(player: Player)
    local state = self.states[player]
    if not state then
        return false
    end

    state.kills += 1
    state.profile.Kills = state.kills
    player:SetAttribute("CBS_Kills", state.kills)
    return true
end

function PlayerState:MarkWaveComplete(player: Player)
    local state = self.states[player]
    if not state then
        return false
    end

    state.profile.TotalWaves += 1
    return true
end

function PlayerState:GetPersistentProfile(player: Player)
    local state = self.states[player]
    if not state then
        return nil
    end

    state.profile.Credits = state.credits
    state.profile.PowerLevel = state.powerLevel
    state.profile.Kills = state.kills

    return DataSchema.Sanitize(state.profile)
end

return PlayerState
