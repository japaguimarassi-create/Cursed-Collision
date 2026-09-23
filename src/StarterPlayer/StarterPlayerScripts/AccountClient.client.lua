local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)

if not remotes then
    return
end

local accountAction = remotes:WaitForChild("AccountAction", 15)
local accountEvent = remotes:WaitForChild("AccountEvent", 15)
local gamePassAction = remotes:WaitForChild("GamePassAction", 15)
local gamePassEvent = remotes:WaitForChild("GamePassEvent", 15)

if not accountAction or not accountEvent or not gamePassAction or not gamePassEvent then
    return
end

local shop = require(ReplicatedStorage.Economy.ShopDefinitions)
local gamePassConfig = require(ReplicatedStorage.Monetization.GamePassConfig)

local oldGui = playerGui:FindFirstChild("CursedCollisionAccountUI")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionAccountUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local accent = Color3.fromRGB(155, 112, 255)
local panelColor = Color3.fromRGB(10, 12, 18)
local textColor = Color3.fromRGB(236, 237, 244)
local muted = Color3.fromRGB(155, 158, 176)
local successColor = Color3.fromRGB(104, 222, 148)
local errorColor = Color3.fromRGB(235, 82, 102)

local function corner(parent: GuiObject, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function stroke(parent: GuiObject, color: Color3, thickness: number)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.Transparency = 0.28
    s.Parent = parent
end

local function label(parent: Instance, textValue: string, size: UDim2, position: UDim2, font: Enum.Font, textSize: number)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = textValue
    l.Size = size
    l.Position = position
    l.Font = font
    l.TextSize = textSize
    l.TextColor3 = textColor
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function button(parent: Instance, name: string, textValue: string, size: UDim2, position: UDim2)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = textValue
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = Color3.fromRGB(24, 27, 37)
    b.BackgroundTransparency = 0.05
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextColor3 = textColor
    b.AutoButtonColor = true
    b.Active = true
    b.Selectable = true
    b.Parent = parent
    corner(b, 10)
    stroke(b, Color3.fromRGB(78, 82, 102), 1)
    return b
end

local function setMenuOpen(open: boolean)
    player:SetAttribute("CCHUD_MenuOpen", open)
end

local function closeOwner()
    local ownerGui = playerGui:FindFirstChild("CursedCollisionOwnerUI")
    if ownerGui then
        local ownerPanel = ownerGui:FindFirstChild("OwnerPanel")
        if ownerPanel and ownerPanel:IsA("GuiObject") then
            ownerPanel.Visible = false
        end
    end
    player:SetAttribute("CCHUD_OwnerPanelOpen", false)
end

local menuButton = button(gui, "MenuButton", "MENU", UDim2.fromScale(0.105, 0.06), UDim2.fromScale(0.875, 0.022))

local panel = Instance.new("Frame")
panel.Name = "AccountPanel"
panel.Size = UDim2.fromScale(0.90, 0.82)
panel.Position = UDim2.fromScale(0.50, 0.51)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = panelColor
panel.BackgroundTransparency = 0.02
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
corner(panel, 18)
stroke(panel, accent, 1.5)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(300, 420)
sizeConstraint.MaxSize = Vector2.new(920, 740)
sizeConstraint.Parent = panel

local panelScale = Instance.new("UIScale")
panelScale.Scale = 0.96
panelScale.Parent = panel

label(panel, "CURSED COLLISION", UDim2.fromScale(0.50, 0.075), UDim2.fromScale(0.035, 0.025), Enum.Font.GothamBlack, 20)
local subheader = label(panel, "SKINS • MISSIONS", UDim2.fromScale(0.45, 0.05), UDim2.fromScale(0.035, 0.092), Enum.Font.Gotham, 9)
subheader.TextColor3 = muted

local creditsLabel = label(panel, "0 CREDITS", UDim2.fromScale(0.28, 0.06), UDim2.fromScale(0.64, 0.034), Enum.Font.GothamBold, 13)
creditsLabel.TextXAlignment = Enum.TextXAlignment.Right

local platformLabel = label(panel, "MOBILE", UDim2.fromScale(0.25, 0.045), UDim2.fromScale(0.67, 0.088), Enum.Font.Gotham, 9)
platformLabel.TextXAlignment = Enum.TextXAlignment.Right
platformLabel.TextColor3 = muted

local close = button(panel, "Close", "×", UDim2.fromScale(0.07, 0.075), UDim2.fromScale(0.92, 0.025))
close.TextSize = 22

local tabs = Instance.new("Frame")
tabs.Size = UDim2.fromScale(0.94, 0.09)
tabs.Position = UDim2.fromScale(0.03, 0.145)
tabs.BackgroundTransparency = 1
tabs.Parent = panel

local tabShop = button(tabs, "ShopTab", "SKINS", UDim2.fromScale(0.45, 0.85), UDim2.fromScale(0, 0))
local tabQuest = button(tabs, "QuestTab", "MISSIONS", UDim2.fromScale(0.29, 0.85), UDim2.fromScale(0.355, 0))
local tabPass = button(tabs, "PassTab", "PASSES", UDim2.fromScale(0.29, 0.85), UDim2.fromScale(0.665, 0))
tabShop.Size = UDim2.fromScale(0.29, 0.85)

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.fromScale(0.94, 0.71)
content.Position = UDim2.fromScale(0.03, 0.245)
content.BackgroundTransparency = 1
content.Parent = panel

local state = {
    economy = {
        Credits = 0,
        OwnedSkins = {},
        EquippedSkin = ""
    },
    quests = {
        Daily = {},
        Weekly = {},
        General = {},
        Totals = {Daily = 24, Weekly = 24, General = 24}
    },
    activeTab = "Shop",
    passes = {UltimateSkin = false, KillSound = false, InstantSkin = false}
}

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        child:Destroy()
    end
end

local function listFrame()
    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.fromScale(1, 1)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 5
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list

    return list
end

local function skinButton(parent: Instance, item, owned: boolean, equipped: boolean)
    local actionText = owned and (equipped and "EQUIPPED" or "OWNED") or (tostring(item.Price) .. " C")
    local b = button(parent, item.Id, "", UDim2.new(1, -8, 0, 64), UDim2.new())

    local name = label(b, item.Name, UDim2.new(0.60, 0, 0.53, 0), UDim2.fromScale(0.025, 0.03), Enum.Font.GothamBold, 13)
    name.TextColor3 = equipped and accent or textColor

    local rarity = label(b, item.Rarity or "SKIN", UDim2.new(0.42, 0, 0.27, 0), UDim2.fromScale(0.025, 0.61), Enum.Font.Gotham, 9)
    rarity.TextColor3 = muted

    local action = label(b, actionText, UDim2.new(0.31, 0, 0.70, 0), UDim2.fromScale(0.66, 0.15), Enum.Font.GothamBlack, 11)
    action.TextXAlignment = Enum.TextXAlignment.Right
    action.TextColor3 = equipped and accent or (owned and successColor or textColor)

    b.Activated:Connect(function()
        if owned then
            accountAction:FireServer("Equip", {category = "Skins", id = item.Id})
        else
            accountAction:FireServer("Buy", {category = "Skins", id = item.Id})
        end
    end)
end

local function renderShop()
    clearContent()

    local characterId = player:GetAttribute("CharacterId") or "PotentialMan"
    local title = label(content, "CURRENT • " .. characterId, UDim2.fromScale(1, 0.08), UDim2.new(), Enum.Font.GothamBlack, 12)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextColor3 = muted

    local list = listFrame()
    list.Position = UDim2.fromScale(0, 0.10)
    list.Size = UDim2.fromScale(1, 0.90)

    local order = 0
    for id, item in pairs(shop.Skins) do
        if item.Character == characterId then
            order += 1
            local b = skinButton(list, item, state.economy.OwnedSkins[id] == true, state.economy.EquippedSkin == id)
            b.LayoutOrder = order
        end
    end
end

local function questCard(parent: Instance, quest)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 92)
    frame.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    corner(frame, 10)
    stroke(frame, Color3.fromRGB(69, 72, 90), 1)

    label(frame, quest.Name or "Mission", UDim2.fromScale(0.66, 0.24), UDim2.fromScale(0.025, 0.07), Enum.Font.GothamBold, 12)
    local desc = label(frame, quest.Description or "", UDim2.fromScale(0.66, 0.33), UDim2.fromScale(0.025, 0.31), Enum.Font.Gotham, 10)
    desc.TextColor3 = muted

    local progress = math.floor(tonumber(quest.Progress) or 0)
    local target = math.max(1, math.floor(tonumber(quest.Target) or 1))
    local ratio = math.clamp(progress / target, 0, 1)

    local back = Instance.new("Frame")
    back.Size = UDim2.fromScale(0.55, 0.10)
    back.Position = UDim2.fromScale(0.025, 0.77)
    back.BackgroundColor3 = Color3.fromRGB(45, 46, 58)
    back.BorderSizePixel = 0
    back.Parent = frame
    corner(back, 5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(ratio, 1)
    fill.BackgroundColor3 = quest.Completed and successColor or accent
    fill.BorderSizePixel = 0
    fill.Parent = back
    corner(fill, 5)

    local p = label(frame, tostring(progress) .. " / " .. tostring(target), UDim2.fromScale(0.25, 0.20), UDim2.fromScale(0.60, 0.72), Enum.Font.GothamBold, 9)
    p.TextXAlignment = Enum.TextXAlignment.Right

    local reward = label(frame, "+" .. tostring(quest.Reward or 0) .. " C", UDim2.fromScale(0.25, 0.22), UDim2.fromScale(0.70, 0.20), Enum.Font.GothamBlack, 14)
    reward.TextXAlignment = Enum.TextXAlignment.Right
    reward.TextColor3 = Color3.fromRGB(255, 213, 101)
end

local function renderQuests()
    clearContent()

    local info = label(content, "DAILY • " .. tostring(state.quests.Totals.Daily or 24) .. "  |  WEEKLY • " .. tostring(state.quests.Totals.Weekly or 24) .. "  |  MASTERY • " .. tostring(state.quests.Totals.General or 24), UDim2.fromScale(1, 0.07), UDim2.new(), Enum.Font.GothamBold, 10)
    info.TextColor3 = muted
    info.TextXAlignment = Enum.TextXAlignment.Center

    local list = listFrame()
    list.Position = UDim2.fromScale(0, 0.08)
    list.Size = UDim2.fromScale(1, 0.92)

    local order = 0
    local function section(titleText: string, quests)
        order += 1
        local title = label(list, titleText, UDim2.new(1, -8, 0, 30), UDim2.new(), Enum.Font.GothamBlack, 14)
        title.LayoutOrder = order
        title.TextColor3 = accent

        for _, quest in ipairs(quests or {}) do
            order += 1
            local card = questCard(list, quest)
            card.LayoutOrder = order
        end
    end

    section("DAILY", state.quests.Daily)
    section("WEEKLY", state.quests.Weekly)
    section("GENERAL / MASTERY", state.quests.General)
end

local function passButton(parent: Instance, key: string, title: string, description: string, action: string?)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -8, 0, 102)
    card.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    card.BorderSizePixel = 0
    card.Parent = parent
    corner(card, 12)
    stroke(card, Color3.fromRGB(69, 72, 90), 1)

    local titleLabel = label(card, title, UDim2.fromScale(0.57, 0.23), UDim2.fromScale(0.025, 0.10), Enum.Font.GothamBlack, 13)
    titleLabel.TextColor3 = accent

    local desc = label(card, description, UDim2.fromScale(0.57, 0.44), UDim2.fromScale(0.025, 0.34), Enum.Font.Gotham, 10)
    desc.TextColor3 = muted

    local statusText = state.passes[key] and "OWNED" or (gamePassConfig[key].Id > 0 and "BUY" or "SET ID")
    local actionButton = button(card, "Pass_" .. key, statusText, UDim2.fromScale(0.29, 0.30), UDim2.fromScale(0.68, 0.17))
    actionButton.TextSize = 10

    actionButton.Activated:Connect(function()
        if state.passes[key] then
            return
        end

        local id = gamePassConfig[key].Id
        if type(id) == "number" and id > 0 then
            pcall(function()
                MarketplaceService:PromptGamePassPurchase(player, id)
            end)
        end
    end)

    if action then
        local selector = button(card, "Action_" .. key, action, UDim2.fromScale(0.29, 0.30), UDim2.fromScale(0.68, 0.56))
        selector.TextSize = 9
        selector.Visible = state.passes[key]

        selector.Activated:Connect(function()
            if key == "InstantSkin" then
                gamePassAction:FireServer("ApplyInstantSkin", {
                    skinId = state.economy.EquippedSkin
                })
            elseif key == "UltimateSkin" then
                gamePassAction:FireServer("SetUltimateSkin", {
                    skinId = state.economy.EquippedSkin
                })
            end
        end)
    end

    return card
