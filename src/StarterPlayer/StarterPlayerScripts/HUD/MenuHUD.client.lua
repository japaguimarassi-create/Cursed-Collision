--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Theme = require(script.Parent.HUDTheme)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local account = remotes and remotes:WaitForChild("AccountAction", 15)
local accountEvent = remotes and remotes:WaitForChild("AccountEvent", 15)
local passEvent = remotes and remotes:WaitForChild("GamePassEvent", 15)
if not account or not accountEvent or not passEvent then
    return
end

local Shop = require(ReplicatedStorage.Economy.ShopDefinitions)
local Passes = require(ReplicatedStorage.Monetization.GamePassConfig)

local gui = Theme.CreateGui("CursedCollisionHUD_Menu", 55)
local root = Theme.Root(gui)
Theme.ResponsiveScale(root, 760, 0.70, 1.06)

local backdrop = Instance.new("TextButton")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Theme.Colors.Background
backdrop.BackgroundTransparency = 0.34
backdrop.BorderSizePixel = 0
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.Parent = root

local panel = Theme.Panel(root, "MenuPanel", UDim2.fromScale(0.84, 0.78))
panel.Visible = false

local title = Theme.Label(panel, "Title", "CURSED COLLISION", UDim2.fromScale(0.60, 0.08), UDim2.fromScale(0.04, 0.028), 20)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack

local credits = Theme.Label(panel, "Credits", "0 C", UDim2.fromScale(0.22, 0.06), UDim2.fromScale(0.69, 0.04), 12)
credits.TextXAlignment = Enum.TextXAlignment.Right
credits.TextColor3 = Theme.Colors.Warning

local close = Theme.Button(panel, "Close", "×", UDim2.fromOffset(52, 44), UDim2.fromScale(0.94, 0.03), 44)
close.AnchorPoint = Vector2.new(1, 0)
close.TextSize = 21

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.fromScale(0.92, 0.085)
tabBar.Position = UDim2.fromScale(0.04, 0.145)
tabBar.BackgroundTransparency = 1
tabBar.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabBar

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.fromScale(0.92, 0.69)
content.Position = UDim2.fromScale(0.04, 0.245)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.fromOffset(0, 0)
content.ScrollBarThickness = 5
content.Selectable = true
content.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = content

local state = {
    tab = "Shop",
    economy = {Credits = 0, OwnedSkins = {}, EquippedSkin = ""},
    quests = {Daily = {}, Weekly = {}, General = {}},
    passes = {UltimateSkin = false, InstantSkin = false, KillSound = false}
}

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if child ~= layout then
            child:Destroy()
        end
    end
end

local function row(text: string, order: number, callback: (() -> ())?): TextButton
    local b = Theme.Button(content, "Row" .. order, text, UDim2.new(1, -8, 0, 70), UDim2.new(), 54)
    b.LayoutOrder = order
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextSize = 10
    if callback then
        b.Activated:Connect(callback)
    end
    return b
end

local function renderShop()
    clearContent()
    local characterId = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
    local order = 0

    for id, item in pairs(Shop.Skins) do
        if item.Character == characterId then
            order += 1
            local owned = state.economy.OwnedSkins[id] == true
            row(
                item.Name .. "\n" .. (owned and "OWNED / TAP TO EQUIP" or tostring(item.Price) .. " CREDITS"),
                order,
                function()
                    account:FireServer(owned and "Equip" or "Buy", {category = "Skins", id = id})
                end
            )
        end
    end

    if order == 0 then
        row("No skins registered for this fighter.", 1, nil)
    end
end

local function renderMissions()
    clearContent()
    local order = 0

    for _, section in ipairs({"Daily", "Weekly", "General"}) do
        order += 1
        local heading = row(section:upper(), order, nil)
        heading.TextColor3 = Theme.Colors.Accent
        heading.TextSize = 11

        for _, quest in ipairs(state.quests[section] or {}) do
            order += 1
            row(
                tostring(quest.Name or "Mission")
                    .. "\n"
                    .. tostring(quest.Progress or 0)
                    .. " / "
                    .. tostring(quest.Target or 1)
                    .. "   •   +"
                    .. tostring(quest.Reward or 0)
                    .. " C",
                order,
                nil
            )
        end
    end
end

