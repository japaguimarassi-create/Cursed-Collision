--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local diagnostics: {[Model]: boolean} = {}

local function inspect(character: Model)
    if diagnostics[character] then
        return
    end

    local hasAnimator = false
    local hasMotor6D = false
    local hasConstraint = false

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid:FindFirstChildOfClass("Animator") then
        hasAnimator = true
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("Motor6D") then
            hasMotor6D = true
        elseif object:IsA("AnimationConstraint") then
            hasConstraint = true
        end
    end

    character:SetAttribute("CC_AnimationBackend", hasConstraint and "AnimationConstraint" or "Motor6D")
    character:SetAttribute("CC_AnimatorReady", hasAnimator)
    character:SetAttribute("CC_JointDiagnostics", string.format("Motor6D=%s Constraint=%s", tostring(hasMotor6D), tostring(hasConstraint)))

    diagnostics[character] = true
end

local function bindPlayer(player: Player)
    if player.Character then
        inspect(player.Character)
    end

    player.CharacterAdded:Connect(function(character)
        diagnostics[character] = nil
        task.defer(inspect, character)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    bindPlayer(player)
end

Players.PlayerAdded:Connect(bindPlayer)

RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and not diagnostics[character] then
            inspect(character)
        end
    end
end)
