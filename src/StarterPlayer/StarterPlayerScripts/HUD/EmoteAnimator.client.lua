--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local event = remotes and remotes:WaitForChild("EmoteEvent", 15)
local fx = remotes and remotes:WaitForChild("CombatFX", 15)
if not event or not fx then
    return
end

type Active = {
    Id: string,
    Started: number,
    Duration: number,
    Loop: boolean,
    Joints: {[string]: Motor6D?}
}

local active: {[Model]: Active} = {}

local function joint(character: Model, names: {string}): Motor6D?
    for _, name in ipairs(names) do
        local found = character:FindFirstChild(name, true)
        if found and found:IsA("Motor6D") then
            return found
        end
    end
    return nil
end

local function joints(character: Model): {[string]: Motor6D?}
    return {
        Root = joint(character, {"Root", "RootJoint"}),
        Waist = joint(character, {"Waist"}),
        Neck = joint(character, {"Neck"}),
        LeftShoulder = joint(character, {"LeftShoulder", "Left Shoulder"}),
        RightShoulder = joint(character, {"RightShoulder", "Right Shoulder"}),
        LeftHip = joint(character, {"LeftHip", "Left Hip"}),
        RightHip = joint(character, {"RightHip", "Right Hip"})
    }
end

local function clear(data: Active)
    for _, motor in pairs(data.Joints) do
        if motor and motor.Parent then
            motor.Transform = CFrame.identity
        end
    end
end

local function stop(model: Model)
    local data = active[model]
    if not data then
        return
    end
    clear(data)
    active[model] = nil
    if model == player.Character then
        player:SetAttribute("CCHUD_EmoteActive", false)
    end
end

local function pose(id: string, t: number): {[string]: CFrame}
    local wave = math.sin(t * math.pi * 2)
    local fast = math.sin(t * math.pi * 4)

    if id == "emote_001" then
        return {
            Waist = CFrame.Angles(0.04 * fast, 0.10 * wave, 0.04 * wave),
            LeftShoulder = CFrame.Angles(0.16 * wave, 0, -0.44 - 0.12 * wave),
            RightShoulder = CFrame.Angles(-0.10 * wave, 0, 0.70 + 0.10 * wave)
        }
    elseif id == "emote_002" then
        local progress = math.clamp(t, 0, 1)
        local lift = math.sin(progress * math.pi)
        return {
            Waist = CFrame.Angles(0, -0.10 * lift, 0),
            Neck = CFrame.Angles(0, 0, -0.08 * lift),
            RightShoulder = CFrame.Angles(-0.95 * lift, 0.06 * lift, 0.44 * lift)
        }
    elseif id == "emote_003" then
        return {
            Waist = CFrame.Angles(-0.08 + 0.04 * wave, 0.14 * wave, 0),
            LeftShoulder = CFrame.Angles(-0.90 + 0.16 * wave, 0, -0.38 * fast),
            RightShoulder = CFrame.Angles(-0.90 - 0.16 * wave, 0, 0.38 * fast),
            LeftHip = CFrame.Angles(0.13 * wave, 0, 0),
            RightHip = CFrame.Angles(-0.13 * wave, 0, 0)
        }
    elseif id == "emote_004" then
        return {
            Waist = CFrame.Angles(0.04, 0.28 * wave, 0.05 * wave),
            Neck = CFrame.Angles(0, -0.20 * wave, 0),
            LeftShoulder = CFrame.Angles(0.15 * wave, 0, 0.20),
            RightShoulder = CFrame.Angles(-0.15 * wave, 0, -0.60)
        }
    end

    local progress = math.clamp(t / 3.1, 0, 1)
    local snap = math.clamp((progress - 0.40) / 0.16, 0, 1)
    return {
        Waist = CFrame.Angles(-0.06 * snap, -0.20 * snap, 0),
        Neck = CFrame.Angles(0, 0.15 * snap, 0),
        LeftShoulder = CFrame.Angles(-0.48 * snap, 0, -0.20 * snap),
        RightShoulder = CFrame.Angles(-0.72 * snap, 0, 0.44 * snap)
    }
end

local function play(model: Model, id: string, duration: number, loop: boolean)
    stop(model)
    active[model] = {
        Id = id,
        Started = os.clock(),
        Duration = duration,
        Loop = loop,
        Joints = joints(model)
    }
    if model == player.Character then
        player:SetAttribute("CCHUD_EmoteActive", true)
    end
end

event.OnClientEvent:Connect(function(kind, payload)
    if type(payload) ~= "table" or type(payload.UserId) ~= "number" then
        return
    end

    local target = Players:GetPlayerByUserId(payload.UserId)
    local model = target and target.Character
    if not model then
        return
    end

    if kind == "Play" then
        play(
            model,
            tostring(payload.Id or "emote_001"),
            math.max(0.1, tonumber(payload.Duration) or 3),
            payload.Loop == true
        )
    elseif kind == "Stop" then
        stop(model)
    end
end)

fx.OnClientEvent:Connect(function(kind, _, payload)
    if kind ~= "Hit" and kind ~= "PerfectBlock" and kind ~= "Death" then
        return
    end
    local actor: Instance? = nil
    if type(payload) == "table" then
        actor = payload.actor
    end

    if actor and actor:IsA("Model") then
        stop(actor)
    end
end)

RunService.RenderStepped:Connect(function()
    local localModel = player.Character

    for model, data in pairs(active) do
        if not model.Parent then
            active[model] = nil
            continue
        end

        if model == localModel then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local moving = humanoid.MoveDirection.Magnitude > 0.08
                local state = humanoid:GetState()
                if moving
                    or state == Enum.HumanoidStateType.Jumping
                    or state == Enum.HumanoidStateType.Freefall
                    or humanoid.Health <= 0
                    or model:GetAttribute("Stunned") == true
                    or model:GetAttribute("Ragdolled") == true then
                    stop(model)
                    continue
                end
            end
        end

        local elapsed = os.clock() - data.Started
        if elapsed >= data.Duration then
            if data.Loop then
                data.Started = os.clock()
                elapsed = 0
            else
                stop(model)
                continue
            end
        end

        local current = pose(data.Id, elapsed)
        for name, motor in pairs(data.Joints) do
            if motor and motor.Parent then
                motor.Transform = current[name] or CFrame.identity
            end
        end
    end
end)
