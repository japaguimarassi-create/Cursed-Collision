--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
Theme.ResponsiveScale(root, 760, 0.68, 1.06)

local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Theme.Colors.Background
backdrop.BackgroundTransparency = 1
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.Parent = root

local panel = Theme.Panel(root, "Panel", UDim2.fromScale(0.86, 0.79))
panel.Visible = false
panel.BackgroundTransparency = 0.08

local accent = Instance.new("Frame")
accent.Name = "TopAccent"
accent.Size = UDim2.fromScale(0.62, 0.008)
accent.Position = UDim2.fromScale(0.04, 0.145)
accent.BackgroundColor3 = Theme.Colors.Accent
accent.BorderSizePixel = 0
accent.Parent = panel
Theme.Corner(accent, 4)

local title = Theme.Label(panel, "Title", "CURSED COLLISION", UDim2.fromScale(0.58, 0.075), UDim2.fromScale(0.04, 0.035), 20)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack

local subtitle = Theme.Label(panel, "Subtitle", "BATTLEGROUND • COLLECTION • PROGRESSION", UDim2.fromScale(0.64, 0.045), UDim2.fromScale(0.04, 0.095), 8)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextColor3 = Theme.Colors.Muted

local credits = Theme.Label(panel, "Credits", "0 C", UDim2.fromScale(0.22, 0.06), UDim2.fromScale(0.69, 0.045), 12)
credits.TextXAlignment = Enum.TextXAlignment.Right
credits.Font = Enum.Font.GothamBlack
credits.TextColor3 = Theme.Colors.Warning

local close = Theme.Button(panel, "Close", "×", UDim2.fromOffset(50, 44), UDim2.fromScale(0.95, 0.035), 44)
close.AnchorPoint = Vector2.new(1, 0)
close.TextSize = 21

local tabs = Instance.new("Frame")
tabs.Name = "Tabs"
tabs.Size = UDim2.fromScale(0.92, 0.085)
tabs.Position = UDim2.fromScale(0.04, 0.17)
tabs.BackgroundTransparency = 1
tabs.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.Padding = UDim.new(0, 7)
tabLayout.Parent = tabs

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.fromScale(0.92, 0.665)
content.Position = UDim2.fromScale(0.04, 0.275)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.fromOffset(0, 0)
content.Selectable = true
content.Parent = panel

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.Parent = content

local state = {
    Tab = "Shop",
    Credits = 0,
    OwnedSkins = {} :: {[string]: boolean},
    Quests = {Daily = {}, Weekly = {}, General = {}}
}

local tabsByName: {[string]: TextButton} = {}

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if child ~= contentLayout then
            child:Destroy()
        end
    end
end

local function updateTabs()
    for name, button in pairs(tabsByName) do
        button.BackgroundColor3 = name == state.Tab
            and Theme.Colors.SurfacePressed
            or Theme.Colors.Surface2
        button.TextColor3 = name == state.Tab
            and Theme.Colors.AccentBright
            or Theme.Colors.Text
    end
end

local function row(index: number, main: string, sub: string?, callback: (() -> ())?): TextButton
    local holder = Instance.new("Frame")
    holder.Name = "RowHolder" .. index
    holder.Size = UDim2.new(1, -4, 0, 74)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = index
    holder.Parent = content

    local button = Theme.Button(holder, "Row", "", UDim2.fromScale(1, 1), UDim2.new(), 58)
    button.TextXAlignment = Enum.TextXAlignment.Left

    local mainLabel = Theme.Label(button, "Main", main, UDim2.fromScale(0.87, 0.44), UDim2.fromScale(0.06, 0.08), 11)
    mainLabel.TextXAlignment = Enum.TextXAlignment.Left
    mainLabel.Font = Enum.Font.GothamBlack

    if sub then
        local subLabel = Theme.Label(button, "Sub", sub, UDim2.fromScale(0.87, 0.30), UDim2.fromScale(0.06, 0.54), 8)
        subLabel.TextXAlignment = Enum.TextXAlignment.Left
        subLabel.TextColor3 = Theme.Colors.Muted
    end

    if callback then
        button.Activated:Connect(callback)
    end

    return button
end

local function renderShop()
    clearContent()
    local characterId = tostring(player:GetAttribute("CharacterId") or "Yuji")
    local index = 0

    for _, item in pairs(Shop.Skins) do
        if item.Character == characterId then
            index += 1
            local owned = state.OwnedSkins[item.Id] == true
            row(
                index,
                tostring(item.Name),
                owned and "OWNED • TAP TO EQUIP" or tostring(item.Price) .. " CREDITS",
                function()
                    account:FireServer(
                        owned and "Equip" or "Buy",
                        {category = "Skins", id = item.Id}
                    )
                end
            )
        end
    end

    if index == 0 then
        row(1, "NO SKINS REGISTERED", "More cosmetics can be added without changing this menu.", nil)
    end
end

local function renderGamepass()
    clearContent()

    local passList = {
        {Key = "UltimateSkin", Name = "ULTIMATE SKIN"},
        {Key = "InstantSkin", Name = "INSTANT SKIN"},
        {Key = "KillSound", Name = "KILL SOUND"}
    }

    for index, pass in ipairs(passList) do
        local info = Passes[pass.Key]
        local id = info and tonumber(info.Id) or 0
        row(
            index,
            pass.Name,
            id > 0 and "OPEN ROBLOX PURCHASE" or "NOT CONFIGURED",
            function()
                if id > 0 then
                    pcall(function()
                        MarketplaceService:PromptGamePassPurchase(player, id)
                    end)
                end
            end
        )
    end
