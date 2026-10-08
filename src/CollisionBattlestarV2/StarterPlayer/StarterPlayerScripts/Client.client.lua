--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Network = require(ReplicatedStorage.Shared.Network)
local HUD = require(script.Parent.HUD)
local FX = require(script.Parent.FX)
local Audio = require(script.Parent.Audio)

local player = Players.LocalPlayer

local folder
for _ = 1, 20 do
    folder = ReplicatedStorage:FindFirstChild("CBS2_Remotes")
    if folder then
        break
    end
    task.wait(0.25)
end

local remotes = Network.wait(8)
if not remotes then
    task.wait(2)
    remotes = Network.wait(8)
end

if not remotes then
    local playerGui = player:WaitForChild("PlayerGui")
    local message = Instance.new("ScreenGui")
    message.Name = "CBS2_BootError"
    message.ResetOnSpawn = false
    message.Parent = playerGui

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -30, 0, 60)
    text.Position = UDim2.new(0, 15, 0.5, -30)
    text.BackgroundTransparency = 0.15
    text.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
    text.TextColor3 = Color3.fromRGB(255, 105, 105)
    text.Text = "SERVER CONNECTION FAILED"
    text.Font = Enum.Font.GothamBold
    text.TextSize = 18
    text.Parent = message
    return
end

local hud = HUD.new(remotes)
local fx = FX.new(remotes)
local audio = Audio.new(remotes)

fx:Start()
audio:Start()

local function recoverCamera()
    local camera = workspace.CurrentCamera
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if camera and humanoid then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
    end
end

player.CharacterAdded:Connect(function()
    task.defer(recoverCamera)
end)

task.spawn(function()
    for _ = 1, 40 do
        recoverCamera()
        if player:GetAttribute("CBS_PlayerReady") == true then
            break
        end
        task.wait(0.25)
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        remotes.Combat:FireServer({action = "Attack"})
    elseif input.KeyCode == Enum.KeyCode.Q then
        local camera = workspace.CurrentCamera
        local look = camera and camera.CFrame.LookVector or Vector3.zAxis
        remotes.Combat:FireServer({
            action = "Dash",
            direction = Vector3.new(look.X, 0, look.Z),
        })
    end
end)

remotes.State:FireServer({action = "RequestState"})
