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

local function playerCharacter(player)
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

local function available(player, kind, duration)
    cooldowns[player] = cooldowns[player] or {}
    local now = os.clock()
    local last = cooldowns[player][kind] or 0

    if now - last < duration then
        return false
    end

    cooldowns[player][kind] = now
    return true
end

local function train(player, kind)
    if not profiles.IsLoaded(player) then
        return
    end

    if player:GetAttribute("CarryingAnimal") then
        notify(player, "Venda ou perca o animal atual antes de treinar.", "Warning")
        return
    end

    local _, humanoid = playerCharacter(player)

    if not humanoid then
        return
    end

    local data = profiles.Get(player)

    if not data then
        return
    end

    if kind == "Treadmill" then
        if data.Speed >= Config.MaxSpeedLevel then
            notify(player, "Velocidade no nível máximo.", "Info")
            return
        end

        if not available(player, "TreadmillReward", Config.Training.TreadmillInterval) then
            return
        end

        local success = profiles.AddStat(player, "Speed", Config.Training.TreadmillGain)

        if success then
            animalService.ApplyMovement(player)
            notify(player, "+1 Velocidade! Continue correndo para treinar.", "Success")
        end

        return
    end

    if kind == "BenchPress" then
        if data.Strength >= Config.MaxStrength then
            notify(player, "Força no nível máximo.", "Info")
            return
        end

        if not available(player, "BenchPressReward", Config.Training.BenchPressCooldown) then
            return
        end

        local success = profiles.AddStat(player, "Strength", Config.Training.BenchPressGain)

        if success then
            animalService.ApplyMovement(player)
            notify(player, "+2 Força! Você consegue carregar animais mais pesados.", "Success")
        end
    end
end

local function preparePrompt(prompt, trainingType)
    if trainingType == "Treadmill" then
        prompt.ActionText = "Treinar Velocidade"
        prompt.ObjectText = "Esteira"
        prompt.HoldDuration = 0.5
        prompt.MaxActivationDistance = 9
        prompt.RequiresLineOfSight = false
        prompt:SetAttribute("InteractionType", "Treadmill")
        return
    end

    prompt.ActionText = "Fazer supino"
    prompt.ObjectText = "Treino de Força"
    prompt.HoldDuration = 0.7
    prompt.MaxActivationDistance = 9
    prompt.RequiresLineOfSight = false
    prompt:SetAttribute("InteractionType", "BenchPress")
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

    local trainingParts = worldBuilder.GetTrainingParts()

    for _, part in ipairs(trainingParts) do
        local trainingType = part:GetAttribute("TrainingType")

        if trainingType == "BenchPress" or trainingType == "Treadmill" then
            local prompt = part:FindFirstChildWhichIsA("ProximityPrompt")

            if not prompt then
                prompt = Instance.new("ProximityPrompt")
                prompt.Name = trainingType == "Treadmill" and "TreadmillPrompt" or "BenchPressPrompt"
                prompt.Parent = part
            end

            preparePrompt(prompt, trainingType)
        end
    end

    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        local trainingType = prompt:GetAttribute("InteractionType")

        if trainingType ~= "BenchPress" and trainingType ~= "Treadmill" then
            return
        end

        local part = prompt.Parent

        if not part
            or not part:IsA("BasePart")
            or part:GetAttribute("TrainingType") ~= trainingType
            or not part:IsDescendantOf(worldBuilder.GetTrainingFolder()) then
            return
        end

        local _, _, root = playerCharacter(player)

        if not root
            or (root.Position - part.Position).Magnitude
                > math.min(prompt.MaxActivationDistance, Config.MaxInteractionDistance) + 2 then
            return
        end

        local success, err = pcall(train, player, trainingType)

        if not success then
            warn("RoubeUmAnimal: falha no treino " .. trainingType .. ": " .. tostring(err))
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.35)

            for _, player in ipairs(Players:GetPlayers()) do
                local _, humanoid, root = playerCharacter(player)

                if root and humanoid and humanoid.MoveDirection.Magnitude > 0.15 then
                    for _, part in ipairs(trainingParts) do
                        if part.Parent
                            and part:GetAttribute("TrainingType") == "Treadmill"
                            and insidePart(part, root.Position) then
                            local success, err = pcall(train, player, "Treadmill")

                            if not success then
                                warn("RoubeUmAnimal: falha na esteira: " .. tostring(err))
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
