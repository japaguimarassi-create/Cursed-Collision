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
    Open: (self: MenuController, menuName: string) -> (),
    Close: (self: MenuController) -> (),
    Toggle: (self: MenuController, menuName: string) -> (),
    Destroy: (self: MenuController) -> ()
}

local MenuController = {}
MenuController.__index = MenuController

local function panel(parent: Instance, title: string): (Frame, TextButton)
    local frame = Instance.new("Frame")
    frame.Name = title .. "Panel"
    frame.Size = UDim2.fromScale(0.90, 0.84)
    frame.Position = UDim2.fromScale(0.50, 0.53)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Theme.Colors.Panel
    frame.BackgroundTransparency = 0.04
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = parent
    Widgets.Corner(frame, Theme.Radius.Large)
    Widgets.Stroke(frame, 0.45)

    local heading = Widgets.Label(frame, title, UDim2.fromScale(0.72, 0.08), UDim2.fromScale(0.05, 0.025), 18)
    heading.TextXAlignment = Enum.TextXAlignment.Left

    local close = Widgets.Button(frame, "Close", "X", Theme.Radius.Pill)
    close.Size = UDim2.fromScale(0.08, 0.08)
    close.Position = UDim2.fromScale(0.90, 0.025)
    close.AnchorPoint = Vector2.new(0.5, 0)

    return frame, close
end

local function scroll(parent: Instance): ScrollingFrame
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

local function setMenuAttributes(name: string, open: boolean)
    player:SetAttribute("CCHUD_MenuOpen", open)

    player:SetAttribute("CCHUD_CharacterMenuOpen", name == "Characters" and open)
    player:SetAttribute("CCHUD_EmoteWheelOpen", name == "Emotes" and open)
    player:SetAttribute("CCHUD_SettingsOpen", name == "Settings" and open)
    player:SetAttribute("CCHUD_OwnerPanelOpen", name == "Owner" and open)
end

local function clearSelection()
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.SelectedObject = nil
    end
end

function MenuController.new(): MenuController
    local gui = Instance.new("ScreenGui")
    gui.Name = "CursedCollisionMenuHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 20
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = gui

    local dim = Widgets.Dim(root)

    local characterPanel, characterClose = panel(root, "CHARACTER SELECT")
    local characterList = scroll(characterPanel)

    local characterGrid = Instance.new("UIGridLayout")
    characterGrid.CellSize = UDim2.new(0.31, 0, 0, 58)
    characterGrid.CellPadding = UDim2.new(0.018, 0, 0, 10)
    characterGrid.SortOrder = Enum.SortOrder.LayoutOrder
    characterGrid.Parent = characterList

    local characterButtons: {TextButton} = {}
    local characterIds: {string} = {}

    for id, definition in pairs(Definitions) do
        table.insert(characterIds, id)
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Parent = characterList

        local button = Widgets.Button(holder, id, definition.Name or id)
        button.TextSize = 10
        button.LayoutOrder = #characterIds
        button.Activated:Connect(function()
            local remotes = ReplicatedStorage:WaitForChild("Remotes")
            local combat = remotes:FindFirstChild("CombatAction")
            if combat and combat:IsA("RemoteEvent") then
                combat:FireServer("SelectCharacter", {Id = id})
            end
            self:Close()
        end)

        table.insert(characterButtons, button)
    end

    table.sort(characterIds)

    local emotePanel, emoteClose = panel(root, "EMOTES")
    local emoteList = scroll(emotePanel)
    local emoteGrid = Instance.new("UIGridLayout")
    emoteGrid.CellSize = UDim2.new(0.31, 0, 0, 72)
    emoteGrid.CellPadding = UDim2.new(0.018, 0, 0, 10)
    emoteGrid.Parent = emoteList

    for id, emote in pairs(Emotes) do
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
            self:Close()
        end)
    end

    local mainPanel, mainClose = panel(root, "MENU")
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

    local settings = Widgets.Button(mainList, "Settings", "SETTINGS")
    settings.Size = UDim2.fromScale(1, 0.16)
    settings.Activated:Connect(function()
        self:Open("Settings")
    end)

    local emotes = Widgets.Button(mainList, "Emotes", "EMOTES")
    emotes.Size = UDim2.fromScale(1, 0.16)
    emotes.Activated:Connect(function()
        self:Open("Emotes")
    end)

    local characters = Widgets.Button(mainList, "Characters", "CHARACTERS")
    characters.Size = UDim2.fromScale(1, 0.16)
    characters.Activated:Connect(function()
        self:Open("Characters")
    end)

    local closeMenu = Widgets.Button(mainList, "CloseMenu", "RETURN TO GAME")
    closeMenu.Size = UDim2.fromScale(1, 0.16)
    closeMenu.Activated:Connect(function()
        self:Close()
    end)

    local settingsPanel, settingsClose = panel(root, "SETTINGS")
    local settingsList = Instance.new("Frame")
    settingsList.Size = UDim2.fromScale(0.78, 0.68)
    settingsList.Position = UDim2.fromScale(0.11, 0.17)
    settingsList.BackgroundTransparency = 1
    settingsList.Parent = settingsPanel

    local function settingButton(textValue: string, attribute: string, defaultValue: boolean)
        local button = Widgets.Button(settingsList, attribute, textValue)
        button.Size = UDim2.fromScale(1, 0.16)
        button.Activated:Connect(function()
            local current = player:GetAttribute(attribute)
            if current == nil then
                current = defaultValue
            end
            player:SetAttribute(attribute, not current)
            button.Text = textValue .. ": " .. (not current and "ON" or "OFF")
        end)
        button.Text = textValue .. ": " .. (player:GetAttribute(attribute) == true and "ON" or "OFF")
    end

    settingButton("AUTO SPRINT", "CCSettingAutoSprint", false)
    settingButton("CAMERA SHAKE", "CCSettingCameraShake", true)
    settingButton("REDUCED MOTION", "CCSettingReducedMotion", false)

    characterClose.Activated:Connect(function() self:Close() end)
    emoteClose.Activated:Connect(function() self:Close() end)
    mainClose.Activated:Connect(function() self:Close() end)
    settingsClose.Activated:Connect(function() self:Open("Menu") end)

    dim.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            self:Close()
        end
    end)

    local controller = setmetatable({
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
            Emotes = characterButtons[1],
            Menu = settings,
            Settings = settingsList:FindFirstChildWhichIsA("TextButton")
        }
    }, MenuController) :: any

    controller:Close()

    return controller
end

function MenuController:Open(self: MenuController, menuName: string)
    for name, frame in pairs(self._panels) do
        frame.Visible = name == menuName
    end

    self._dim.Visible = true
    self.Root.Visible = true
    setMenuAttributes(menuName, true)

    if Platform:IsGamepad() then
        GuiService.GuiNavigationEnabled = true
        GuiService.AutoSelectGuiEnabled = true
        local first = self._firstButtons[menuName]
        if first and first:IsA("GuiButton") then
            GuiService.SelectedObject = first
        end
    end
end

function MenuController:Close(self: MenuController)
    for _, frame in pairs(self._panels) do
        frame.Visible = false
    end

    self._dim.Visible = false
    self.Root.Visible = false
    setMenuAttributes("", false)
    clearSelection()
end

function MenuController:Toggle(self: MenuController, menuName: string)
    local frame = self._panels[menuName]
    if frame and frame.Visible then
        self:Close()
    else
        self:Open(menuName)
    end
end

function MenuController:Destroy(self: MenuController)
    self:Close()
    if self.Gui then
        self.Gui:Destroy()
    end
end

return MenuController
