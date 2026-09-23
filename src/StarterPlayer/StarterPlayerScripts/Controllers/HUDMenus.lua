--!strict

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local Emotes = require(ReplicatedStorage.Emotes.EmoteDefinitions)
local Theme = require(script.Parent.HUDTheme)
local Platform = require(script.Parent.HUDPlatform)
local Widgets = require(script.Parent.HUDWidgets)

local player = Players.LocalPlayer

export type MenuController = {
    Gui: ScreenGui,
    Root: Frame,
    Open: (self: MenuController, name: string) -> (),
    Close: (self: MenuController) -> (),
    Toggle: (self: MenuController, name: string) -> (),
    Destroy: (self: MenuController) -> ()
}

local MenuController = {}
MenuController.__index = MenuController

local function makePanel(root: Frame, title: string): (Frame, TextButton)
    local frame = Instance.new("Frame")
    frame.Name = title .. "Panel"
    frame.Size = UDim2.fromScale(0.90, 0.84)
    frame.Position = UDim2.fromScale(0.50, 0.53)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Theme.Colors.Panel
    frame.BackgroundTransparency = 0.04
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = root
    Widgets.Corner(frame, Theme.Radius.Large)
    Widgets.Stroke(frame, 0.45)

    local heading = Widgets.Label(frame, title, UDim2.fromScale(0.72, 0.08), UDim2.fromScale(0.05, 0.025), 18)
    heading.TextXAlignment = Enum.TextXAlignment.Left

    local close = Widgets.Button(frame, "Close", "X", Theme.Radius.Pill)
    close.Size = UDim2.fromScale(0.08, 0.08)
    close.Position = UDim2.fromScale(0.90, 0.025)

    return frame, close
end

local function makeScroll(parent: Instance): ScrollingFrame
    local area = Instance.new("ScrollingFrame")
    area.Size = UDim2.fromScale(0.90, 0.78)
    area.Position = UDim2.fromScale(0.05, 0.14)
    area.BackgroundTransparency = 1
    area.BorderSizePixel = 0
    area.ScrollBarThickness = 4
    area.ScrollBarImageTransparency = 0.35
    area.AutomaticCanvasSize = Enum.AutomaticSize.Y
    area.CanvasSize = UDim2.new()
    area.Parent = parent
    return area
end

local function setOpenAttributes(name: string, open: boolean)
    player:SetAttribute("CCHUD_MenuOpen", open)
    player:SetAttribute("CCHUD_CharacterMenuOpen", open and name == "Characters")
    player:SetAttribute("CCHUD_EmoteWheelOpen", open and name == "Emotes")
    player:SetAttribute("CCHUD_SettingsOpen", open and name == "Settings")
    player:SetAttribute("CCHUD_OwnerPanelOpen", open and name == "Owner")
end

local function selectFirst(button: GuiButton?)
    if Platform:IsGamepad() and button then
        GuiService.GuiNavigationEnabled = true
        GuiService.AutoSelectGuiEnabled = true
        GuiService.SelectedObject = button
    end
end

