local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local TrainingService = {}
local profiles
local worldBuilder
local animalService
local notify
local cooldowns = {}
local started = false

local function characterState(player)
    local character = player.Character
    if not character then
        return nil, nil, nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then
        return nil, nil, nil
    end
    return character, humanoid, root
end

local function insidePart(part, position)
    local localPosition = part.CFrame:PointToObjectSpace(position)
    return math.abs(localPosition.X) <= part.Size.X * 0.5 + 1.5
        and math.abs(localPosition.Z) <= part.Size.Z * 0.5 + 1.5
        and localPosition.Y >= -4
        and localPosition.Y <= part.Size.Y * 0.5 + 6
end

local function train(player)
    if not profiles.IsLoaded(player) or player:GetAttribute("RebirthInProgress") then
        return
    end
    if player:GetAttribute("CarryingAnimal") then
        notify(player, "Return your carried animal to the barn before training.", "Warning")
        return
    end
    local _, humanoid = characterState(player)
    if not humanoid then
        return
    end
    local data = profiles.Get(player)
    if not data or data.Speed >= Config.MaxSpeedLevel then
        notify(player, "Speed is at the maximum level.", "Info")
        return
    end
    cooldowns[player] = cooldowns[player] or 0
    local now = os.clock()
    if now - cooldowns[player] < Config.Training.TreadmillInterval then
        return
    end
    cooldowns[player] = now
    local gain = Config.Training.TreadmillGain
    if profiles.AddStat(player, "Speed", gain) then
        animalService.ApplyMovement(player)
        notify(player, "+" .. tostring(gain) .. " speed. Sprint to improve your chances of escaping guardians.", "Success")
    end
end

function TrainingService.Start(profileService, builder, animals, notifyFunction)
    if started then
        return
    end
    started = true
    profiles = profileService
    worldBuilder = builder
    animalService = animals
    notify = notifyFunction

    for _, trainingPart in ipairs(worldBuilder.GetTrainingParts()) do
        if trainingPart:GetAttribute("TrainingType") == "Treadmill" then
            local prompt = trainingPart:FindFirstChildWhichIsA("ProximityPrompt")
            if not prompt then
                prompt = Instance.new("ProximityPrompt")
                prompt.Name = "TreadmillPrompt"
                prompt.Parent = trainingPart
            end
            prompt.ActionText = "Train Speed"
            prompt.ObjectText = "Farm Treadmill"
            prompt.HoldDuration = 0.35
            prompt.MaxActivationDistance = 9
            prompt.RequiresLineOfSight = false
            prompt:SetAttribute("InteractionType", "Treadmill")
        end
    end

    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        if prompt:GetAttribute("InteractionType") ~= "Treadmill" then
            return
        end
        local part = prompt.Parent
        if not part or not part:IsA("BasePart")
            or part:GetAttribute("TrainingType") ~= "Treadmill"
            or not part:IsDescendantOf(worldBuilder.GetTrainingFolder()) then
            return
        end
        local _, _, root = characterState(player)
        if not root or (root.Position - part.Position).Magnitude > math.min(prompt.MaxActivationDistance, Config.MaxInteractionDistance) + 2 then
            return
        end
        local success, err = pcall(train, player)
        if not success then
            warn("StealAnAnimal: treadmill error: " .. tostring(err))
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.35)
            for _, player in ipairs(Players:GetPlayers()) do
                local _, humanoid, root = characterState(player)
                if root and humanoid and humanoid.MoveDirection.Magnitude > 0.15 then
                    for _, trainingPart in ipairs(worldBuilder.GetTrainingParts()) do
                        if trainingPart.Parent
                            and trainingPart:GetAttribute("TrainingType") == "Treadmill"
                            and insidePart(trainingPart, root.Position) then
                            local success, err = pcall(train, player)
                            if not success then
                                warn("StealAnAnimal: treadmill reward error: " .. tostring(err))
                            end
                            break
                        end
                    end
                end
            end
        end
    end)
end

function TrainingService.RemovePlayer(player)
    cooldowns[player] = nil
end

return TrainingService
