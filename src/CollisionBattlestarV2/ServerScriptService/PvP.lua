--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local PvP = {}
PvP.__index = PvP

function PvP.new(world, score, remotes)
    return setmetatable({
        world = world,
        score = score,
        remotes = remotes,
        participants = {},
        connections = {},
    }, PvP)
end

function PvP:IsParticipant(player: Player)
    return self.participants[player] == true
end

function PvP:CanAttack(attacker: Player, target: Player)
    return self:IsParticipant(attacker) and self:IsParticipant(target) and attacker ~= target
end

function PvP:Join(player: Player)
    if self:IsParticipant(player) then
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end

    self.participants[player] = true
    player:SetAttribute("CBS_PvP", true)
    root.CFrame = CFrame.new(0, 4, Constants.PVPArenaCenterZ)
    root.AssemblyLinearVelocity = Vector3.zero
    self.remotes.PvP:FireClient(player, "State", true)
end

function PvP:Leave(player: Player)
    self.participants[player] = nil
    player:SetAttribute("CBS_PvP", false)

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        root.CFrame = self.world:GetPlayerSpawn()
        root.AssemblyLinearVelocity = Vector3.zero
    end

    self.remotes.PvP:FireClient(player, "State", false)
end

function PvP:OnDeath(player: Player)
    if not self:IsParticipant(player) then
        return
    end

    local killerId = player:GetAttribute("CBS2_LastKiller")
    local killer = type(killerId) == "number" and Players:GetPlayerByUserId(killerId) or nil
    if killer and self:IsParticipant(killer) then
        self.score:PVP(killer)
    end

    player:SetAttribute("CBS2_LastKiller", nil)

    task.delay(2, function()
        if player.Parent and self:IsParticipant(player) then
            self:Leave(player)
        end
    end)
end

function PvP:Reset()
    local list = {}
    for player in pairs(self.participants) do
        list[#list + 1] = player
    end
    for _, player in ipairs(list) do
        self:Leave(player)
    end
end

function PvP:Start()
    table.insert(self.connections, self.remotes.PvP.OnServerEvent:Connect(function(player, request)
        if type(request) ~= "table" then
            return
        end
        if request.action == "Join" then
            self:Join(player)
        elseif request.action == "Leave" then
            self:Leave(player)
        end
    end))

    table.insert(self.connections, Players.PlayerRemoving:Connect(function(player)
        self.participants[player] = nil
    end))
end

function PvP:Stop()
    self:Reset()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    table.clear(self.connections)
end

function PvP:Reload()
    self:Stop()
    self:Start()
end

return PvP