function MenuController.new(): MenuController
    local playerGui = player:WaitForChild("PlayerGui")

    local old = playerGui:FindFirstChild("CursedCollisionMenuHUD")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CursedCollisionMenuHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 20
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = gui

    local dim = Widgets.Dim(root)

    local characterPanel, characterClose = makePanel(root, "CHARACTER SELECT")
    local characterList = makeScroll(characterPanel)

    local characterGrid = Instance.new("UIGridLayout")
    characterGrid.CellSize = UDim2.new(0.31, 0, 0, 58)
    characterGrid.CellPadding = UDim2.new(0.018, 0, 0, 10)
    characterGrid.SortOrder = Enum.SortOrder.LayoutOrder
    characterGrid.Parent = characterList

    local characterButtons: {TextButton} = {}
    local sortedCharacters: {string} = {}
    for id in pairs(Definitions) do
        table.insert(sortedCharacters, id)
    end
    table.sort(sortedCharacters)

    local emotePanel, emoteClose = makePanel(root, "EMOTES")
    local emoteList = makeScroll(emotePanel)

    local emoteGrid = Instance.new("UIGridLayout")
    emoteGrid.CellSize = UDim2.new(0.31, 0, 0, 72)
    emoteGrid.CellPadding = UDim2.new(0.018, 0, 0, 10)
    emoteGrid.SortOrder = Enum.SortOrder.LayoutOrder
    emoteGrid.Parent = emoteList

    local emoteButtons: {TextButton} = {}

    local mainPanel, mainClose = makePanel(root, "MENU")
    local mainList = Instance.new("Frame")
    mainList.Size = UDim2.fromScale(0.78, 0.68)
    mainList.Position = UDim2.fromScale(0.11, 0.17)
    mainList.BackgroundTransparency = 1
    mainList.Parent = mainPanel

    local mainLayout = Instance.new("UIListLayout")
    mainLayout.Padding = UDim.new(0, 12)
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    mainLayout.Parent = mainList

    local settingsPanel, settingsClose = makePanel(root, "SETTINGS")
    local settingsList = Instance.new("Frame")
    settingsList.Size = UDim2.fromScale(0.78, 0.68)
    settingsList.Position = UDim2.fromScale(0.11, 0.17)
    settingsList.BackgroundTransparency = 1
    settingsList.Parent = settingsPanel

    local settingsLayout = Instance.new("UIListLayout")
    settingsLayout.Padding = UDim.new(0, 12)
    settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    settingsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    settingsLayout.Parent = settingsList

    local controller: any

    for _, id in ipairs(sortedCharacters) do
        local definition = Definitions[id]

        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Parent = characterList

        local button = Widgets.Button(holder, id, tostring(definition.Name or id))
        button.TextSize = 10
        button.Activated:Connect(function()
            local remotes = ReplicatedStorage:WaitForChild("Remotes")
            local combat = remotes:FindFirstChild("CombatAction")
            if combat and combat:IsA("RemoteEvent") then
                combat:FireServer("SelectCharacter", {Id = id})
            end
            controller:Close()
        end)

        table.insert(characterButtons, button)
    end

    local sortedEmotes: {string} = {}
    for id in pairs(Emotes) do
        table.insert(sortedEmotes, id)
    end
    table.sort(sortedEmotes)

    for _, id in ipairs(sortedEmotes) do
        local emote = Emotes[id]

        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Parent = emoteList

        local button = Widgets.Button(holder, id, tostring(emote.Name or id))
        button.TextSize = 10
        button.Activated:Connect(function()
            local remotes = ReplicatedStorage:WaitForChild("Remotes")
            local remote = remotes:FindFirstChild("EmoteAction")
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer("Start", {Id = id})
            end
            controller:Close()
        end)

        table.insert(emoteButtons, button)
    end

    local menuSettings = Widgets.Button(mainList, "Settings", "SETTINGS")
    menuSettings.Size = UDim2.fromScale(1, 0.16)
    menuSettings.Activated:Connect(function()
        controller:Open("Settings")
    end)

    local menuEmotes = Widgets.Button(mainList, "Emotes", "EMOTES")
    menuEmotes.Size = UDim2.fromScale(1, 0.16)
    menuEmotes.Activated:Connect(function()
        controller:Open("Emotes")
    end)

    local menuCharacters = Widgets.Button(mainList, "Characters", "CHARACTERS")
    menuCharacters.Size = UDim2.fromScale(1, 0.16)
    menuCharacters.Activated:Connect(function()
        controller:Open("Characters")
    end)

    local menuReturn = Widgets.Button(mainList, "Return", "RETURN TO GAME")
    menuReturn.Size = UDim2.fromScale(1, 0.16)
    menuReturn.Activated:Connect(function()
        controller:Close()
    end)

    local function settingButton(textValue: string, attribute: string, defaultValue: boolean)
        local button = Widgets.Button(settingsList, attribute, textValue)
        button.Size = UDim2.fromScale(1, 0.16)

        local function refresh()
            local enabled = player:GetAttribute(attribute)
            if enabled == nil then
                enabled = defaultValue
                player:SetAttribute(attribute, enabled)
            end
            button.Text = textValue .. ": " .. (enabled and "ON" or "OFF")
        end

        button.Activated:Connect(function()
            local current = player:GetAttribute(attribute)
            if current == nil then
                current = defaultValue
            end
            player:SetAttribute(attribute, not current)
            refresh()
        end)

        refresh()
    end

    settingButton("AUTO SPRINT", "CCSettingAutoSprint", false)
    settingButton("CAMERA SHAKE", "CCSettingCameraShake", true)
    settingButton("REDUCED MOTION", "CCSettingReducedMotion", false)

    characterClose.Activated:Connect(function()
        controller:Close()
    end)
    emoteClose.Activated:Connect(function()
        controller:Close()
    end)
    mainClose.Activated:Connect(function()
        controller:Close()
    end)
    settingsClose.Activated:Connect(function()
        controller:Open("Menu")
    end)

    dim.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            controller:Close()
        end
    end)

    controller = setmetatable({
        Gui = gui,
        Root = root,
        _dim = dim,
        _panels = {
            Characters = characterPanel,
            Emotes = emotePanel,
            Menu = mainPanel,
            Settings = settingsPanel
        },
        _firstButtons = {
            Characters = characterButtons[1],
            Emotes = emoteButtons[1],
            Menu = menuSettings,
            Settings = settingsList:FindFirstChildWhichIsA("TextButton")
        }
    }, MenuController)

    controller:Close()
    return controller
end

function MenuController:Open(name: string)
    for panelName, frame in pairs(self._panels) do
        frame.Visible = panelName == name
    end

    self._dim.Visible = true
    self.Root.Visible = true
    setOpenAttributes(name, true)
    selectFirst(self._firstButtons[name])
end

function MenuController:Close()
    for _, frame in pairs(self._panels) do
        frame.Visible = false
    end

    self._dim.Visible = false
    self.Root.Visible = false
    setOpenAttributes("", false)

    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.SelectedObject = nil
    end
end

function MenuController:Toggle(name: string)
    local frame = self._panels[name]
    if frame and frame.Visible then
        self:Close()
    else
        self:Open(name)
    end
end

function MenuController:Destroy()
    self:Close()
    self.Gui:Destroy()
end

return MenuController
