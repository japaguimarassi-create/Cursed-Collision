--!strict

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Rules = require(Shared:WaitForChild("SecurityRules"))

local Service = {}
Service.__index = Service

function Service.new()
    return setmetatable({strikes = {}}, Service)
end

function Service:ValidateAction(player: Player, action: string): boolean
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local alive = humanoid ~= nil and humanoid.Health > 0
    local zone = player:GetAttribute("Zone") or "PvE"
    local ready = player:GetAttribute("DataReady") == true
    if Rules.validRequest(action, ready, alive, zone) then
        return true
    end
    self.strikes[player] = (self.strikes[player] or 0) + 1
    return false
end

function Service:GetStrikeCount(player: Player): number
    return self.strikes[player] or 0
end

function Service:Start()
    Players.PlayerRemoving:Connect(function(player)
        self.strikes[player] = nil
    end)
end

return Service