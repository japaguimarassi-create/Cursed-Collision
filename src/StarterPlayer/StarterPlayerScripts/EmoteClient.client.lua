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

local oldGui = playerGui:FindFirstChild("CursedCollisionEmoteUI")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionEmoteUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.DisplayOrder = 8
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local function corner(parent: GuiObject, radius: number)
    local value = Instance.new("UICorner")
    value.CornerRadius = UDim.new(0, radius)
    value.Parent = parent
end

local function stroke(parent: GuiObject, transparency: number)
    local value = Instance.new("UIStroke")
    value.Thickness = 1
    value.Transparency = transparency
    value.Parent = parent
end

local function button(
    parent: Instance,
    name: string,
    textValue: string,
    size: UDim2,
    position: UDim2
): TextButton
    local value = Instance.new("TextButton")
    value.Name = name
    value.Text = textValue
    value.Size = size
    value.Position = position
    value.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    value.BackgroundTransparency = 0.05
    value.BorderSizePixel = 0
    value.TextColor3 = Color3.fromRGB(240, 241, 246)
    value.Font = Enum.Font.GothamBlack
    value.TextSize = 11
    value.TextWrapped = true
    value.AutoButtonColor = true
    value.Active = true
    value.Selectable = true
    value.Parent = parent
    corner(value, 13)
    stroke(value, 0.52)
    return value
end

local emoteButton = button(
    root,
    "EmoteButton",
    "EMOTES",
    UDim2.fromScale(0.11, 0.06),
    UDim2.fromScale(0.74, 0.02)
)

local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.BackgroundColor3 = Color3.fromRGB(3, 4, 8)
backdrop.BackgroundTransparency = 0.30
backdrop.Visible = false
backdrop.Selectable = false
backdrop.Parent = root

local wheel = Instance.new("Frame")
wheel.Name = "EmoteWheel"
wheel.Size = UDim2.fromScale(0.55, 0.62)
wheel.Position = UDim2.fromScale(0.50, 0.49)
wheel.AnchorPoint = Vector2.new(0.5, 0.5)
wheel.BackgroundColor3 = Color3.fromRGB(9, 11, 16)
wheel.BackgroundTransparency = 0.04
wheel.Visible = false
wheel.Parent = root
corner(wheel, 26)
stroke(wheel, 0.35)

local center = Instance.new("Frame")
center.Size = UDim2.fromScale(0.31, 0.31)
center.Position = UDim2.fromScale(0.50, 0.50)
center.AnchorPoint = Vector2.new(0.5, 0.5)
center.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
center.Parent = wheel
corner(center, 100)
stroke(center, 0.72)

local centerTitle = Instance.new("TextLabel")
centerTitle.Size = UDim2.fromScale(0.88, 0.36)
centerTitle.Position = UDim2.fromScale(0.06, 0.17)
centerTitle.BackgroundTransparency = 1
centerTitle.Text = "EMOTES"
centerTitle.TextColor3 = Color3.fromRGB(239, 240, 246)
centerTitle.Font = Enum.Font.GothamBlack
centerTitle.TextScaled = true
centerTitle.Parent = center

local centerHint = Instance.new("TextLabel")
centerHint.Size = UDim2.fromScale(0.86, 0.22)
centerHint.Position = UDim2.fromScale(0.07, 0.59)
centerHint.BackgroundTransparency = 1
centerHint.Text = "TAP TO PLAY"
centerHint.TextColor3 = Color3.fromRGB(151, 154, 170)
centerHint.Font = Enum.Font.GothamBold
centerHint.TextSize = 9
centerHint.Parent = center

local currentWheel = {
    "emote_001",
    "emote_002",
    "emote_003",
    "emote_004",
    "emote_005"
}

for index = 1, #currentWheel do
    local angle = math.rad(-90 + (index - 1) * 72)
    local x = 0.50 + math.cos(angle) * 0.40
    local y = 0.50 + math.sin(angle) * 0.40
    local id = currentWheel[index]
    local info = definitions[id]

    button(
        wheel,
        "Slot" .. tostring(index),
        info and tostring(index) .. "\n" .. info.Name or tostring(index),
        UDim2.fromScale(0.25, 0.20),
        UDim2.fromScale(x, y)
    ).Activated:Connect(function()
        actionRemote:FireServer("Start", {Id = id})
        wheel.Visible = false
        backdrop.Visible = false
        player:SetAttribute("CCHUD_EmoteWheelOpen", false)
    end)
