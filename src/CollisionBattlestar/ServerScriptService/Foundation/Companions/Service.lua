--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local FriendRules = require(Shared:WaitForChild("FriendRules"))
local CompanionDefinitions = require(Shared:WaitForChild("CompanionDefinitions"))
local Factory = require(script.Parent:WaitForChild("Factory"))
local Brain = require(script.Parent:WaitForChild("Brain"))
local Resolver = require(script.Parent:WaitForChild("AvatarResolver"))

local Service = {}
Service.__index = Service

function Service.new()
    return setmetatable({
        friends = nil,
        playerState = nil,
        resolver = Resolver.new(),
        echoes = {},
        remote = nil,
        loopConnection = nil,
    }, Service)
end

function Service:Init(registry, remotes)
    self.friends = registry:Get("Friends")
    self.playerState = registry:Get("PlayerState")
    self.remote = remotes.Companion

    self.remote.OnServerEvent:Connect(function(player: Player, action, friendUserId, classId)
        if action == "List" then
            self:SendFriends(player)
        elseif action == "Summon" then
            if typeof(friendUserId) == "number" and typeof(classId) == "string" then
                self:Summon(player, friendUserId, classId)
            end
        elseif action == "Dismiss" then
            self:Despawn(player, "Manual")
        end
    end)

    Players.PlayerAdded:Connect(function(player)
        self:DisableRepresentedFriend(player.UserId)
    end)
    Players.PlayerRemoving:Connect(function(player)
        self:Despawn(player, "OwnerLeft")
        self:DisableRepresentedFriend(player.UserId)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self:DisableRepresentedFriend(player.UserId)
    end

    local elapsed = 0
    self.loopConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 0.1 then return end
        elapsed = 0
        local now = os.clock()
        for owner, brain in pairs(self.echoes) do
            if not brain:Update(now) then
                self:Despawn(owner, "Invalid")
            end
        end
    end)
end

function Service:SendFriends(player: Player)
    local result = {}
    for _, friend in ipairs(self.friends:ResolveFriends(player)) do
        table.insert(result, {
            UserId = friend.UserId,
            Username = friend.Username,
            DisplayName = friend.DisplayName,
            Online = Players:GetPlayerByUserId(friend.UserId) ~= nil,
        })
    end
    table.sort(result, function(a,b) return a.DisplayName < b.DisplayName end)
    self.remote:FireClient(player, "Friends", result)
end

function Service:Summon(player: Player, friendUserId: number, classId: string): boolean
    if not FriendRules.classIsValid(classId) then return false end
    if not self.friends:IsFriend(player, friendUserId) then
        self.remote:FireClient(player, "Failed", "Friend verification failed.")
        return false
    end
    if Players:GetPlayerByUserId(friendUserId) then
        self.remote:FireClient(player, "Failed", "That friend is already in this server.")
        return false
    end

    local equipped = player:GetAttribute("EquippedEcho") or "None"
    local expectedItem = "Echo_" .. classId
    if equipped ~= expectedItem then
        self.remote:FireClient(player, "Failed", "Equip " .. expectedItem .. " in the Shop first.")
        return false
    end

    self:Despawn(player, "Resummon")
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return false end

    local avatarModel, source = self.resolver:Resolve(friendUserId, classId)
    local spawn = root.CFrame * CFrame.new(-5, 0, 4)
    local model = Factory.Create(friendUserId, classId, avatarModel, spawn)
    local brain = Brain.new(model, player, classId)
    self.echoes[player] = brain
    self.remote:FireClient(player, "Summoned", friendUserId, classId, source)
    return true
end

function Service:Despawn(player: Player, reason: string)
    local brain = self.echoes[player]
    if not brain then return end
    if brain.model and brain.model.Parent then brain.model:Destroy() end
    self.echoes[player] = nil
    if self.remote and player.Parent then
        self.remote:FireClient(player, "Dismissed", reason)
    end
end

function Service:DisableRepresentedFriend(friendUserId: number)
    for owner, brain in pairs(self.echoes) do
        if brain.model and brain.model:GetAttribute("FriendUserId") == friendUserId then
            self:Despawn(owner, "FriendJoined")
        end
    end
end

return Service
