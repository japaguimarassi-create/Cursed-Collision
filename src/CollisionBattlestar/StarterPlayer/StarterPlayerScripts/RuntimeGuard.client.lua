--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
gui.Enabled = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 0, 78)
frame.Position = UDim2.fromScale(0, 0)
frame.BackgroundColor3 = Color3.fromRGB(9, 12, 18)
frame.BackgroundTransparency = 0.06
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -32, 0, 28)
title.Position = UDim2.fromOffset(16, 8)
title.BackgroundTransparency = 1
title.Text = "COLLISION BATTLESTAR"
title.TextColor3 = Color3.fromRGB(240, 243, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 19
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -32, 0, 24)
status.Position = UDim2.fromOffset(16, 38)
status.BackgroundTransparency = 1
status.Text = "STARTING RUNTIME..."
status.TextColor3 = Color3.fromRGB(174, 185, 205)
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local stateRemote
local remoteFolder = ReplicatedStorage:FindFirstChild("CollisionBattlestarRemotes")

if remoteFolder then
    local candidate = remoteFolder:FindFirstChild("State")
    if candidate and candidate:IsA("RemoteEvent") then
        stateRemote = candidate
    end
end

local function recoverCamera()
    local camera = workspace.CurrentCamera
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if camera and humanoid then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
    end
end

local function show(message: string, errorState: boolean?)
    gui.Enabled = true
    status.Text = message
    status.TextColor3 = errorState
        and Color3.fromRGB(255, 105, 105)
        or Color3.fromRGB(174, 185, 205)
    recoverCamera()
end

local function hide()
    local hud = playerGui:FindFirstChild("CollisionBattlestarHUD")
    if hud then
        gui.Enabled = false
    end
end

local function bindRemote(remote: RemoteEvent)
    remote.OnClientEvent:Connect(function(kind, payload)
        if kind == "RuntimeReloadStarted" then
            show("RUNTIME RECOVERY • RESTORING SYSTEMS...")
        elseif kind == "RuntimeReloaded" then
            show("RUNTIME RESTORED", false)
            task.delay(1.2, hide)
        elseif kind == "BootError" then
            local message = type(payload) == "table"
                and tostring(payload.message or "server boot failure")
                or "server boot failure"

            show("SERVER: " .. message, true)
        end
    end)
end

if stateRemote then
    bindRemote(stateRemote)
else
    task.spawn(function()
        for _ = 1, 20 do
            local folder = ReplicatedStorage:FindFirstChild("CollisionBattlestarRemotes")
            local remote = folder and folder:FindFirstChild("State")

            if remote and remote:IsA("RemoteEvent") then
                bindRemote(remote)
                break
            end

            task.wait(0.5)
        end
    end)
end

player.CharacterAdded:Connect(function()
    task.defer(recoverCamera)
end)

task.spawn(function()
    for _ = 1, 60 do
        recoverCamera()

        if playerGui:FindFirstChild("CollisionBattlestarHUD") then
            gui.Enabled = false
        elseif workspace:GetAttribute("CBS_ServerBootError") then
            show("SERVER: " .. tostring(workspace:GetAttribute("CBS_ServerBootError")), true)
        elseif workspace:GetAttribute("CBS_WorldReady") == true then
            show("WORLD READY • LOADING HUD...")
        end

        task.wait(0.5)
    end

    hide()
end)