end

local function renderPasses()
    clearContent()

    local list = listFrame()
    list.Size = UDim2.fromScale(1, 1)

    passButton(
        list,
        "UltimateSkin",
        "ULTIMATE SKIN",
        "Use your selected owned skin automatically when your Ultimate/Awakening begins.",
        "USE EQUIPPED SKIN"
    )

    passButton(
        list,
        "InstantSkin",
        "INSTANT SKIN SWAP",
        "Change to your currently equipped owned skin instantly during the match.",
        "APPLY NOW"
    )

    passButton(
        list,
        "KillSound",
        "KILL SOUND",
        "Unlocks the custom kill sound that plays after you confirm a player elimination.",
        nil
    )
end

local function render()
    if state.activeTab == "Shop" then
        renderShop()
    elseif state.activeTab == "Quests" then
        renderQuests()
    else
        renderPasses()
    end
end

local function openMenu()
    closeOwner()
    setMenuOpen(true)
    accountAction:FireServer("Sync", {})
gamePassAction:FireServer("Sync", {})
    render()
    panel.Visible = true
    panelScale.Scale = 0.96
    TweenService:Create(panelScale, TweenInfo.new(0.16, Enum.EasingStyle.Back), {Scale = 1}):Play()
end

local function closeMenu()
    setMenuOpen(false)
    panel.Visible = false
