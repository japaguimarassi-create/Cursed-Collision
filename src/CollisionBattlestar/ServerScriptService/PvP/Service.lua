--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PvPRules = require(ReplicatedStorage.Shared.PvPRules)
local ArenaBuilder = require(script.Parent.ArenaBuilder)

local PvPService = {}
PvPService.__index = PvPService

function PvPService.new(playerState, economyService, remotes)
    return setmetatable({
        playerState = playerState,
        economyService = economyService,
        remotes = remotes,
        world = nil,
        participants = {} :: {[Player]: boolean},
        requests = {} :: {[Player]: number},
    }, PvPService)
end

function PvPService:Start()
    self.world = ArenaBuilder.Build()

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            self:WatchCharacter(player, character)
            task.defer(function()
                if self.participants[player] then
                    self:PositionPlayer(player)
                end
            end)
        end)

        if player.Character then
            self:WatchCharacter(player, player.Character)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.participants[player] = nil
        self.requests[player] = nil
    end)

    self.remotes.PvP.OnServerEvent:Connect(function(player, request)
        self:HandleRequest(player, request)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self.participants[player] = player:GetAttribute("CBS_PvP") == true
        self:WatchCharacter(player, player.Character)
    end
end

function PvPService:CanRequest(player: Player)
    local now = os.clock()
    local previous = self.requests[player] or -math.huge
    if now - previous < 0.75 then
        return false
    end
    self.requests[player] = now
    return true
end

function PvPService:HandleRequest(player: Player, request: any)
    if type(request) ~= "table" or not self:CanRequest(player) then
        return
    end

    if request.action == "Join" then
        local ok, reason = self:Join(player)
        self.remotes.PvP:FireClient(player, "Result", {
            success = ok,
            reason = reason,
            active = self.participants[player] == true,
        })
    elseif request.action == "Leave" then
        local ok, reason = self:Leave(player)
        self.remotes.PvP:FireClient(player, "Result", {
            success = ok,
            reason = reason,
            active = self.participants[player] == true,
        })
    elseif request.action == "State" then
        self.remotes.PvP:FireClient(player, "Result", {
            success = true,
            active = self.participants[player] == true,
        })
    end
end

function PvPService:GetSpawns()
    local spawns = self.world and self.world:FindFirstChild("Spawns")
    if not spawns then
        return {}
    end

    local result = {}
    for _, child in ipairs(spawns:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(result, child)
        end
    end

    table.sort(result, function(a, b)
        return a.Name < b.Name
    end)

    return result
end

function PvPService:WatchCharacter(player: Player, character: Model?)
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    humanoid.Died:Connect(function()
        if not self.participants[player] then
            return
        end

        local killerUserId = player:GetAttribute("CBS_LastPvPKillerUserId")
        if type(killerUserId) == "number" then
            local killer = Players:GetPlayerByUserId(killerUserId)
            if killer and self.participants[killer] then
                self.economyService:RewardEnemyDefeat(killer, 75)
            end
        end

        player:SetAttribute("CBS_LastPvPKillerUserId", nil)
    end)
end

function PvPService:PositionPlayer(player: Player)
    local character = player.Character
    if not character then
        return false
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return false
    end

    local spawns = self:GetSpawns()
    if #spawns == 0 then
        return false
    end

    local index = (player.UserId % #spawns) + 1
    root.CFrame = spawns[index].CFrame + Vector3.new(0, 4, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    return true
end

function PvPService:Join(player: Player)
    if not PvPRules.canJoin(self.participants[player] == true) then
        return false, "already_in_pvp"
    end

    local valid = self:PositionPlayer(player)
    if not valid then
        return false, "character_unavailable"
    end

    self.participants[player] = true
    player:SetAttribute("CBS_PvP", true)

    return true, "joined"
end

function PvPService:Leave(player: Player)
    if not PvPRules.canLeave(self.participants[player] == true) then
        return false, "not_in_pvp"
    end

    self.participants[player] = nil
    player:SetAttribute("CBS_PvP", false)

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if root and root:IsA("BasePart") then
        root.CFrame = CFrame.new(0, 6, 0)
        root.AssemblyLinearVelocity = Vector3.zero
    end

    return true, "left"
end

function PvPService:GetAvailableDashDistance(position: Vector3, direction: Vector3, maximum: number)
    local limitX = if direction.X > 0
        then (70 - position.X) / direction.X
        elseif direction.X < 0
        then (-70 - position.X) / direction.X
        else math.huge

    local limitZ = if direction.Z > 0
        then (242 - position.Z) / direction.Z
        elseif direction.Z < 0
        then (138 - position.Z) / direction.Z
        else math.huge

    local available = math.huge

    if limitX > 0 then
        available = math.min(available, limitX)
    end

    if limitZ > 0 then
        available = math.min(available, limitZ)
    end

    return math.max(0, math.min(maximum, available))
end

function PvPService:IsParticipant(player: Player)
    return self.participants[player] == true
end

function PvPService:IsInsideZone(position: Vector3)
    return position.X >= -70
        and position.X <= 70
        and position.Z >= 138
        and position.Z <= 242
        and position.Y >= -10
        and position.Y <= 60
end

function PvPService:ValidateTarget(player: Player, target: Player)
    if not target or target == player then
        return false
    end

    return self:IsParticipant(player) and self:IsParticipant(target)
end

return PvPService
