local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimalAnimator = require(Shared:WaitForChild("AnimalAnimator"))
local TreadmillAnimator = require(Shared:WaitForChild("TreadmillAnimator"))

local animalAnimator = AnimalAnimator.new()
local trackedModels = setmetatable({}, { __mode = "k" })
local modelConnections = setmetatable({}, { __mode = "k" })
local treadmillEntries = {}
local trackedTreadmillParts = setmetatable({}, { __mode = "k" })

local function isAnimalModel(model)
    return model
        and model:IsA("Model")
        and model:GetAttribute("AnimalId") ~= nil
        and model.PrimaryPart ~= nil
end

local function attachAnimal(model)
    if not isAnimalModel(model) or trackedModels[model] then
        return false
    end

    local initialState = model:GetAttribute("AnimationState") or "Rest"
    local registered = animalAnimator:Register(model, initialState)
    if not registered then
        return false
    end

    trackedModels[model] = true
    modelConnections[model] = model:GetAttributeChangedSignal("AnimationState"):Connect(function()
        local state = model:GetAttribute("AnimationState")
        if state == "Walk" or state == "Rest" or state == "Run" then
            animalAnimator:SetState(model, state)
        end
    end)

    model.Destroying:Connect(function()
        animalAnimator:Remove(model)
        trackedModels[model] = nil
        local connection = modelConnections[model]
        if connection then
            connection:Disconnect()
            modelConnections[model] = nil
        end
    end)

    return true
end

local function queueAnimalAttachment(instance)
    if not instance:IsA("Model") then
        return
    end
    task.defer(function()
        if instance.Parent and not attachAnimal(instance) then
            task.delay(0.1, function()
                if instance.Parent then
                    attachAnimal(instance)
                end
            end)
        end
    end)
end

local function attachTreadmillPart(part)
    if not part:IsA("BasePart") or trackedTreadmillParts[part] then
        return
    end

    if part.Name == "MovingBeltStripe" then
        local origin = part:GetAttribute("TreadmillOrigin")
        if typeof(origin) ~= "Vector3" then
            return
        end
        table.insert(treadmillEntries, {
            Part = part,
            Kind = "Stripe",
            Origin = origin,
            Phase = tonumber(part:GetAttribute("AnimationPhase")) or 0,
            Length = tonumber(part:GetAttribute("AnimationLength")) or 7.2,
            Speed = tonumber(part:GetAttribute("AnimationSpeed")) or 2.4,
        })
        trackedTreadmillParts[part] = true
    elseif part.Name == "BeltRoller" then
        table.insert(treadmillEntries, {
            Part = part,
            Kind = "Roller",
            BaseCFrame = part.CFrame,
            Speed = tonumber(part:GetAttribute("AnimationSpeed")) or 3.4,
        })
        trackedTreadmillParts[part] = true
    end
end

for _, instance in ipairs(Workspace:GetDescendants()) do
    if instance:IsA("Model") then
        queueAnimalAttachment(instance)
    elseif instance:IsA("BasePart") then
        attachTreadmillPart(instance)
    end
end

Workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("Model") then
        queueAnimalAttachment(instance)
    elseif instance:IsA("BasePart") then
        task.defer(attachTreadmillPart, instance)
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    local camera = Workspace.CurrentCamera
    animalAnimator:SetViewPosition(camera and camera.CFrame.Position or nil)
    animalAnimator:Step(deltaTime)
    TreadmillAnimator.Step(treadmillEntries, os.clock())
end)

LocalPlayer.CharacterAdded:Connect(function()
    local camera = Workspace.CurrentCamera
    animalAnimator:SetViewPosition(camera and camera.CFrame.Position or nil)
end)