end

menuButton.Activated:Connect(function()
    if panel.Visible then
        closeMenu()
    else
        openMenu()
    end
end)

close.Activated:Connect(closeMenu)

tabShop.Activated:Connect(function()
    state.activeTab = "Shop"
    render()
end)

tabQuest.Activated:Connect(function()
    state.activeTab = "Quests"
    render()
end)

tabPass.Activated:Connect(function()
    state.activeTab = "Passes"
    render()
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonStart then
        if panel.Visible then
            closeMenu()
        else
            openMenu()
        end
    end
end)

local function showToast(message: string, success: boolean)
    if message == "" then
        return
    end

    local toast = label(gui, message, UDim2.fromScale(0.56, 0.055), UDim2.fromScale(0.22, 0.90), Enum.Font.GothamBold, 12)
    toast.TextXAlignment = Enum.TextXAlignment.Center
    toast.BackgroundTransparency = 0.10
    toast.BackgroundColor3 = success and Color3.fromRGB(22, 54, 37) or Color3.fromRGB(63, 25, 34)
    toast.TextColor3 = success and successColor or errorColor
    corner(toast, 9)
    Debris:AddItem(toast, 2.4)
end

accountEvent.OnClientEvent:Connect(function(event, payload)
    if event == "Sync" then
        state.economy = payload.Economy or state.economy
        state.quests = payload.Quests or state.quests
        creditsLabel.Text = tostring(state.economy.Credits or 0) .. " CREDITS"

        if panel.Visible then
            render()
        end

    elseif event == "Notice" then
        if player:GetAttribute("CCHUD_OwnerPanelOpen") ~= true then
            showToast(tostring(payload and payload.Message or ""), payload and payload.Success == true)
        end
    end
end)