end

local function renderQuests()
    clearContent()
    local index = 0

    for _, section in ipairs({"Daily", "Weekly", "General"}) do
        index += 1
        local header = row(index, section:upper(), "MISSIONS", nil)
        header.TextColor3 = Theme.Colors.Accent

        for _, quest in ipairs(state.Quests[section] or {}) do
            index += 1
            row(
                index,
                tostring(quest.Name or "Mission"),
                string.format(
                    "%d / %d  •  +%d C",
                    tonumber(quest.Progress) or 0,
                    tonumber(quest.Target) or 1,
                    tonumber(quest.Reward) or 0
                ),
                nil
            )
        end
    end
end

local function renderRewards()
    clearContent()

    local ownedCount = 0
    for _ in pairs(state.OwnedSkins) do
        ownedCount += 1
    end

    local ready = player:GetAttribute("AwakeningReady") == true
        or player:GetAttribute("UltimateReady") == true

    row(1, "CREDITS", tostring(state.Credits) .. " C", nil)
    row(2, "SKINS OWNED", tostring(ownedCount), nil)
    row(3, "TRANSFORMATION", ready and "READY • FULL METER" or "BUILD METER IN COMBAT", nil)
    row(4, "CURRENT FIGHTER", tostring(player:GetAttribute("CharacterName") or "Yuji") .. " • " .. tostring(player:GetAttribute("CharacterTitle") or ""), nil)
end

local function render()
    updateTabs()

    if state.Tab == "Shop" then
        renderShop()
    elseif state.Tab == "Gamepass" then
        renderGamepass()
    elseif state.Tab == "Quests" then
        renderQuests()
    else
        renderRewards()
    end
end

local function makeTab(name: string, text: string, width: number)
    local button = Theme.Button(
        tabs,
        name,
        text,
        UDim2.new(width, -6, 0.86, 0),
        UDim2.new(),
        52
    )
    button.TextSize = 9
    tabsByName[name] = button
    button.Activated:Connect(function()
        state.Tab = name
        player:SetAttribute("CCHUD_MenuSection", name)
        render()
    end)
end

makeTab("Shop", "SHOP", 0.25)
makeTab("Gamepass", "GAMEPASS", 0.25)
makeTab("Quests", "QUESTS", 0.22)
makeTab("Rewards", "REWARDS", 0.24)

local openTween: Tween?
local backdropTween: Tween?

local function closeMenu()
    if not panel.Visible then
        player:SetAttribute("CCHUD_MenuOpen", false)
        return
    end

    if openTween then
        openTween:Cancel()
    end
    if backdropTween then
        backdropTween:Cancel()
    end

    openTween = TweenService:Create(
        panel,
        TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = UDim2.fromScale(0.80, 0.73),
            BackgroundTransparency = 0.20
        }
    )
    backdropTween = TweenService:Create(
        backdrop,
        TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {BackgroundTransparency = 1}
    )

    openTween:Play()
    backdropTween:Play()

    task.delay(0.16, function()
        if player:GetAttribute("CCHUD_MenuOpen") ~= true then
            panel.Visible = false
            backdrop.Visible = false
        end
    end)
end

local function openMenu()
    Theme.CloseCombatAttributes(player)
    player:SetAttribute("CCHUD_MenuOpen", true)
    panel.Visible = true
    backdrop.Visible = true

    panel.Size = UDim2.fromScale(0.80, 0.73)
    panel.BackgroundTransparency = 0.20
    backdrop.BackgroundTransparency = 1

    if openTween then
        openTween:Cancel()
    end
    if backdropTween then
        backdropTween:Cancel()
    end

    openTween = TweenService:Create(
        panel,
        TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.fromScale(0.86, 0.79),
            BackgroundTransparency = 0.08
        }
    )
    backdropTween = TweenService:Create(
        backdrop,
        TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.38}
    )

    openTween:Play()
    backdropTween:Play()

    account:FireServer("Sync", {})
    render()

    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = tabsByName[state.Tab] or tabsByName.Shop
    end
end

close.Activated:Connect(closeMenu)
backdrop.Activated:Connect(closeMenu)

player:GetAttributeChangedSignal("CCHUD_MenuOpen"):Connect(function()
    if player:GetAttribute("CCHUD_MenuOpen") == true then
        openMenu()
    else
        closeMenu()
    end
end)

player:GetAttributeChangedSignal("CCHUD_MenuSection"):Connect(function()
    if player:GetAttribute("CCHUD_MenuOpen") ~= true then
        return
    end

    local section = tostring(player:GetAttribute("CCHUD_MenuSection") or "Shop")
    if tabsByName[section] then
        state.Tab = section
        render()
    end
end)

player:GetAttributeChangedSignal("CharacterId"):Connect(function()
    if panel.Visible and state.Tab == "Shop" then
        render()
    end
end)

player:GetAttributeChangedSignal("AwakeningReady"):Connect(function()
    if panel.Visible and state.Tab == "Rewards" then
        render()
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

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.ButtonStart then
        if panel.Visible then
            closeMenu()
        else
            openMenu()
        end
    end
end)
