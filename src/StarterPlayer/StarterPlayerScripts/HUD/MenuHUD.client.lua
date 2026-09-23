--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Theme = require(script.Parent.HUDTheme)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local account = remotes and remotes:WaitForChild("AccountAction", 15)
local accountEvent = remotes and remotes:WaitForChild("AccountEvent", 15)
if not account or not accountEvent then
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
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.Parent = root

local panel = Theme.Panel(root, "Panel", UDim2.fromScale(0.84, 0.78))
panel.Visible = false

local title = Theme.Label(panel, "Title", "CURSED COLLISION", UDim2.fromScale(0.60, 0.08), UDim2.fromScale(0.04, 0.03), 20)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack

local sub = Theme.Label(panel, "Sub", "SHOP • MISSIONS • PASSES • PLAYERS", UDim2.fromScale(0.70, 0.045), UDim2.fromScale(0.04, 0.10), 8)
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.TextColor3 = Theme.Colors.Muted

local credits = Theme.Label(panel, "Credits", "0 C", UDim2.fromScale(0.20, 0.06), UDim2.fromScale(0.70, 0.045), 12)
credits.TextXAlignment = Enum.TextXAlignment.Right
credits.TextColor3 = Theme.Colors.Warning

local close = Theme.Button(panel, "Close", "×", UDim2.fromOffset(52, 44), UDim2.fromScale(0.94, 0.03), 44)
close.AnchorPoint = Vector2.new(1, 0)
close.TextSize = 21

local tabs = Instance.new("Frame")
tabs.Size = UDim2.fromScale(0.92, 0.085)
tabs.Position = UDim2.fromScale(0.04, 0.15)
tabs.BackgroundTransparency = 1
tabs.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 7)
tabLayout.Parent = tabs

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.fromScale(0.92, 0.69)
content.Position = UDim2.fromScale(0.04, 0.25)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.fromOffset(0, 0)
content.Selectable = true
content.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = content

local state = {
    Tab = "Shop",
    Credits = 0,
    OwnedSkins = {} :: {[string]: boolean},
    Quests = {Daily = {}, Weekly = {}, General = {}}
}

local function clear()
    for _, child in ipairs(content:GetChildren()) do
        if child ~= layout then
            child:Destroy()
        end
    end
end

local function row(order: number, text: string, callback: (() -> ())?): TextButton
    local b = Theme.Button(content, "Row" .. order, text, UDim2.new(1, -8, 0, 70), UDim2.new(), 56)
    b.LayoutOrder = order
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextSize = 10
    if callback then
        b.Activated:Connect(callback)
    end
    return b
end

local function renderShop()
    clear()
    local characterId = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
    local order = 0

    for _, item in pairs(Shop.Skins) do
        if item.Character == characterId then
            order += 1
            local owned = state.OwnedSkins[item.Id] == true
            row(
                order,
                tostring(item.Name) .. "\n" .. (owned and "OWNED • TAP TO EQUIP" or tostring(item.Price) .. " CREDITS"),
                function()
                    account:FireServer(owned and "Equip" or "Buy", {category = "Skins", id = item.Id})
                end
            )
        end
    end

    if order == 0 then
        row(1, "NO SKINS REGISTERED", nil)
    end
end

local function renderMissions()
    clear()
    local order = 0

    for _, section in ipairs({"Daily", "Weekly", "General"}) do
        order += 1
        local heading = row(order, section:upper(), nil)
        heading.TextColor3 = Theme.Colors.Accent
        for _, quest in ipairs(state.Quests[section] or {}) do
            order += 1
            row(
                order,
                tostring(quest.Name or "Mission")
                    .. "\n"
                    .. tostring(quest.Progress or 0)
                    .. " / "
                    .. tostring(quest.Target or 1)
                    .. "  •  +"
                    .. tostring(quest.Reward or 0)
                    .. " C",
                nil
            )
        end
    end
end

