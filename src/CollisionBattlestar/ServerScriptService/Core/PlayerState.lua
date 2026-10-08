--!strict

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local PlayerState = {}
PlayerState.__index = PlayerState

type State = {
    credits: number,
    powerLevel: number,
    lastAttackAt: number,
    lastDashAt: number,
    comboStep: number,
    lastComboAt: number,
    kills: number,
}

function PlayerState.new()
    return setmetatable({
        states = {} :: {[Player]: State},
    }, PlayerState)
end

function PlayerState:Start()
    Players.PlayerAdded:Connect(function(player)
        self:AddPlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.states[player] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self:AddPlayer(player)
    end
end

function PlayerState:AddPlayer(player: Player)
    if self.states[player] then
        return
    end

    self.states[player] = {
        credits = Config.Economy.BaseCredits,
        powerLevel = 1,
        lastAttackAt = -math.huge,
        lastDashAt = -math.huge,
        comboStep = 0,
        lastComboAt = -math.huge,
        kills = 0,
    }

    player:SetAttribute("CBS_Credits", 0)
    player:SetAttribute("CBS_PowerLevel", 1)
    player:SetAttribute("CBS_Kills", 0)
    player:SetAttribute("CBS_PlayerStateReady", true)

    player.CharacterAdded:Connect(function(character)
        self:ApplyCharacterStats(player, character)
    end)

    if player.Character then
        self:ApplyCharacterStats(player, player.Character)
    end
end

function PlayerState:Get(player: Player): State?
    return self.states[player]
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

    humanoid.MaxHealth = Config.Player.BaseHealth + (state.powerLevel - 1) * 10
    humanoid.Health = humanoid.MaxHealth
    humanoid.WalkSpeed = Config.Player.BaseWalkSpeed + (state.powerLevel - 1) * 0.75
end

function PlayerState:AddCredits(player: Player, amount: number)
    local state = self.states[player]
    if not state or amount <= 0 then
        return false
    end

    state.credits += math.floor(amount)
    player:SetAttribute("CBS_Credits", state.credits)
    return true
end

function PlayerState:GetUpgradeCost(player: Player): number
    local state = self.states[player]
    if not state then
        return math.huge
    end

    return math.floor(Config.Economy.UpgradeBaseCost * Config.Economy.UpgradeCostGrowth ^ (state.powerLevel - 1))
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

    player:SetAttribute("CBS_Credits", state.credits)
    player:SetAttribute("CBS_PowerLevel", state.powerLevel)

    if player.Character then
        self:ApplyCharacterStats(player, player.Character)
    end

    return true, state.powerLevel
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
        state.comboStep = 1
    else
        state.comboStep = (state.comboStep % Config.Combat.ComboSteps) + 1
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

    if now - state.lastDashAt < Config.Combat.DashCooldown then
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
    player:SetAttribute("CBS_Kills", state.kills)
    return true
end

return PlayerState
