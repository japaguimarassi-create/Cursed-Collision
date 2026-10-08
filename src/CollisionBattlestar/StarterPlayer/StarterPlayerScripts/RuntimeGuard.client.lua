--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("CollisionBattlestarRuntimeGuard")
if existing then
    existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CollisionBattlestarRuntimeGuard"
gui.DisplayOrder = 1000
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 0, 86)
frame.Position = UDim2.fromScale(0, 0)
frame.BackgroundColor3 = Color3.fromRGB(9, 12, 18)
frame.BackgroundTransparency = 0.06
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -32, 0, 32)
title.Position = UDim2.fromOffset(16, 10)
title.BackgroundTransparency = 1
title.Text = "COLLISION BATTLESTAR"
title.TextColor3 = Color3.fromRGB(240, 243, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -32, 0, 26)
status.Position = UDim2.fromOffset(16, 44)
status.BackgroundTransparency = 1
status.Text = "STARTING RUNTIME..."
status.TextColor3 = Color3.fromRGB(174, 185, 205)
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local function update()
    local hud = playerGui:FindFirstChild("CollisionBattlestarHUD")
    local worldReady = workspace:GetAttribute("CBS_WorldReady") == true
    local serverError = workspace:GetAttribute("CBS_ServerBootError")

    if hud then
        gui:Destroy()
        return true
    end

    if serverError then
        status.Text = "SERVER: " .. tostring(serverError)
        status.TextColor3 = Color3.fromRGB(255, 105, 105)
    elseif worldReady then
        status.Text = "WORLD READY • LOADING HUD..."
        status.TextColor3 = Color3.fromRGB(115, 220, 145)
    else
        status.Text = "WAITING FOR SERVER WORLD..."
        status.TextColor3 = Color3.fromRGB(174, 185, 205)
    end

    return false
end

local cameraConnection = RunService.PreRender:Connect(function()
    local camera = workspace.CurrentCamera
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if camera and humanoid and camera.CameraSubject ~= humanoid then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
    end
end)

for _ = 1, 60 do
    if update() then
        cameraConnection:Disconnect()
        return
    end

    task.wait(0.5)
end

cameraConnection:Disconnect()

if gui.Parent then
    gui:Destroy()
end
