--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local action = remotes and remotes:WaitForChild("EmoteAction", 15)
if not action then return end

local definitions = require(ReplicatedStorage.Emotes.EmoteDefinitions)

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionHUD_Emotes"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.DisplayOrder = 30
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1,1)
root.BackgroundTransparency = 1
root.Parent = gui

local openButton = Instance.new("TextButton")
openButton.Size = UDim2.fromScale(0.065,0.052)
openButton.Position = UDim2.fromScale(0.105,0.018)
openButton.Text = "☺"
openButton.Font = Enum.Font.GothamBlack
openButton.TextSize = 17
openButton.TextColor3 = Color3.fromRGB(240,241,246)
openButton.BackgroundColor3 = Color3.fromRGB(18,21,29)
openButton.BorderSizePixel = 0
openButton.Selectable = true
openButton.Parent = root
local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(0,12)
oc.Parent = openButton

local backdrop = Instance.new("TextButton")
backdrop.Size = UDim2.fromScale(1,1)
backdrop.BackgroundColor3 = Color3.fromRGB(3,4,7)
backdrop.BackgroundTransparency = 0.32
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.Parent = root

local wheel = Instance.new("Frame")
wheel.Size = UDim2.fromScale(0.54,0.62)
wheel.Position = UDim2.fromScale(0.50,0.50)
wheel.AnchorPoint = Vector2.new(0.5,0.5)
wheel.BackgroundColor3 = Color3.fromRGB(11,13,19)
wheel.BorderSizePixel = 0
wheel.Visible = false
wheel.Parent = root
local wc = Instance.new("UICorner")
wc.CornerRadius = UDim.new(0,22)
wc.Parent = wheel
local ws = Instance.new("UIStroke")
ws.Color = Color3.fromRGB(157,117,255)
ws.Transparency = 0.24
ws.Thickness = 1.4
ws.Parent = wheel

local center = Instance.new("Frame")
center.Size = UDim2.fromScale(0.28,0.28)
center.Position = UDim2.fromScale(0.50,0.50)
center.AnchorPoint = Vector2.new(0.5,0.5)
center.BackgroundColor3 = Color3.fromRGB(18,21,29)
center.Parent = wheel
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(1,0)
cc.Parent = center

local t = Instance.new("TextLabel")
t.Size = UDim2.fromScale(0.90,0.40)
t.Position = UDim2.fromScale(0.05,0.18)
t.BackgroundTransparency = 1
t.Text = "EMOTES"
t.Font = Enum.Font.GothamBlack
t.TextSize = 14
t.TextColor3 = Color3.fromRGB(240,241,246)
t.Parent = center

local slots: {[number]: TextButton} = {}
local ids = {"emote_001","emote_002","emote_003","emote_004","emote_005"}

for index,id in ipairs(ids) do
    local angle = math.rad(-90 + (index-1)*72)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromScale(0.24,0.18)
    b.Position = UDim2.fromScale(0.50+math.cos(angle)*0.39,0.50+math.sin(angle)*0.39)
    b.AnchorPoint = Vector2.new(0.5,0.5)
    b.Text = tostring(index) .. "\n" .. tostring(definitions[id] and definitions[id].Name or id)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.TextWrapped = true
    b.TextColor3 = Color3.fromRGB(240,241,246)
    b.BackgroundColor3 = Color3.fromRGB(22,25,34)
    b.BorderSizePixel = 0
    b.Selectable = true
    b.Parent = wheel
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,12)
    c.Parent = b
    slots[index] = b

    b.Activated:Connect(function()
        action:FireServer("Start", {Id=id})
        wheel.Visible = false
        backdrop.Visible = false
        player:SetAttribute("CCHUD_EmoteWheelOpen", false)
    end)
end

local function closeWheel()
    wheel.Visible = false
    backdrop.Visible = false
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
end

local function openWheel()
    player:SetAttribute("CCHUD_MenuOpen", false)
    player:SetAttribute("CCHUD_CharacterMenuOpen", false)
    player:SetAttribute("CCHUD_SettingsOpen", false)
    player:SetAttribute("CCHUD_EmoteWheelOpen", true)
    wheel.Visible = true
    backdrop.Visible = true
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = slots[1]
    end
end

openButton.Activated:Connect(function()
    if wheel.Visible then closeWheel() else openWheel() end
end)
backdrop.Activated:Connect(closeWheel)

player:GetAttributeChangedSignal("CCHUD_EmoteWheelOpen"):Connect(function()
    if player:GetAttribute("CCHUD_EmoteWheelOpen") == true then
        wheel.Visible = true
        backdrop.Visible = true
    else
        wheel.Visible = false
        backdrop.Visible = false
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.B then
        if wheel.Visible then closeWheel() else openWheel() end
    elseif input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if wheel.Visible then return end
        if player:GetAttribute("CCHUD_EmoteActive") == true then
            action:FireServer("Stop", {})
        end
    end
end)