end

type JointSet = {
    Root: Motor6D?,
    Waist: Motor6D?,
    Neck: Motor6D?,
    LeftShoulder: Motor6D?,
    RightShoulder: Motor6D?,
    LeftHip: Motor6D?,
    RightHip: Motor6D?
}

type ActiveEmote = {
    id: string,
    started: number,
    duration: number,
    loop: boolean,
    joints: JointSet
}

local activeEmote: {[Model]: ActiveEmote} = {}
local movementConnection: RBXScriptConnection?

local function findJoint(character: Model, names: {string}): Motor6D?
    for _, name in ipairs(names) do
        local joint = character:FindFirstChild(name, true)
        if joint and joint:IsA("Motor6D") then
            return joint
        end
    end

    return nil
end

local function jointsOf(character: Model): JointSet
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

local function applyPose(data: ActiveEmote, pose: {[string]: CFrame})
    for name, joint in pairs(data.joints) do
        if joint and joint.Parent then
            joint.Transform = pose[name] or CFrame.identity
        end
    end
end

local function clearPose(data: ActiveEmote)
    applyPose(data, {})
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
    end

    if id == "emote_002" then
        local lift = math.sin(math.clamp(t, 0, 1) * math.pi)
        return {
            Waist = CFrame.Angles(0, -0.12 * lift, 0),
            Neck = CFrame.Angles(0, 0, -0.10 * lift),
            RightShoulder = CFrame.Angles(-0.95 * lift, 0.08 * lift, 0.48 * lift),
            LeftShoulder = CFrame.Angles(0.08 * lift, 0, -0.18 * lift)
        }
    end

    if id == "emote_003" then
        return {
            Waist = CFrame.Angles(-0.10 + 0.05 * wave, 0.14 * wave, 0),
            LeftShoulder = CFrame.Angles(-0.92 + 0.20 * wave, 0, -0.42 * wave2),
            RightShoulder = CFrame.Angles(-0.92 - 0.20 * wave, 0, 0.42 * wave2),
            LeftHip = CFrame.Angles(0.15 * wave, 0, 0),
            RightHip = CFrame.Angles(-0.15 * wave, 0, 0)
        }
    end

    if id == "emote_004" then
        return {
            Waist = CFrame.Angles(0.04, 0.32 * wave, 0.06 * wave),
            Neck = CFrame.Angles(0, -0.24 * wave, 0),
            LeftShoulder = CFrame.Angles(0.18 * wave, 0, 0.22),
            RightShoulder = CFrame.Angles(-0.18 * wave, 0, -0.64),
            Root = CFrame.Angles(0, 0.10 * wave, 0)
        }
    end

    local progress = math.clamp(t / 3.1, 0, 1)
    local snap = math.clamp((progress - 0.42) / 0.16, 0, 1)

    return {
        Waist = CFrame.Angles(-0.06 * snap, -0.24 * snap, 0),
        Neck = CFrame.Angles(0, 0.18 * snap, 0),
        LeftShoulder = CFrame.Angles(-0.52 * snap, 0, -0.24 * snap),
        RightShoulder = CFrame.Angles(-0.76 * snap, 0, 0.48 * snap),
        Root = CFrame.Angles(0, 0.20 * snap, 0)
    }
end

local function stopModel(model: Model, notifyServer: boolean)
    local data = activeEmote[model]
    if data then
        clearPose(data)
        activeEmote[model] = nil
    end

    if notifyServer and model == player.Character then
        actionRemote:FireServer("Stop", {})
    end
end

local function stopLocal()
    local character = player.Character
    if character then
        stopModel(character, true)
    end
end

