--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
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

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionEmoteUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 8
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = root

local function refreshScale()
    local camera = workspace.CurrentCamera
    if camera then
        scale.Scale = math.clamp(camera.ViewportSize.Y / 800, 0.82, 1.12)
    end
end

refreshScale()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
end

local function corner(parent: GuiObject, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function stroke(parent: GuiObject, color: Color3, transparency: number)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency
    s.Thickness = 1
    s.Parent = parent
end

local function button(parent: Instance, name: string, textValue: string, size: UDim2, position: UDim2)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = textValue
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = Color3.fromRGB(23, 25, 33)
    b.BackgroundTransparency = 0.05
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.fromRGB(240, 241, 246)
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 11
    b.AutoButtonColor = true
    b.Active = true
    b.Selectable = true
    b.Parent = parent
    corner(b, 13)
    stroke(b, Color3.fromRGB(76, 78, 95), 0.55)
    return b
end

local emoteButton = button(
    root,
    "EmoteButton",
    "EMOTES",
    UDim2.fromScale(0.105, 0.06),
    UDim2.fromScale(0.755, 0.022)
)

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(4, 5, 8)
backdrop.BackgroundTransparency = 0.28
backdrop.Visible = false
backdrop.Parent = root

local wheel = Instance.new("Frame")
wheel.Name = "EmoteWheel"
wheel.Size = UDim2.fromScale(0.52, 0.58)
wheel.Position = UDim2.fromScale(0.50, 0.49)
wheel.AnchorPoint = Vector2.new(0.5, 0.5)
wheel.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
wheel.BackgroundTransparency = 0.05
wheel.Visible = false
wheel.Parent = root
corner(wheel, 26)
stroke(wheel, Color3.fromRGB(155, 112, 255), 1.25)

local center = Instance.new("Frame")
center.Size = UDim2.fromScale(0.30, 0.30)
center.Position = UDim2.fromScale(0.50, 0.50)
center.AnchorPoint = Vector2.new(0.5, 0.5)
center.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
center.Parent = wheel
corner(center, 100)
stroke(center, Color3.fromRGB(82, 84, 101), 1)

local centerTitle = Instance.new("TextLabel")
centerTitle.Size = UDim2.fromScale(0.9, 0.36)
centerTitle.Position = UDim2.fromScale(0.05, 0.18)
centerTitle.BackgroundTransparency = 1
centerTitle.Text = "EMOTES"
centerTitle.TextColor3 = Color3.fromRGB(238, 239, 245)
centerTitle.Font = Enum.Font.GothamBlack
centerTitle.TextScaled = true
centerTitle.Parent = center

local centerHint = Instance.new("TextLabel")
centerHint.Size = UDim2.fromScale(0.86, 0.20)
centerHint.Position = UDim2.fromScale(0.07, 0.60)
centerHint.BackgroundTransparency = 1
centerHint.Text = "TAP TO PLAY"
centerHint.TextColor3 = Color3.fromRGB(150, 154, 168)
centerHint.Font = Enum.Font.GothamBold
centerHint.TextSize = 9
centerHint.Parent = center

local wheelButtons = {}
local currentWheel = {
    "emote_001",
    "emote_002",
    "emote_003",
    "emote_004",
    "emote_005"
}

for index = 1, 5 do
    local angle = math.rad(-90 + (index - 1) * 72)
    local x = 0.50 + math.cos(angle) * 0.39
    local y = 0.50 + math.sin(angle) * 0.39

    local id = currentWheel[index]
    local info = definitions[id]
    local b = button(
        wheel,
        "Slot" .. tostring(index),
        info and tostring(index) .. "\n" .. info.Name or tostring(index),
        UDim2.fromScale(0.25, 0.20),
        UDim2.fromScale(x, y)
    )
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.TextSize = 9
    wheelButtons[index] = b
end

type ActiveEmote = {
    id: string,
    started: number,
    duration: number,
    loop: boolean,
    joints: {[string]: Motor6D?}
}

local activeEmote: {[Model]: any} = {}

local function findJoint(character: Model, names: {string}): Motor6D?
    for _, name in ipairs(names) do
        local joint = character:FindFirstChild(name, true)
        if joint and joint:IsA("Motor6D") then
            return joint
        end
    end
    return nil
end

local function jointsOf(character: Model)
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

local function apply(data, pose: {[string]: CFrame})
    for name, joint in pairs(data.joints) do
        if joint and joint.Parent then
            joint.Transform = pose[name] or CFrame.identity
        end
    end
end

local function clear(data)
    apply(data, {})
end

local function poseFor(id: string, t: number): {[string]: CFrame}
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
        local p = math.clamp(t / 1.0, 0, 1)
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
            RightShoulder = CFrame.Angles(-0.92 - 0.20 * wave, 0, 0.42 * wave2),
            LeftHip = CFrame.Angles(0.15 * wave, 0, 0),
            RightHip = CFrame.Angles(-0.15 * wave, 0, 0)
        }
    elseif id == "emote_004" then
        return {
            Waist = CFrame.Angles(0.04, 0.32 * wave, 0.06 * wave),
            Neck = CFrame.Angles(0, -0.24 * wave, 0),
            LeftShoulder = CFrame.Angles(0.18 * wave, 0, 0.22),
            RightShoulder = CFrame.Angles(-0.18 * wave, 0, -0.64),
            Root = CFrame.Angles(0, 0.10 * wave, 0)
        }
    else
        local p = math.clamp(t / 3.1, 0, 1)
        local snap = math.clamp((p - 0.42) / 0.16, 0, 1)
        return {
            Waist = CFrame.Angles(-0.06 * snap, -0.24 * snap, 0),
            Neck = CFrame.Angles(0, 0.18 * snap, 0),
            LeftShoulder = CFrame.Angles(-0.52 * snap, 0, -0.24 * snap),
            RightShoulder = CFrame.Angles(-0.76 * snap, 0, 0.48 * snap),
            Root = CFrame.Angles(0, 0.20 * snap, 0)
        }
    end
