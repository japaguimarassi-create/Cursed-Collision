--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Theme = require(script.Parent.HUDTheme)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local action = remotes and remotes:WaitForChild("EmoteAction", 15)
if not action then
    return
end

local Definitions = require(ReplicatedStorage.Emotes.EmoteDefinitions)

local gui = Theme.CreateGui("CursedCollisionHUD_Emotes", 70)
local root = Theme.Root(gui)
Theme.ResponsiveScale(root, 760, 0.72, 1.06)

local backdrop = Instance.new("TextButton")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Theme.Colors.Background
backdrop.BackgroundTransparency = 0.34
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.Parent = root

local wheel = Theme.Panel(root, "EmoteWheel", UDim2.fromScale(0.58, 0.64))
wheel.Visible = false

local title = Theme.Label(wheel, "Title", "EMOTES", UDim2.fromScale(0.40, 0.10), UDim2.fromScale(0.30, 0.08), 17)
title.Font = Enum.Font.GothamBlack

local center = Theme.Button(wheel, "Center", "CLOSE", UDim2.fromScale(0.22, 0.12), UDim2.fromScale(0.39, 0.58), 56)
local ids = {"emote_001", "emote_002", "emote_003", "emote_004", "emote_005"}

for index, id in ipairs(ids) do
    local angle = math.rad(-90 + (index - 1) * 72)
    local info = Definitions[id]
    local button = Theme.Button(
        wheel,
        "Slot" .. index,
        tostring(index) .. "\n" .. (info and info.Name or id),
        UDim2.fromScale(0.25, 0.18),
        UDim2.fromScale(0.50 + math.cos(angle) * 0.38, 0.50 + math.sin(angle) * 0.38),
        58
    )
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.TextSize = 9
    button.Activated:Connect(function()
        action:FireServer("Start", {Id = id})
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
    player:SetAttribute("CCHUD_OwnerPanelOpen", false)
    player:SetAttribute("CCHUD_EmoteWheelOpen", true)
    wheel.Visible = true
    backdrop.Visible = true

    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        local first = wheel:FindFirstChild("Slot1")
        if first and first:IsA("GuiButton") then
            GuiService.SelectedObject = first
        end
    end
end

center.Activated:Connect(closeWheel)
backdrop.Activated:Connect(closeWheel)

player:GetAttributeChangedSignal("CCHUD_EmoteWheelOpen"):Connect(function()
    if player:GetAttribute("CCHUD_EmoteWheelOpen") == true then
        openWheel()
    else
        closeWheel()
    end
end)

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
    end
end)