local function bindMovementInterrupt(character: Model)
    if movementConnection then
        movementConnection:Disconnect()
        movementConnection = nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local function interrupt()
        if activeEmote[character] then
            stopLocal()
        end
    end

    movementConnection = humanoid.Running:Connect(function(speed)
        if speed > 0.08 then
            interrupt()
        end
    end)

    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping
            or newState == Enum.HumanoidStateType.Freefall
            or newState == Enum.HumanoidStateType.Climbing
            or newState == Enum.HumanoidStateType.Swimming then
            interrupt()
        end
    end)

    humanoid.Died:Connect(interrupt)
end

local function menuBlocked(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function closeOtherInterfaces()
    local function hide(guiName: string, panelName: string)
        local otherGui = playerGui:FindFirstChild(guiName)
        local panel = otherGui and otherGui:FindFirstChild(panelName)

        if panel and panel:IsA("GuiObject") then
            panel.Visible = false
        end
    end

    hide("CursedCollisionAccountUI", "AccountPanel")
    hide("CursedCollisionCharacterUI", "CharacterPanel")
    hide("CursedCollisionOwnerUI", "OwnerPanel")

    player:SetAttribute("CCHUD_MenuOpen", false)
    player:SetAttribute("CCHUD_CharacterMenuOpen", false)
    player:SetAttribute("CCHUD_OwnerPanelOpen", false)
end

local function closeWheel()
    wheel.Visible = false
    backdrop.Visible = false
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
end

local function openWheel()
    if menuBlocked() then
        return
    end

    closeOtherInterfaces()
    wheel.Visible = true
    backdrop.Visible = true
    player:SetAttribute("CCHUD_EmoteWheelOpen", true)
end

emoteButton.Activated:Connect(function()
    if wheel.Visible then
        closeWheel()
    else
        openWheel()
    end
end)

backdrop.Activated:Connect(closeWheel)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.B then
        if wheel.Visible then
            closeWheel()
        else
            openWheel()
        end
        return
    end

    if input.KeyCode == Enum.KeyCode.Space
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        stopLocal()
    end
end)

player.CharacterAdded:Connect(function(character)
    stopLocal()
    closeWheel()
    bindMovementInterrupt(character)
end)

bindMovementInterrupt(player.Character or Instance.new("Model"))

combatFX.OnClientEvent:Connect(function(kind, _, payload)
    if not payload then
        return
    end

    if kind == "Hit"
        or kind == "BlockImpact"
        or kind == "PerfectBlock" then
        local actor = payload.actor
        if actor and actor:IsA("Model") and actor == player.Character then
            stopLocal()
        end
    end

    if kind == "CombatAction" then
        local actor = payload.actor
        if actor and actor:IsA("Model") and actor == player.Character then
            local action = tostring(payload.action or "")
            if action ~= "Emote" then
                if action == "M1Start"
                    or action == "SkillStart"
                    or action == "SpecialStart"
                    or action == "Dash"
                    or action == "BlockStart" then
                    stopLocal()
                end
            end
        end
    end
end)

eventRemote.OnClientEvent:Connect(function(event: string, payload: any)
    if type(payload) ~= "table" then
        return
    end

    local actor = Players:GetPlayerByUserId(tonumber(payload.UserId) or -1)
    local model = actor and actor.Character

    if event == "Play" then
        local info = definitions[payload.Id]
        if model and info then
            stopModel(model, false)
            activeEmote[model] = {
                id = info.Id,
                started = os.clock(),
                duration = info.Duration,
                loop = info.Loop,
                joints = jointsOf(model)
            }
        end
    elseif event == "Stop" then
        if model then
            stopModel(model, false)
        end
    end
end)

local renderBound = "CursedCollision_Emotes_Render"

RunService:BindToRenderStep(
    renderBound,
    Enum.RenderPriority.Last.Value,
    function()
        for model, data in pairs(activeEmote) do
            if not model.Parent then
                activeEmote[model] = nil
                continue
            end

            local elapsed = os.clock() - data.started

            if elapsed >= data.duration then
                if data.loop then
                    data.started = os.clock()
                    elapsed = 0
                else
                    if model == player.Character then
                        actionRemote:FireServer("Stop", {})
                    end
                    stopModel(model, false)
                    continue
                end
            end

            applyPose(data, poseFor(data.id, elapsed))
        end
    end
)

return nil
