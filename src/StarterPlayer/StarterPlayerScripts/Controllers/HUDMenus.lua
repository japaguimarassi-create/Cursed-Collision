--!strict

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local Emotes = require(ReplicatedStorage.Emotes.EmoteDefinitions)
local Theme = require(script.Parent.HUDTheme)
local Widgets = require(script.Parent.HUDWidgets)

local player = Players.LocalPlayer
local Menus = {}
Menus.__index = Menus

local function panel(root: Frame, title: string): (Frame, TextButton)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(0.90, 0.84)
    frame.Position = UDim2.fromScale(0.50, 0.53)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Theme.Colors.Panel
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = root
    Widgets.Corner(frame, Theme.Radius.Large)
    Widgets.Stroke(frame, 0.45)

    local titleLabel = Widgets.Label(frame, title, UDim2.fromScale(0.72, 0.08), UDim2.fromScale(0.05, 0.025), 18)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local close = Widgets.Button(frame, "Close", "X")
    close.Size = UDim2.fromScale(0.08, 0.08)
    close.Position = UDim2.fromScale(0.90, 0.025)

    return frame, close
end

local function scroll(parent: Instance): ScrollingFrame
    local area = Instance.new("ScrollingFrame")
    area.Size = UDim2.fromScale(0.90, 0.78)
    area.Position = UDim2.fromScale(0.05, 0.14)
    area.BackgroundTransparency = 1
    area.BorderSizePixel = 0
    area.ScrollBarThickness = 4
    area.AutomaticCanvasSize = Enum.AutomaticSize.Y
    area.CanvasSize = UDim2.new()
    area.Parent = parent
    return area
end

local function setAttributes(name: string, open: boolean)
    player:SetAttribute("CCHUD_MenuOpen", open)
    player:SetAttribute("CCHUD_CharacterMenuOpen", open and name == "Characters")
    player:SetAttribute("CCHUD_EmoteWheelOpen", open and name == "Emotes")
    player:SetAttribute("CCHUD_SettingsOpen", open and name == "Settings")
end

