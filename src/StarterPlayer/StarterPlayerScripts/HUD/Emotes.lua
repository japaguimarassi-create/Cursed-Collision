--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Util = require(script.Parent.Util)

local player = Players.LocalPlayer
local M = {}
local started = false

type Active = {
    id: string,
    started: number,
    duration: number,
    loop: boolean,
    joints: {[string]: Motor6D?}
}

local active: {[Model]: Active} = {}

local function findJoint(character: Model, names: {string}): Motor6D?
    for _, name in ipairs(names) do
        local joint = character:FindFirstChild(name, true)
        if joint and joint:IsA("Motor6D") then
            return joint
        end
    end
    return nil
end

local function joints(character: Model)
    return {
        Root = findJoint(character, {"Root", "RootJoint"}),
        Waist = findJoint(character, {"Waist"}),
        Neck = findJoint(character, {"Neck"}),
        LeftShoulder = findJoint(character, {"LeftShoulder", "Left Shoulder"}),
        RightShoulder = findJoint(character, {"RightShoulder", "Right Shoulder"}),
        LeftHip = findJoint(character, {"LeftHip", "Left Hip"}),
        RightHip = findJoint(character, {"RightHip", "Right Hip"})
    }
end

local function apply(data: Active, pose: {[string]: CFrame})
    for name, joint in pairs(data.joints) do
        if joint and joint.Parent then
            joint.Transform = pose[name] or CFrame.identity
        end
    end
end

local function stopModel(model: Model)
    local data = active[model]
    if not data then
        return
    end
    apply(data, {})
    active[model] = nil
end

local function pose(id: string, t: number): {[string]: CFrame}
    local wave = math.sin(t * math.pi * 2)
    local wave2 = math.sin(t * math.pi * 4)

    if id == "emote_001" then
        return {
            Waist = CFrame.Angles(0.04 * wave2, 0.12 * wave, 0.05 * wave),
            LeftShoulder = CFrame.Angles(0.18 * wave, 0, -0.42 - 0.16 * wave),
            RightShoulder = CFrame.Angles(-0.12 * wave, 0, 0.72 + 0.12 * wave),
            LeftHip = CFrame.Angles(0, 0.06 * wave, 0),
            RightHip = CFrame.Angles(0, -0.06 * wave, 0)
        }
    elseif id == "emote_002" then
        local p = math.clamp(t / 1, 0, 1)
        local lift = math.sin(p * math.pi)
        return {
            Waist = CFrame.Angles(0, -0.12 * lift, 0),
            Neck = CFrame.Angles(0, 0, -0.10 * lift),
            RightShoulder = CFrame.Angles(-0.95 * lift, 0.08 * lift, 0.48 * lift),
            LeftShoulder = CFrame.Angles(0.08 * lift, 0, -0.18 * lift)
        }
    elseif id == "emote_003" then
        return {
            Waist = CFrame.Angles(-0.10 + 0.05 * wave, 0.14 * wave, 0),
            LeftShoulder = CFrame.Angles(-0.92 + 0.20 * wave, 0, -0.42 * wave2),
            RightShoulder = CFrame.Angles(-0.92 - 0.20 * wave, 0, 0.42 * wave2)
        }
    elseif id == "emote_004" then
        return {
            Waist = CFrame.Angles(0.04, 0.32 * wave, 0.06 * wave),
            Neck = CFrame.Angles(0, -0.24 * wave, 0),
            LeftShoulder = CFrame.Angles(0.18 * wave, 0, 0.22),
            RightShoulder = CFrame.Angles(-0.18 * wave, 0, -0.64),
            Root = CFrame.Angles(0, 0.10 * wave, 0)
        }
    end

    local p = math.clamp(t / 3.1, 0, 1)
    local snap = math.clamp((p - 0.42) / 0.16, 0, 1)
    return {
        Waist = CFrame.Angles(-0.06 * snap, -0.24 * snap, 0),
        Neck = CFrame.Angles(0, 0.18 * snap, 0),
        LeftShoulder = CFrame.Angles(-0.52 * snap, 0, -0.24 * snap),
        RightShoulder = CFrame.Angles(-0.76 * snap, 0, 0.48 * snap)
    }
end

