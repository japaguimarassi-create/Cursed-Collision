--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Theme = require(script.Parent.HUDTheme)

local player = Players.LocalPlayer
local gui = Theme.CreateGui("CursedCollisionHUD_Settings", 75)
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

local panel = Theme.Panel(root, "SettingsPanel", UDim2.fromScale(0.70, 0.68))
panel.Visible = false

local title = Theme.Label(panel, "Title", "SETTINGS", UDim2.fromScale(0.54, 0.08), UDim2.fromScale(0.05, 0.04), 20)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack

local close = Theme.Button(panel, "Close", "×", UDim2.fromOffset(52, 44), UDim2.fromScale(0.94, 0.04), 44)
close.AnchorPoint = Vector2.new(1, 0)
close.TextSize = 21

local list = Instance.new("Frame")
list.Size = UDim2.fromScale(0.88, 0.68)
list.Position = UDim2.fromScale(0.06, 0.18)
list.BackgroundTransparency = 1
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = list

local reducedEffects = false
local autoSprint = false

local effects = Theme.Button(list, "ReducedEffects", "REDUCED EFFECTS  •  OFF", UDim2.new(1, 0, 0, 62), UDim2.new(), 56)
effects.Activated:Connect(function()
    reducedEffects = not reducedEffects
    effects.Text = "REDUCED EFFECTS  •  " .. (reducedEffects and "ON" or "OFF")
    player:SetAttribute("CC_ReducedEffects", reducedEffects)
end)

local sprint = Theme.Button(list, "AutoSprint", "AUTO SPRINT  •  OFF", UDim2.new(1, 0, 0, 62), UDim2.new(), 56)
sprint.Activated:Connect(function()
    autoSprint = not autoSprint
    sprint.Text = "AUTO SPRINT  •  " .. (autoSprint and "ON" or "OFF")
    player:SetAttribute("CC_AutoSprint", autoSprint)
end)

local input = Theme.Label(list, "Input", "INPUT: " .. tostring(UserInputService.PreferredInput), UDim2.new(1, 0, 0, 62), UDim2.new(), 10)
input.TextColor3 = Theme.Colors.Muted

local function closePanel()
    panel.Visible = false
    backdrop.Visible = false
    player:SetAttribute("CCHUD_SettingsOpen", false)
end

local function openPanel()
    player:SetAttribute("CCHUD_MenuOpen", false)
    player:SetAttribute("CCHUD_CharacterMenuOpen", false)
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
    player:SetAttribute("CCHUD_OwnerPanelOpen", false)
    player:SetAttribute("CCHUD_SettingsOpen", true)
    panel.Visible = true
    backdrop.Visible = true

    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = effects
    end
end

close.Activated:Connect(closePanel)
backdrop.Activated:Connect(closePanel)

player:GetAttributeChangedSignal("CCHUD_SettingsOpen"):Connect(function()
    if player:GetAttribute("CCHUD_SettingsOpen") == true then
        openPanel()
    else
        closePanel()
    end
end)

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
    input.Text = "INPUT: " .. tostring(UserInputService.PreferredInput)
end)

UserInputService.InputBegan:Connect(function(inputObject, processed)
    if processed then
        return
    end
    if inputObject.KeyCode == Enum.KeyCode.ButtonSelect then
        if panel.Visible then
            closePanel()
        else
            openPanel()
        end
    end
end)