function Menus.new(): any
    local gui = Instance.new("ScreenGui")
    gui.Name = "CursedCollisionMenuHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 20
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = player:WaitForChild("PlayerGui")

    local root = Instance.new("Frame")
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = gui

    local dim = Widgets.Dim(root)

    local characterPanel, characterClose = panel(root, "CHARACTER SELECT")
    local characterList = scroll(characterPanel)
    local characterGrid = Instance.new("UIGridLayout")
    characterGrid.CellSize = UDim2.new(0.31, 0, 0, 58)
    characterGrid.CellPadding = UDim2.new(0.018, 0, 0, 10)
    characterGrid.Parent = characterList

    local characterIds = {}
    for id in pairs(Definitions) do
        table.insert(characterIds, id)
    end
    table.sort(characterIds)

    local emotePanel, emoteClose = panel(root, "EMOTES")
    local emoteList = scroll(emotePanel)
    local emoteGrid = Instance.new("UIGridLayout")
    emoteGrid.CellSize = UDim2.new(0.31, 0, 0, 72)
    emoteGrid.CellPadding = UDim2.new(0.018, 0, 0, 10)
    emoteGrid.Parent = emoteList

    local emoteIds = {}
    for id in pairs(Emotes) do
        table.insert(emoteIds, id)
    end
    table.sort(emoteIds)

    local menuPanel, menuClose = panel(root, "MENU")
    local menuList = Instance.new("Frame")
    menuList.Size = UDim2.fromScale(0.78, 0.68)
    menuList.Position = UDim2.fromScale(0.11, 0.17)
    menuList.BackgroundTransparency = 1
    menuList.Parent = menuPanel

    local menuLayout = Instance.new("UIListLayout")
    menuLayout.Padding = UDim.new(0, 12)
    menuLayout.Parent = menuList

    local settingsPanel, settingsClose = panel(root, "SETTINGS")
    local settingsList = Instance.new("Frame")
    settingsList.Size = UDim2.fromScale(0.78, 0.68)
    settingsList.Position = UDim2.fromScale(0.11, 0.17)
    settingsList.BackgroundTransparency = 1
    settingsList.Parent = settingsPanel

    local controller: any

    local function close()
        controller:Close()
    end

    for _, id in ipairs(characterIds) do
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Parent = characterList
        local button = Widgets.Button(holder, id, tostring(Definitions[id].Name or id))
        button.TextSize = 10
        button.Activated:Connect(function()
            local folder = ReplicatedStorage:FindFirstChild("Remotes")
            local remote = folder and folder:FindFirstChild("CombatAction")
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer("SelectCharacter", {Id = id})
            end
            close()
        end)
    end

    for _, id in ipairs(emoteIds) do
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Parent = emoteList
        local button = Widgets.Button(holder, id, tostring(Emotes[id].Name or id))
        button.TextSize = 10
        button.Activated:Connect(function()
            local folder = ReplicatedStorage:FindFirstChild("Remotes")
            local remote = folder and folder:FindFirstChild("EmoteAction")
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer("Start", {Id = id})
            end
            close()
        end)
    end

    local settings = Widgets.Button(menuList, "Settings", "SETTINGS")
    settings.Size = UDim2.fromScale(1, 0.18)
    settings.Activated:Connect(function()
        controller:Open("Settings")
    end)

    local emotes = Widgets.Button(menuList, "Emotes", "EMOTES")
    emotes.Size = UDim2.fromScale(1, 0.18)
    emotes.Activated:Connect(function()
        controller:Open("Emotes")
    end)

    local characters = Widgets.Button(menuList, "Characters", "CHARACTERS")
    characters.Size = UDim2.fromScale(1, 0.18)
    characters.Activated:Connect(function()
        controller:Open("Characters")
    end)

    local returnButton = Widgets.Button(menuList, "Return", "RETURN TO GAME")
    returnButton.Size = UDim2.fromScale(1, 0.18)
    returnButton.Activated:Connect(close)

    local function setting(textValue: string, attribute: string, defaultValue: boolean)
        local button = Widgets.Button(settingsList, attribute, textValue)
        button.Size = UDim2.fromScale(1, 0.18)

        local function refresh()
            local value = player:GetAttribute(attribute)
            if value == nil then
                value = defaultValue
                player:SetAttribute(attribute, value)
            end
            button.Text = textValue .. ": " .. (value and "ON" or "OFF")
        end

        button.Activated:Connect(function()
            local value = player:GetAttribute(attribute)
            if value == nil then
                value = defaultValue
            end
            player:SetAttribute(attribute, not value)
            refresh()
        end)

        refresh()
    end

    setting("AUTO SPRINT", "CCSettingAutoSprint", false)
    setting("CAMERA SHAKE", "CCSettingCameraShake", true)
    setting("REDUCED MOTION", "CCSettingReducedMotion", false)

    characterClose.Activated:Connect(close)
    emoteClose.Activated:Connect(close)
    menuClose.Activated:Connect(close)
    settingsClose.Activated:Connect(function()
        controller:Open("Menu")
    end)

    dim.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            close()
        end
    end)

    controller = setmetatable({
        Gui = gui,
        Root = root,
        Dim = dim,
        Panels = {
            Characters = characterPanel,
            Emotes = emotePanel,
            Menu = menuPanel,
            Settings = settingsPanel
        },
        First = {
            Characters = characterList:FindFirstChildWhichIsA("TextButton", true),
            Emotes = emoteList:FindFirstChildWhichIsA("TextButton", true),
            Menu = settings,
            Settings = settingsList:FindFirstChildWhichIsA("TextButton")
        }
    }, Menus)

    controller:Close()
    return controller
end

function Menus:Open(name: string)
    for panelName, frame in pairs(self.Panels) do
        frame.Visible = panelName == name
    end

    self.Dim.Visible = true
    self.Root.Visible = true
    setAttributes(name, true)

    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.AutoSelectGuiEnabled = true
        local first = self.First[name]
        if first and first:IsA("GuiButton") then
            GuiService.SelectedObject = first
        end
    end
end

function Menus:Close()
    for _, frame in pairs(self.Panels) do
        frame.Visible = false
    end

    self.Dim.Visible = false
    self.Root.Visible = false
    setAttributes("", false)

    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.SelectedObject = nil
    end
end

return Menus