local function renderPasses()
    clear()
    local passes = {
        {Key = "UltimateSkin", Name = "ULTIMATE SKIN"},
        {Key = "InstantSkin", Name = "INSTANT SKIN"},
        {Key = "KillSound", Name = "KILL SOUND"}
    }

    for index, data in ipairs(passes) do
        row(index, data.Name .. "\nOPEN ROBLOX PURCHASE", function()
            local info = Passes[data.Key]
            if info and tonumber(info.Id) and info.Id > 0 then
                pcall(function()
                    MarketplaceService:PromptGamePassPurchase(player, info.Id)
                end)
            end
        end)
    end
end

local function renderPlayers()
    clear()
    for index, target in ipairs(Players:GetPlayers()) do
        row(index, string.format("%02d  %s  @%s", index, target.DisplayName, target.Name), nil)
    end
end

local function render()
    if state.Tab == "Shop" then
        renderShop()
    elseif state.Tab == "Missions" then
        renderMissions()
    elseif state.Tab == "Passes" then
        renderPasses()
    else
        renderPlayers()
    end
end

local tabShop = Theme.Button(tabs, "Shop", "SHOP", UDim2.fromScale(0.23, 0.86), UDim2.new(), 54)
local tabMissions = Theme.Button(tabs, "Missions", "MISSIONS", UDim2.fromScale(0.25, 0.86), UDim2.new(), 54)
local tabPasses = Theme.Button(tabs, "Passes", "PASSES", UDim2.fromScale(0.20, 0.86), UDim2.new(), 54)
local tabPlayers = Theme.Button(tabs, "Players", "PLAYERS", UDim2.fromScale(0.25, 0.86), UDim2.new(), 54)

tabShop.Activated:Connect(function() state.Tab = "Shop"; render() end)
tabMissions.Activated:Connect(function() state.Tab = "Missions"; render() end)
tabPasses.Activated:Connect(function() state.Tab = "Passes"; render() end)
tabPlayers.Activated:Connect(function() state.Tab = "Players"; render() end)

local function closeMenu()
    panel.Visible = false
    backdrop.Visible = false
    player:SetAttribute("CCHUD_MenuOpen", false)
end

local function openMenu()
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

close.Activated:Connect(closeMenu)
backdrop.Activated:Connect(closeMenu)

player:GetAttributeChangedSignal("CCHUD_MenuSection"):Connect(function()
    if player:GetAttribute("CCHUD_MenuOpen") ~= true then
        return
    end
    state.Tab = tostring(player:GetAttribute("CCHUD_MenuSection") or "Shop")
    render()
end)

player:GetAttributeChangedSignal("CCHUD_MenuOpen"):Connect(function()
    if player:GetAttribute("CCHUD_MenuOpen") == true
        and player:GetAttribute("CCHUD_CharacterMenuOpen") ~= true
        and player:GetAttribute("CCHUD_EmoteWheelOpen") ~= true
        and player:GetAttribute("CCHUD_SettingsOpen") ~= true
        and player:GetAttribute("CCHUD_OwnerPanelOpen") ~= true then
        openMenu()
    else
        closeMenu()
    end
end)

accountEvent.OnClientEvent:Connect(function(event, payload)
    if event ~= "Sync" or type(payload) ~= "table" then
        return
    end
    local economy = payload.Economy
    if type(economy) == "table" then
        state.Credits = tonumber(economy.Credits) or state.Credits
        state.OwnedSkins = economy.OwnedSkins or state.OwnedSkins
        credits.Text = tostring(state.Credits) .. " C"
    end
    if type(payload.Quests) == "table" then
        state.Quests = payload.Quests
    end
    if panel.Visible then
        render()
    end
end)

player:GetAttributeChangedSignal("CharacterId"):Connect(function()
    if panel.Visible and state.Tab == "Shop" then
        render()
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.ButtonStart and panel.Visible then
        closeMenu()
    end
end)
