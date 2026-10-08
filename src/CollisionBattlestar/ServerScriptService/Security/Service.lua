--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local SecurityService = {}
SecurityService.__index = SecurityService

function SecurityService.new(worldService, playerState)
    return setmetatable({
        worldService = worldService,
        playerState = playerState,
        strikes = {} :: {[Player]: number},
    }, SecurityService)
end

function SecurityService:Start()
end

function SecurityService:IsAliveCharacter(player: Player)
    local character = player.Character
    if not character then
        return false, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        return false, character, root
    end

    if not root:IsA("BasePart") then
        return false, character, nil
    end

    return true, character, root
end

function SecurityService:IsInsideArena(root: BasePart)
    return self.worldService:IsInsideArena(root.Position)
end


function SecurityService:NormalizeDashDirection(value: any): Vector3?
    if typeof(value) ~= "Vector3" then
        return nil
    end

    local horizontal = Vector3.new(value.X, 0, value.Z)
    local magnitude = horizontal.Magnitude

    if magnitude < 0.1 or magnitude > 1.5 then
        return nil
    end

    if math.abs(value.Y) > Constants.DashVerticalLimit then
        return nil
    end

    return horizontal.Unit
end

function SecurityService:ValidateAttackTargetForActor(root: BasePart, targetModel: Model, maxDistance: number)
    if not targetModel:IsDescendantOf(workspace) then
        return false
    end

    if targetModel:GetAttribute("CBS_Enemy") ~= true then
        return false
    end

    local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")

    if not targetRoot or not targetHumanoid or not targetRoot:IsA("BasePart") or targetHumanoid.Health <= 0 then
        return false
    end

    local offset = targetRoot.Position - root.Position
    if offset.Magnitude > maxDistance then
        return false
    end

    if offset.Magnitude > 0 then
        local direction = offset.Unit
        if root.CFrame.LookVector:Dot(direction) < 0.25 then
            return false
        end
    end

    return true, targetHumanoid, targetRoot
end

function SecurityService:ValidateAttackTarget(player: Player, targetModel: Model, root: BasePart)
    if not targetModel:IsDescendantOf(workspace) then
        return false
    end

    if targetModel:GetAttribute("CBS_Enemy") ~= true then
        return false
    end

    local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")

    if not targetRoot or not targetHumanoid or not targetRoot:IsA("BasePart") then
        return false
    end

    if targetHumanoid.Health <= 0 then
        return false
    end

    local offset = targetRoot.Position - root.Position
    local distance = offset.Magnitude

    if distance > Constants.MaxAttackDistance then
        return false
    end

    if distance > 0 then
        local direction = offset.Unit
        if root.CFrame.LookVector:Dot(direction) < Constants.MaxAttackAngle then
            return false
        end
    end

    return true, targetHumanoid, targetRoot
end

function SecurityService:RecordStrike(player: Player)
    self.strikes[player] = (self.strikes[player] or 0) + 1
end

function SecurityService:GetStrikeCount(player: Player)
    return self.strikes[player] or 0
end

return SecurityService