local function renderPasses()
    clearContent()
    local data = {
        {"UltimateSkin", "ULTIMATE SKIN"},
        {"InstantSkin", "INSTANT SKIN"},
        {"KillSound", "KILL SOUND"}
    }

    for index, item in ipairs(data) do
        local key, titleText = item[1], item[2]
        row(
            titleText .. "\n" .. (state.passes[key] and "OWNED" or "PURCHASE"),
            index,
            function()
                local config = Passes[key]
                if config and tonumber(config.Id) and config.Id > 0 then
                    local marketplace = game:GetService("MarketplaceService")
                    pcall(function()
                        marketplace:PromptGamePassPurchase(player, config.Id)
                    end)
                end
            end
        )
    end
end

local function render()
    if state.tab == "Shop" then
        renderShop()
    elseif state.tab == "Missions" then
        renderMissions()
    elseif state.tab == "Passes" then
        renderPasses()
    else
        clearContent()
        local players = Players:GetPlayers()
        for index, target in ipairs(players) do
            row(string.format("%02d   %s   @%s", index, target.DisplayName, target.Name), index, nil)
        end
    end
end

local tabShop = Theme.Button(tabBar, "Shop", "SHOP", UDim2.fromScale(0.23, 0.86), UDim2.new(), 54)
local tabMissions = Theme.Button(tabBar, "Missions", "MISSIONS", UDim2.fromScale(0.25, 0.86), UDim2.new(), 54)
local tabPasses = Theme.Button(tabBar, "Passes", "PASSES", UDim2.fromScale(0.20, 0.86), UDim2.new(), 54)
local tabPlayers = Theme.Button(tabBar, "Players", "PLAYERS", UDim2.fromScale(0.25, 0.86), UDim2.new(), 54)

tabShop.Activated:Connect(function() state.tab = "Shop"; render() end)
tabMissions.Activated:Connect(function() state.tab = "Missions"; render() end)
tabPasses.Activated:Connect(function() state.tab = "Passes"; render() end)
tabPlayers.Activated:Connect(function() state.tab = "Players"; render() end)

local function closePanel()
    panel.Visible = false
    backdrop.Visible = false
    if player:GetAttribute("CCHUD_MenuOpen") == true then
        player:SetAttribute("CCHUD_MenuOpen", false)
    end
end

local function openPanel()
    player:SetAttribute("CCHUD_CharacterMenuOpen", false)
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
    player:SetAttribute("CCHUD_SettingsOpen", false)
    player:SetAttribute("CCHUD_OwnerPanelOpen", false)
    player:SetAttribute("CCHUD_MenuOpen", true)
    panel.Visible = true
    backdrop.Visible = true
    account:FireServer("Sync", {})
    render()
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = tabShop
    end
end

close.Activated:Connect(closePanel)
backdrop.Activated:Connect(closePanel)

accountEvent.OnClientEvent:Connect(function(event, payload)
    if event ~= "Sync" or not payload then
        return
    end
    state.economy = payload.Economy or state.economy
    state.quests = payload.Quests or state.quests
    credits.Text = tostring(state.economy.Credits or 0) .. " C"
    if panel.Visible then
        render()
    end
end)

passEvent.OnClientEvent:Connect(function(event, payload)
    if event ~= "Sync" then
        return
    end
    for key, value in pairs(payload or {}) do
        if state.passes[key] ~= nil then
            state.passes[key] = value == true
        end
    end
    if panel.Visible and state.tab == "Passes" then
        render()
    end
end)

player:GetAttributeChangedSignal("CCHUD_MenuOpen"):Connect(function()
    local open = player:GetAttribute("CCHUD_MenuOpen") == true
        and player:GetAttribute("CCHUD_CharacterMenuOpen") ~= true
        and player:GetAttribute("CCHUD_EmoteWheelOpen") ~= true
        and player:GetAttribute("CCHUD_SettingsOpen") ~= true
        and player:GetAttribute("CCHUD_OwnerPanelOpen") ~= true

    if open then
        local section = tostring(player:GetAttribute("CCHUD_MenuSection") or "")
        state.tab = section == "Leaderboard" and "Players" or "Shop"
        openPanel()
    else
        closePanel()
    end
end)

player:GetAttributeChangedSignal("CharacterId"):Connect(function()
    if panel.Visible and state.tab == "Shop" then
        render()
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.ButtonStart and panel.Visible then
        closePanel()
    end
end)
