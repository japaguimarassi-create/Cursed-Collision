local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local existing = playerGui:FindFirstChild("StealAnAnimalBootstrapHUD")
if existing then
    existing:Destroy()
end

local COLORS = {
    Background = Color3.fromRGB(22, 33, 25),
    Panel = Color3.fromRGB(42, 62, 44),
    Gold = Color3.fromRGB(255, 207, 97),
    Text = Color3.fromRGB(255, 249, 229),
    Muted = Color3.fromRGB(209, 222, 202),
    Green = Color3.fromRGB(113, 215, 132),
    Orange = Color3.fromRGB(255, 174, 87),
    Red = Color3.fromRGB(248, 112, 103),
}

local gui = Instance.new("ScreenGui")
gui.Name = "StealAnAnimalBootstrapHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 2000
gui.IgnoreGuiInset = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "StatusCard"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, 14)
card.Size = UDim2.new(0.92, 0, 0, 148)
card.BackgroundColor3 = COLORS.Background
card.BorderSizePixel = 0
card.Parent = gui
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(250, 148)
sizeConstraint.MaxSize = Vector2.new(520, 148)
sizeConstraint.Parent = card
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = card
local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.Gold
stroke.Thickness = 2
stroke.Transparency = 0.15
stroke.Parent = card
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(COLORS.Panel, COLORS.Background)
gradient.Rotation = 90
gradient.Parent = card

local function makeLabel(name, size, position, text, font, textSize, color)
    local object = Instance.new("TextLabel")
    object.Name = name
    object.BackgroundTransparency = 1
    object.Position = position
    object.Size = size
    object.Font = font
    object.Text = text
    object.TextColor3 = color
    object.TextSize = textSize
    object.TextWrapped = true
    object.TextScaled = true
    object.Parent = card
    return object
end

local title = makeLabel("CoreTitle", UDim2.new(1, -28, 0, 30), UDim2.new(0, 14, 0, 7),
    "STEAL AN ANIMAL • CORE BOOT", Enum.Font.GothamBlack, 17, COLORS.Gold)
local state = makeLabel("CoreState", UDim2.new(1, -28, 0, 27), UDim2.new(0, 14, 0, 40),
    "Starting diagnostics...", Enum.Font.GothamBold, 13, COLORS.Text)
local details = makeLabel("CoreDetails", UDim2.new(1, -28, 0, 37), UDim2.new(0, 14, 0, 69),
    "Checking world, remotes and interface.", Enum.Font.Gotham, 11, COLORS.Muted)

local continueButton = Instance.new("TextButton")
continueButton.Name = "ContinueToFallback"
continueButton.AnchorPoint = Vector2.new(1, 1)
continueButton.Position = UDim2.new(1, -12, 1, -8)
continueButton.Size = UDim2.new(0, 168, 0, 31)
continueButton.BackgroundColor3 = COLORS.Orange
continueButton.BorderSizePixel = 0
continueButton.Font = Enum.Font.GothamBold
continueButton.Text = "CONTINUE TO GAME"
continueButton.TextColor3 = Color3.fromRGB(35, 35, 30)
continueButton.TextSize = 12
continueButton.Visible = false
continueButton.Parent = card
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = continueButton

local dismissed = false
continueButton.Activated:Connect(function()
    dismissed = true
    gui.Enabled = false
    local mainGui = playerGui:FindFirstChild("StealAnAnimalHUD")
    local mapOverlay = mainGui and mainGui:FindFirstChild("MapLoadDiagnostic")
    if mapOverlay then
        mapOverlay.Visible = false
    end
end)