end

local function stopModel(model: Model)
    local data = activeEmote[model]
    if not data then
        return
    end

    clear(data)
    activeEmote[model] = nil
end

local function playModel(model: Model, id: string, duration: number, loop: boolean)
    if activeEmote[model] then
        stopModel(model)
    end

    local data: ActiveEmote = {
        id = id,
        started = os.clock(),
        duration = duration,
        loop = loop,
        joints = jointsOf(model)
    }

    activeEmote[model] = data
end

local function menuBlocked()
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

local function openWheel()
    if menuBlocked() then
        return
    end

    closeOtherInterfaces()
    backdrop.Visible = true
    wheel.Visible = true
    player:SetAttribute("CCHUD_EmoteWheelOpen", true)
end

local function closeWheel()
    backdrop.Visible = false
    wheel.Visible = false
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
end

local function toggleWheel()
    if wheel.Visible then
        closeWheel()
    else
        openWheel()
    end
end

for index = 1, 5 do
    wheelButtons[index].Activated:Connect(function()
        local id = currentWheel[index]
        actionRemote:FireServer("Start", {Id = id})
        closeWheel()
    end)
end

emoteButton.Activated:Connect(toggleWheel)

backdrop.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        closeWheel()
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.B then
        toggleWheel()
    end

    if input.KeyCode == Enum.KeyCode.Space
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if activeEmote[player.Character] then
            actionRemote:FireServer("Stop", {})
        end
    end
end)

local function stopLocal()
    if activeEmote[player.Character] then
        actionRemote:FireServer("Stop", {})
    end
end

player.CharacterAdded:Connect(function()
    stopLocal()
    closeWheel()
end)

player:GetAttributeChangedSignal("CCHUD_MenuOpen"):Connect(function()
    if player:GetAttribute("CCHUD_MenuOpen") == true then
        closeWheel()
        stopLocal()
    end
end)

player:GetAttributeChangedSignal("CCHUD_CharacterMenuOpen"):Connect(function()
    if player:GetAttribute("CCHUD_CharacterMenuOpen") == true then
        closeWheel()
        stopLocal()
    end
end)

combatFX.OnClientEvent:Connect(function(kind, _, payload)
    if kind ~= "CombatAction" or not payload or not payload.actor then
        return
    end

    local actor = payload.actor
    if actor:IsA("Model") then
        stopModel(actor)
    end
end)

eventRemote.OnClientEvent:Connect(function(event, payload)
    if event == "Play" then
        local actor = Players:GetPlayerByUserId(payload.UserId)
        local model = actor and actor.Character
        local info = definitions[payload.Id]

        if model and info then
            playModel(
                model,
                info.Id,
                tonumber(payload.Duration) or info.Duration,
                payload.Loop == true
            )
        end
    elseif event == "Stop" then
        local actor = Players:GetPlayerByUserId(payload.UserId)
        if actor and actor.Character then
            stopModel(actor.Character)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local localModel = player.Character

    for model, data in pairs(activeEmote) do
        if not model.Parent then
            activeEmote[model] = nil
            continue
        end

        if model == localModel then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid
                and (humanoid.MoveDirection.Magnitude > 0.08
                or humanoid:GetState() == Enum.HumanoidStateType.Jumping
                or humanoid:GetState() == Enum.HumanoidStateType.Freefall
                or humanoid.Health <= 0) then
                actionRemote:FireServer("Stop", {})
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

        local cycle = data.id == "emote_001"
            and elapsed / 1.0
            or data.id == "emote_003"
            and elapsed / 1.2
            or data.id == "emote_004"
            and elapsed / 0.9
            or elapsed

        apply(data, poseFor(data.id, cycle))
    end
end)

closeWheel()