gamePassEvent.OnClientEvent:Connect(function(event, payload)
    if event == "Sync" then
        for key, value in pairs(payload or {}) do
            if state.passes[key] ~= nil then
                state.passes[key] = value == true
            end
        end
        if panel.Visible and state.activeTab == "Passes" then
            render()
        end
    elseif event == "Result" then
        local success = payload and payload.Success == true
        showToast(tostring(payload and payload.Reason or "GamePass update"), success)
        gamePassAction:FireServer("Sync", {})
        accountAction:FireServer("Sync", {})
    elseif event == "KillSound" then
        local soundId = tostring(payload and payload.SoundId or "")
        if soundId ~= "" then
            local sound = Instance.new("Sound")
            sound.SoundId = soundId
            sound.Volume = math.clamp(tonumber(payload and payload.Volume) or 1, 0, 3)
            sound.Parent = workspace
            sound:Play()
            Debris:AddItem(sound, 5)
        end
    end
end)

local function updatePlatformLabel()
    platformLabel.Text =
        UserInputService.PreferredInput == Enum.PreferredInput.Touch
        and "MOBILE"
        or UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
        and "CONSOLE"
        or "PC"
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(updatePlatformLabel)

player:GetAttributeChangedSignal("CharacterId"):Connect(function()
    if panel.Visible and state.activeTab == "Shop" then
        render()
    end
end)

updatePlatformLabel()
setMenuOpen(false)
accountAction:FireServer("Sync", {})