local function sendProbe(phase)
    local core = ReplicatedStorage:FindFirstChild("StealAnimalCore")
    local diagnostics = core and core:FindFirstChild("Diagnostics")
    local remote = diagnostics and diagnostics:FindFirstChild("ClientProbeReport")
    local camera = Workspace.CurrentCamera
    local mainGui = playerGui:FindFirstChild("StealAnAnimalHUD")
    local activeRoot = Workspace:FindFirstChild("StealAnAnimal")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function()
            remote:FireServer({
                phase = phase,
                hudPresent = gui.Parent == playerGui,
                mainHudReady = mainGui ~= nil and mainGui:GetAttribute("CoreBootstrapComplete") == true,
                activeRootPresent = activeRoot ~= nil,
                mapReady = activeRoot ~= nil and activeRoot:GetAttribute("MapReady") == true,
                remoteFolderPresent = ReplicatedStorage:FindFirstChild("RoubeAnimalRemotes") ~= nil,
                viewportWidth = camera and camera.ViewportSize.X or 0,
                viewportHeight = camera and camera.ViewportSize.Y or 0,
            })
        end)
    end
end

local startedAt = os.clock()
local function update()
    if dismissed then
        return
    end
    local core = ReplicatedStorage:FindFirstChild("StealAnimalCore")
    local bootState = core and core:GetAttribute("BootState") or "Bootstrapping"
    local worldState = core and core:GetAttribute("WorldState") or "Bootstrapping"
    local buildTag = core and core:GetAttribute("BuildTag") or "Core pending"
    local root = Workspace:FindFirstChild("StealAnAnimal")
    local mainGui = playerGui:FindFirstChild("StealAnAnimalHUD")
    local mainHudReady = mainGui ~= nil and mainGui:GetAttribute("CoreBootstrapComplete") == true
    local worldReady = root ~= nil and root:GetAttribute("MapReady") == true and worldState == "Ready"

    if worldReady and bootState == "Ready" and mainHudReady then
        gui.Enabled = false
        sendProbe("HudReady")
        return
    end

    gui.Enabled = true
    continueButton.Visible = bootState == "Degraded" or worldState == "Degraded"
        or (os.clock() - startedAt > 35 and not mainHudReady)
    if worldState == "Building" then
        title.Text = "STEAL AN ANIMAL • BUILDING WORLD"
        state.Text = "CORE ONLINE — generating farms, biomes and guardians"
        state.TextColor3 = COLORS.Gold
    elseif worldState == "Ready" and bootState == "Ready" then
        title.Text = "STEAL AN ANIMAL • FINALIZING HUD"
        state.Text = mainHudReady and "WORLD READY" or "Waiting for the main interface..."
        state.TextColor3 = COLORS.Green
    elseif bootState == "Degraded" or worldState == "Degraded" then
        title.Text = "STEAL AN ANIMAL • SAFE MODE"
        state.Text = "A subsystem did not pass startup checks."
        state.TextColor3 = COLORS.Red
    else
        title.Text = "STEAL AN ANIMAL • CORE BOOT"
        state.Text = "Preparing fallback, remotes and diagnostics..."
        state.TextColor3 = COLORS.Text
    end

    local lastFailure = core and core:GetAttribute("LastFailure")
    local counts = root and ("Farms " .. tostring(root:GetAttribute("BaseCount") or 0)
        .. "/8 • Biomes " .. tostring(root:GetAttribute("BiomeCount") or 0) .. "/6 • Animals "
        .. tostring(root:GetAttribute("AnimalCount") or 0) .. "/23") or "Fallback spawn is available while the world builds."
    details.Text = tostring(buildTag) .. "\n"
        .. (type(lastFailure) == "string" and lastFailure ~= "" and lastFailure or counts)
end

task.spawn(function()
    while not dismissed and gui.Parent do
        update()
        local core = ReplicatedStorage:FindFirstChild("StealAnimalCore")
        local mainGui = playerGui:FindFirstChild("StealAnAnimalHUD")
        if core and core:GetAttribute("BootState") == "Ready"
            and core:GetAttribute("WorldState") == "Ready"
            and mainGui and mainGui:GetAttribute("CoreBootstrapComplete") == true then
            sendProbe("HudReady")
            gui.Enabled = false
            break
        end
        task.wait(0.35)
    end
end)

task.spawn(function()
    task.wait(1)
    sendProbe("Bootstrap")
    task.wait(2)
    sendProbe("Refresh")
end)

player:GetAttributeChangedSignal("CoreBootstrapComplete"):Connect(function()
    sendProbe("HudReady")
    update()
end)
