--!strict

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Rules = require(Shared:WaitForChild("EconomyRules"))

local Service = {}
Service.__index = Service

function Service.new()
    return setmetatable({players = nil, world = nil, stateRemote = nil}, Service)
end

function Service:Init(registry, remotes)
    self.players = registry:Get("PlayerState")
    self.world = registry:Get("World")
    self.stateRemote = remotes.State
    self.world:GetUpgradePrompt().Triggered:Connect(function(player)
        self:UpgradeDamage(player)
    end)
end

function Service:AddCredits(player: Player, amount: number, reason: string)
    if not player or not player.Parent or amount <= 0 then
        return
    end
    self.players:AddCredits(player, amount)
    self.stateRemote:FireClient(player, "Credits", player:GetAttribute("Credits") or 0, reason)
end

function Service:GrantEnemyReward(player: Player, tier: string)
    local stats = Constants.Enemies[tier]
    if stats then
        self:AddCredits(player, stats.Credits, "Defeat")
    end
end

function Service:GrantWaveReward(wave: number)
    local reward = Rules.waveReward(wave)
    for _, player in ipairs(Players:GetPlayers()) do
        self:AddCredits(player, reward, "Wave")
    end
end

function Service:UpgradeDamage(player: Player)
    local currentLevel = player:GetAttribute("DamageLevel") or 0
    local cost = Rules.upgradeCost(currentLevel)
    local credits = player:GetAttribute("Credits") or 0

    if not Rules.canBuy(credits, cost) then
        self.stateRemote:FireClient(player, "UpgradeFailed", cost, credits)
        return
    end

    if not self.players:SpendCredits(player, cost) then
        return
    end

    self.players:AddDamageLevel(player)
    local newLevel = player:GetAttribute("DamageLevel") or 0
    self.stateRemote:FireClient(player, "Upgrade", newLevel, Rules.upgradeCost(newLevel))
end

return Service