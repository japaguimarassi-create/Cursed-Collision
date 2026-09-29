--!strict

local Players = game:GetService("Players")
local SharedState = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlayerState"))
local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))

local Service = {}
Service.__index = Service

function Service.new()
    return setmetatable({states = {}}, Service)
end

function Service:BindPlayer(player: Player)
    local state = SharedState.new()
    SharedState.setReady(state, true)
    self.states[player] = state
    player:SetAttribute("DataReady", true)
    player:SetAttribute("Credits", 0)
    player:SetAttribute("DamageLevel", 0)
    player:SetAttribute("Zone", "PvE")
    player:SetAttribute("CombatHealth", Constants.Combat.PlayerMaxHealth)
    return state
end

function Service:Get(player: Player)
    return self.states[player]
end

function Service:AddCredits(player: Player, amount: number)
    local state = self.states[player]
    if not state then
        return
    end
    SharedState.addCredits(state, amount)
    player:SetAttribute("Credits", state.Credits)
end

function Service:SpendCredits(player: Player, amount: number): boolean
    local state = self.states[player]
    if not state or state.Credits < amount then
        return false
    end
    state.Credits -= amount
    player:SetAttribute("Credits", state.Credits)
    return true
end

function Service:AddDamageLevel(player: Player)
    local state = self.states[player]
    if not state then
        return
    end
    SharedState.addDamageLevel(state)
    player:SetAttribute("DamageLevel", state.DamageLevel)
end

function Service:GetDamage(player: Player): number
    local state = self.states[player]
    if not state then
        return 0
    end
    return state.DamageLevel * Constants.Economy.UpgradeDamagePerLevel
end

function Service:SetWave(player: Player, wave: number)
    local state = self.states[player]
    if state then
        state.Wave = wave
        player:SetAttribute("Wave", wave)
    end
end

function Service:Start()
    Players.PlayerAdded:Connect(function(player)
        self:BindPlayer(player)
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid", 10)
            if humanoid then
                humanoid.MaxHealth = Constants.Combat.PlayerMaxHealth
                humanoid.Health = humanoid.MaxHealth
                player:SetAttribute("CombatHealth", humanoid.Health)
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.states[player] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self:BindPlayer(player)
    end
end

return Service