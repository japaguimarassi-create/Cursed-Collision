--!strict
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
pcall(function()
    ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "CollisionBattlestarImmediateHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 60
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local scale = Instance.new("UIScale")
scale.Scale = 0.92
scale.Parent = gui

local chip = Instance.new("Frame")
chip.Size = UDim2.fromOffset(176, 34)
chip.Position = UDim2.fromScale(0.5, 0.02)
chip.AnchorPoint = Vector2.new(0.5, 0)
chip.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
chip.BackgroundTransparency = 0.08
chip.BorderSizePixel = 0
chip.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = chip

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(72, 82, 103)
stroke.Transparency = 0.24
stroke.Parent = chip

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.Text = "LOADING BATTLE SYSTEMS"
title.TextColor3 = Color3.fromRGB(245, 247, 252)
title.Font = Enum.Font.GothamBold
title.TextSize = 8
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = chip

local function resize()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local viewport = camera.ViewportSize
    scale.Scale = math.clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.68, 1.05)
end

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
resize()

task.spawn(function()
    while gui.Parent do
        RunService.Heartbeat:Wait()
        if player:GetAttribute("CollisionHUDReady") == true then
            TweenService:Create(chip, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.fromScale(0.5, -0.05),
                BackgroundTransparency = 1,
            }):Play()
            task.wait(0.2)
            if gui.Parent then
                gui:Destroy()
            end
            break
        end
    end
end)
