--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Shared.Definitions)

local TestLabService = {}
TestLabService.__index = TestLabService

local ACTIONS = {
    FullHeal = true,
    AddCredits = true,
    SpawnElite = true,
    ClearArena = true,
    NextWave = true,
    ReturnToArena = true,
}

function TestLabService.new(playerState, enemyService, waveService, worldService, pvpService, remotes)
    return setmetatable({
        playerState = playerState,
        enemyService = enemyService,
        waveService = waveService,
        worldService = worldService,
        pvpService = pvpService,
        remotes = remotes,
    }, TestLabService)
end

function TestLabService:IsAuthorized(player: Player)
    return game.CreatorType == Enum.CreatorType.User
        and player.UserId == game.CreatorId
end

function TestLabService:Start()
    self.remotes.Admin.OnServerEvent:Connect(function(player, request)
        if not self:IsAuthorized(player) then
            return
        end

        if type(request) ~= "table" or ACTIONS[request.action] ~= true then
            return
        end

        local ok, result = self:Execute(player, request.action)
        self.remotes.Admin:FireClient(player, "Result", {
            success = ok,
            action = request.action,
            result = result,
        })
    end)
end

function TestLabService:Execute(player: Player, action: string)
    if action == "FullHeal" then
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not humanoid then
            return false, "character_unavailable"
        end

        humanoid.Health = humanoid.MaxHealth
        return true, "healed"
    end

    if action == "AddCredits" then
        self.playerState:AddCredits(player, 1000)
        return true, "1000_credits"
    end

    if action == "SpawnElite" then
        local points = self.worldService:GetEnemySpawnPoints()
        if #points == 0 then
            return false, "spawn_unavailable"
        end

        local wave = math.max(1, self.waveService.wave)
        local index = (player.UserId % #points) + 1
        local model = self.enemyService:Spawn("Elite", wave, points[index].CFrame)

        if model then
            model:SetAttribute("CBS_TestSpawn", true)
        end

        return model ~= nil, model and "elite_spawned" or "spawn_failed"
    end

    if action == "ClearArena" then
        self.enemyService:ClearAll()
        return true, "arena_cleared"
    end

    if action == "NextWave" then
        self.waveService:RequestNextWave()
        return true, "wave_requested"
    end

    if action == "ReturnToArena" then
        if self.pvpService:IsParticipant(player) then
            self.pvpService:Leave(player)
        else
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                root.CFrame = self.worldService:GetPlayerSpawnCFrame()
            end
        end

        return true, "returned"
    end

    return false, "unknown_action"
end

return TestLabService
