--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsRules = require(ReplicatedStorage.Shared.PhysicsRules)

local PhysicsService = {}
PhysicsService.__index = PhysicsService

function PhysicsService.new()
    return setmetatable({
        active = false,
    }, PhysicsService)
end

function PhysicsService:Start()
    self.active = true
end

function PhysicsService:ApplyWorld(world: Instance)
    for _, descendant in ipairs(world:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if descendant.Name:find("Cover", 1, true) then
                PhysicsRules.apply(descendant, PhysicsRules.Cover)
            else
                PhysicsRules.apply(descendant, PhysicsRules.World)
            end
        end
    end
end

function PhysicsService:ApplyCharacter(character: Model)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            PhysicsRules.apply(descendant, PhysicsRules.Character)
        end
    end
end

function PhysicsService:ApplyEnemy(model: Model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            PhysicsRules.apply(descendant, PhysicsRules.Enemy)
        end
    end
end

function PhysicsService:ApplyEcho(model: Model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            PhysicsRules.apply(descendant, PhysicsRules.Echo)
        end
    end
end

function PhysicsService:HealthCheck()
    return self.active
end

function PhysicsService:Stop()
    self.active = false
end

return PhysicsService