function M.Start()
    if started then return end
    started = true

    local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
    if not remotes then return end

    local actionRemote = remotes:WaitForChild("EmoteAction", 15)
    local eventRemote = remotes:WaitForChild("EmoteEvent", 15)
    if not actionRemote or not eventRemote then return end

    local definitions = require(ReplicatedStorage.Emotes.EmoteDefinitions)

    local gui = Util.makeGui("CursedCollisionEmoteUI", 8)
    local root = Util.makeRoot(gui)

    local button = Util.button(root, "EmoteButton", "☆", UDim2.fromScale(0.060, 0.052), UDim2.fromScale(0.925, 0.095), true)
    button.TextSize = 18

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Util.Colors.Black
    backdrop.BackgroundTransparency = 0.30
    backdrop.Visible = false
    backdrop.Active = true
    backdrop.Parent = root

    local wheel = Instance.new("Frame")
    wheel.Name = "EmoteWheel"
    wheel.Size = UDim2.fromScale(0.52, 0.58)
    wheel.Position = UDim2.fromScale(0.50, 0.50)
    wheel.AnchorPoint = Vector2.new(0.5, 0.5)
    wheel.BackgroundColor3 = Util.Colors.Panel
    wheel.BackgroundTransparency = 0.06
    wheel.Visible = false
    wheel.Parent = root
    Util.corner(wheel, 24)
    Util.stroke(wheel, Util.Colors.Accent2, 0.58, 1.2)

    local center = Instance.new("Frame")
    center.Size = UDim2.fromScale(0.28, 0.28)
    center.Position = UDim2.fromScale(0.50, 0.50)
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.BackgroundColor3 = Util.Colors.Background
    center.Parent = wheel
    Util.corner(center, 100)

    Util.label(center, "EMOTES", UDim2.fromScale(0.92, 0.36), UDim2.fromScale(0.04, 0.18), 11, Enum.Font.GothamBlack)
    local hint = Util.label(center, "TAP / SELECT", UDim2.fromScale(0.90, 0.20), UDim2.fromScale(0.05, 0.60), 7)
    hint.TextColor3 = Util.Colors.Muted

    local ids = {"emote_001", "emote_002", "emote_003", "emote_004", "emote_005"}
    local buttons: {[number]: TextButton} = {}

    for index, id in ipairs(ids) do
        local angle = math.rad(-90 + (index - 1) * 72)
        local x = 0.50 + math.cos(angle) * 0.39
        local y = 0.50 + math.sin(angle) * 0.39
        local info = definitions[id]

        local slot = Util.button(
            wheel,
            "Slot" .. index,
            tostring(index) .. "\n" .. tostring(info and info.Name or id),
            UDim2.fromScale(0.25, 0.19),
            UDim2.fromScale(x, y),
            true
        )
        slot.AnchorPoint = Vector2.new(0.5, 0.5)
        buttons[index] = slot

        slot.Activated:Connect(function()
            actionRemote:FireServer("Start", {Id = id})
            wheel.Visible = false
            backdrop.Visible = false
            Util.setMenuAttributes("Emote", false)
        end)
    end

    local function open()
        Util.closeKnownPanels("Emote")
        Util.setMenuAttributes("Emote", true)
        wheel.Visible = true
        backdrop.Visible = true
        Util.setGamepadNavigation(true)
        GuiService.SelectedObject = buttons[1]
    end

    local function closeWheel()
        wheel.Visible = false
        backdrop.Visible = false
        Util.setMenuAttributes("Emote", false)
    end

    button.Activated:Connect(function()
        if wheel.Visible then closeWheel() else open() end
    end)

    backdrop.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            close()
        end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.B then
            if wheel.Visible then close() else open() end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1
            or input.KeyCode == Enum.KeyCode.Space then
            if active[player.Character] then
                actionRemote:FireServer("Stop", {})
            end
        end
    end)

    eventRemote.OnClientEvent:Connect(function(event, payload)
        if not payload or type(payload.UserId) ~= "number" then return end
        local actor = Players:GetPlayerByUserId(payload.UserId)
        local model = actor and actor.Character
        if not model then return end

        if event == "Play" then
            local info = definitions[payload.Id]
            if not info then return end
            stopModel(model)
            active[model] = {
                id = tostring(info.Id),
                started = os.clock(),
                duration = math.max(0.05, tonumber(payload.Duration) or tonumber(info.Duration) or 1),
                loop = payload.Loop == true,
                joints = joints(model)
            }
        elseif event == "Stop" then
            stopModel(model)
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
                if humanoid and (
                    humanoid.MoveDirection.Magnitude > 0.08
                    or humanoid.Health <= 0
                    or humanoid:GetAttribute("Stunned") == true
                    or model:GetAttribute("Ragdolled") == true
                    or model:GetAttribute("Stunned") == true
                ) then
                    actionRemote:FireServer("Stop", {})
                    stopModel(model)
                    continue
                end
            end

            local elapsed = os.clock() - data.started
            if elapsed >= data.duration then
                if data.loop then
                    data.started = os.clock()
                    elapsed = 0
                else
                    if model == localModel then
                        actionRemote:FireServer("Stop", {})
                    end
                    stopModel(model)
                    continue
                end
            end

            local cycle = data.loop and (elapsed % math.max(0.1, data.duration)) or elapsed
            apply(data, pose(data.id, cycle))
        end
    end)
end

return M
