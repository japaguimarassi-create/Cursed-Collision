--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)

if not remotes then
    return
end

local actionRemote = remotes:WaitForChild("EmoteAction", 15)
local eventRemote = remotes:WaitForChild("EmoteEvent", 15)
local combatFX = remotes:WaitForChild("CombatFX", 15)

if not actionRemote or not eventRemote or not combatFX then
    return
end

local definitions = require(ReplicatedStorage.Emotes.EmoteDefinitions)
local AnimationCache = require(script.Parent.Controllers.AnimationCache)

local oldGui = playerGui:FindFirstChild("CursedCollisionEmoteUI")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionEmoteUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local function corner(object: GuiObject, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object
end

local function stroke(object: GuiObject, transparency: number)
    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Transparency = transparency
    s.Parent = object
end

local function makeButton(parent: Instance, name: string, textValue: string): TextButton
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.fromScale(1, 1)
    b.Text = textValue
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 10
    b.TextColor3 = Color3.fromRGB(240, 241, 246)
    b.BackgroundColor3 = Color3.fromRGB(19, 22, 30)
    b.BackgroundTransparency = 0.08
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Active = true
    b.Selectable = true
    b.Parent = parent
    corner(b, 14)
    stroke(b, 0.56)
    return b
end

local emoteButton = Instance.new("TextButton")
emoteButton.Name = "EmoteButton"
emoteButton.Size = UDim2.fromScale(0.11, 0.058)
emoteButton.Position = UDim2.fromScale(0.755, 0.022)
emoteButton.Text = "EMOTES"
emoteButton.Font = Enum.Font.GothamBlack
emoteButton.TextSize = 10
emoteButton.TextColor3 = Color3.fromRGB(240, 241, 246)
emoteButton.BackgroundColor3 = Color3.fromRGB(19, 22, 30)
emoteButton.BackgroundTransparency = 0.08
emoteButton.BorderSizePixel = 0
emoteButton.AutoButtonColor = true
emoteButton.Active = true
emoteButton.Selectable = true
emoteButton.Parent = root
corner(emoteButton, 10)
stroke(emoteButton, 0.56)

local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(4, 5, 8)
backdrop.BackgroundTransparency = 0.34
backdrop.Text = ""
backdrop.Visible = false
backdrop.AutoButtonColor = false
backdrop.Parent = root

local panel = Instance.new("Frame")
panel.Name = "EmoteWheel"
panel.Size = UDim2.fromScale(0.56, 0.61)
panel.Position = UDim2.fromScale(0.50, 0.49)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = root
corner(panel, 24)
stroke(panel, 1.0)

local center = Instance.new("Frame")
center.Size = UDim2.fromScale(0.30, 0.30)
center.Position = UDim2.fromScale(0.50, 0.50)
center.AnchorPoint = Vector2.new(0.5, 0.5)
center.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
center.BorderSizePixel = 0
center.Parent = panel
corner(center, 100)
stroke(center, 0.72)

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(0.90, 0.34)
title.Position = UDim2.fromScale(0.05, 0.16)
title.BackgroundTransparency = 1
title.Text = "EMOTES"
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(240, 241, 246)
title.Parent = center

local hint = Instance.new("TextLabel")
hint.Size = UDim2.fromScale(0.90, 0.22)
hint.Position = UDim2.fromScale(0.05, 0.59)
hint.BackgroundTransparency = 1
hint.Text = "SELECT"
hint.Font = Enum.Font.GothamBold
hint.TextSize = 9
hint.TextColor3 = Color3.fromRGB(151, 154, 171)
hint.Parent = center

local currentWheel: {string} = {
    "emote_001",
    "emote_002",
    "emote_003",
    "emote_004",
    "emote_005"
}

local wheelButtons: {[number]: TextButton} = {}

for index = 1, 5 do
    local angle = math.rad(-90 + (index - 1) * 72)
    local slot = Instance.new("Frame")
    slot.Name = "Slot" .. tostring(index)
    slot.Size = UDim2.fromScale(0.27, 0.20)
    slot.Position = UDim2.fromScale(
        0.50 + math.cos(angle) * 0.40,
        0.50 + math.sin(angle) * 0.40
    )
    slot.AnchorPoint = Vector2.new(0.5, 0.5)
    slot.BackgroundTransparency = 1
    slot.Parent = panel

    local id = currentWheel[index]
    local data = definitions[id]
    local button = makeButton(
        slot,
        "Button",
        tostring(index) .. "\n" .. (data and data.Name or id)
    )

    wheelButtons[index] = button
end

local function menuBlocked(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function closeOtherInterfaces()
    local accountGui = playerGui:FindFirstChild("CursedCollisionAccountUI")
    local accountPanel = accountGui and accountGui:FindFirstChild("AccountPanel")
    if accountPanel and accountPanel:IsA("GuiObject") then
        accountPanel.Visible = false
    end

    local characterGui = playerGui:FindFirstChild("CursedCollisionCharacterUI")
    local characterPanel = characterGui and characterGui:FindFirstChild("CharacterPanel")
    if characterPanel and characterPanel:IsA("GuiObject") then
        characterPanel.Visible = false
    end

    local ownerGui = playerGui:FindFirstChild("CursedCollisionOwnerUI")
    local ownerPanel = ownerGui and ownerGui:FindFirstChild("OwnerPanel")
    if ownerPanel and ownerPanel:IsA("GuiObject") then
        ownerPanel.Visible = false
    end

    player:SetAttribute("CCHUD_MenuOpen", false)
    player:SetAttribute("CCHUD_CharacterMenuOpen", false)
    player:SetAttribute("CCHUD_OwnerPanelOpen", false)
end

local function setWheel(open: boolean)
    if open and menuBlocked() then
        return
    end

    if open then
        closeOtherInterfaces()
    end

    panel.Visible = open
    backdrop.Visible = open
    player:SetAttribute("CCHUD_EmoteWheelOpen", open)

    if open and UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = wheelButtons[1]
    end
end

local function toggleWheel()
    setWheel(not panel.Visible)
end

local function stopLocal()
    actionRemote:FireServer("Stop", {})
end

for index = 1, 5 do
    wheelButtons[index].Activated:Connect(function()
        actionRemote:FireServer("Start", {
            Id = currentWheel[index]
        })
        setWheel(false)
    end)
end

emoteButton.Activated:Connect(toggleWheel)
backdrop.Activated:Connect(function()
    setWheel(false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.B then
        toggleWheel()
        return
    end

    if input.KeyCode == Enum.KeyCode.ButtonB then
        setWheel(false)
        return
    end

    if input.KeyCode == Enum.KeyCode.Space
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if player.Character then
            stopLocal()
        end
    end
end)

local function findJoint(character: Model, names: {string}): Motor6D?
    for _, name in ipairs(names) do
        local joint = character:FindFirstChild(name, true)
        if joint and joint:IsA("Motor6D") then
            return joint
        end
    end

    return nil
end

local function captureJoints(character: Model): {[string]: Motor6D?}
    return {
        Waist = findJoint(character, {"Waist"}),
        Neck = findJoint(character, {"Neck"}),
        LeftShoulder = findJoint(character, {"LeftShoulder", "Left Shoulder"}),
        RightShoulder = findJoint(character, {"RightShoulder", "Right Shoulder"}),
        LeftHip = findJoint(character, {"LeftHip", "Left Hip"}),
        RightHip = findJoint(character, {"RightHip", "Right Hip"})
    }
end

type Active = {
    id: string,
    startedAt: number,
    duration: number,
    looped: boolean,
    track: AnimationTrack?,
    joints: {[string]: Motor6D?}
}

local active: {[Model]: Active} = {}

local function clearPose(data: Active)
    for _, joint in pairs(data.joints) do
        if joint and joint.Parent then
            joint.Transform = CFrame.identity
        end
    end
end

local function stopModel(model: Model)
    local data = active[model]
    if not data then
        return
    end

    if data.track and data.track.IsPlaying then
        data.track:Stop(0.08)
    end

    clearPose(data)
    active[model] = nil
end

local function poseFor(id: string, t: number): {[string]: CFrame}
    local wave = math.sin(t * math.pi * 2)
    local snap = math.clamp((t - 0.85) / 0.20, 0, 1)

    if id == "emote_001" then
        return {
            Waist = CFrame.Angles(0, 0.10 * wave, 0),
            LeftShoulder = CFrame.Angles(0.12 * wave, 0, -0.42 - 0.14 * wave),
            RightShoulder = CFrame.Angles(-0.08 * wave, 0, 0.62 + 0.12 * wave),
            LeftHip = CFrame.Angles(0, 0.06 * wave, 0),
            RightHip = CFrame.Angles(0, -0.06 * wave, 0)
        }
    elseif id == "emote_002" then
        local lift = math.sin(math.clamp(t / 1.0, 0, 1) * math.pi)
        return {
            Waist = CFrame.Angles(0, -0.10 * lift, 0),
            RightShoulder = CFrame.Angles(-0.92 * lift, 0.08 * lift, 0.45 * lift),
            LeftShoulder = CFrame.Angles(0.10 * lift, 0, -0.14 * lift),
            Neck = CFrame.Angles(0, 0.12 * lift, 0)
        }
    elseif id == "emote_003" then
        return {
            Waist = CFrame.Angles(-0.08 + 0.05 * wave, 0.12 * wave, 0),
            LeftShoulder = CFrame.Angles(-0.82 + 0.16 * wave, 0, -0.36 * wave),
            RightShoulder = CFrame.Angles(-0.82 - 0.16 * wave, 0, 0.36 * wave),
            LeftHip = CFrame.Angles(0.12 * wave, 0, 0),
            RightHip = CFrame.Angles(-0.12 * wave, 0, 0)
        }
    elseif id == "emote_004" then
        return {
            Waist = CFrame.Angles(0.04, 0.28 * wave, 0.05 * wave),
            Neck = CFrame.Angles(0, -0.20 * wave, 0),
            LeftShoulder = CFrame.Angles(0.14 * wave, 0, 0.20),
            RightShoulder = CFrame.Angles(-0.14 * wave, 0, -0.58)
        }
    end

    return {
        Waist = CFrame.Angles(-0.06 * snap, -0.20 * snap, 0),
        Neck = CFrame.Angles(0, 0.16 * snap, 0),
        LeftShoulder = CFrame.Angles(-0.48 * snap, 0, -0.22 * snap),
        RightShoulder = CFrame.Angles(-0.72 * snap, 0, 0.44 * snap)
    }
end

local function playModel(model: Model, id: string, duration: number, looped: boolean, animationKey: string?)
    stopModel(model)

    local key = animationKey or ("Emote_" .. string.sub(id, -3))
    local animator = model:FindFirstChildOfClass("Humanoid")
        and model:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")

    local track: AnimationTrack? = if animator then AnimationCache:GetTrack(animator, key) else nil

    if track then
        local info = definitions[id]
        track.Priority = info and info.Priority or Enum.AnimationPriority.Action
        track.Looped = looped
        track:Play(info and 0.05 or 0.05, 1, 1)
    end

    active[model] = {
        id = id,
        startedAt = os.clock(),
        duration = duration,
        looped = looped,
        track = track,
        joints = captureJoints(model)
    }
end

eventRemote.OnClientEvent:Connect(function(event, payload)
    if type(payload) ~= "table" then
        return
    end

    local actor = Players:GetPlayerByUserId(tonumber(payload.UserId) or 0)
    local model = actor and actor.Character

    if event == "Play" then
        local info = definitions[payload.Id]
        if model and info then
            playModel(
                model,
                info.Id,
                tonumber(payload.Duration) or info.Duration,
                payload.Loop == true,
                type(payload.AnimationKey) == "string" and payload.AnimationKey or info.AnimationKey
            )
        end
    elseif event == "Stop" and model then
        stopModel(model)
    end
end)

combatFX.OnClientEvent:Connect(function(kind, _, payload)
    if not payload then
        return
    end

    if kind == "Hit"
        or kind == "PerfectBlock"
        or kind == "Death"
        or kind == "CombatAction" then
        local actor = payload.actor
        if actor and actor:IsA("Model") then
            stopModel(actor)
        end
    end
end)

local function shouldStop(model: Model): boolean
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return true
    end

    if model == player.Character then
        if player:GetAttribute("IsAttacking") == true
            or player:GetAttribute("Stunned") == true
            or player:GetAttribute("Ragdolled") == true
            or humanoid.MoveDirection.Magnitude > 0.05 then
            return true
        end
    end

    return false
end

player.CharacterAdded:Connect(function()
    setWheel(false)
    for model in pairs(active) do
        stopModel(model)
    end
end)

RunService.RenderStepped:Connect(function()
    for model, data in pairs(active) do
        if not model.Parent or shouldStop(model) then
            if model == player.Character then
                stopLocal()
            end
            stopModel(model)
            continue
        end

        local elapsed = os.clock() - data.startedAt

        if elapsed >= data.duration then
            if data.looped then
                data.startedAt = os.clock()
                elapsed = 0
            else
                if model == player.Character then
                    stopLocal()
                end
                stopModel(model)
                continue
            end
        end

        if not data.track then
            for name, joint in pairs(data.joints) do
                if joint and joint.Parent then
                    joint.Transform = poseFor(data.id, elapsed)
                end
            end
        end
    end
end)

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
    end
end)

return nil
