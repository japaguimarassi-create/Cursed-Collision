local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")

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
local GamePassConfig = require(ReplicatedStorage.Monetization.GamePassConfig)

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
    b.TextSize = 13
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
menuButton.TextSize = 12

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

local header = label(panel, "CURSED COLLISION", UDim2.fromScale(0.50, 0.075), UDim2.fromScale(0.035, 0.025), Enum.Font.GothamBlack, 20)
header.TextColor3 = textColor

local subtitle = label(panel, "PROFILE • SKINS • MISSIONS • GAMEPASSES", UDim2.fromScale(0.62, 0.05), UDim2.fromScale(0.035, 0.092), Enum.Font.Gotham, 9)
subtitle.TextColor3 = muted

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

local tabShop = button(tabs, "ShopTab", "SKINS", UDim2.fromScale(0.30, 0.85), UDim2.fromScale(0, 0))
local tabQuest = button(tabs, "QuestTab", "MISSIONS", UDim2.fromScale(0.30, 0.85), UDim2.fromScale(0.35, 0))
local tabPass = button(tabs, "PassTab", "GAMEPASSES", UDim2.fromScale(0.30, 0.85), UDim2.fromScale(0.70, 0))

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
        EquippedSkin = "",
        UltimateSkin = ""
    },
    quests = {
        Daily = {},
        Weekly = {},
        General = {},
        Totals = {Daily = 24, Weekly = 24, General = 24}
    },
    passes = {
        UltimateSkin = false,
        KillSound = false,
        InstantSkin = false
    },
    activeTab = "Shop",
    shopCharacter = player:GetAttribute("CharacterId") or "PotentialMan"
}

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        child:Destroy()
    end
end

local function listFrame(parent: Instance)
    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.fromScale(1, 1)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 5
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.Parent = parent

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
            accountAction:FireServer("Equip", {
                category = "Skins",
                id = item.Id
            })
        else
            accountAction:FireServer("Buy", {
                category = "Skins",
                id = item.Id
            })
        end
    end)

    return b
end

local function renderShop()
    clearContent()

    local characterId = player:GetAttribute("CharacterId") or state.shopCharacter
    state.shopCharacter = characterId

    local title = label(content, "CURRENT CHARACTER • " .. characterId, UDim2.fromScale(1, 0.08), UDim2.fromScale(0, 0), Enum.Font.GothamBlack, 12)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextColor3 = muted

    local list = listFrame(content)
    list.Position = UDim2.fromScale(0, 0.10)
    list.Size = UDim2.fromScale(1, 0.90)

    local order = 0

    for id, item in pairs(shop.Skins) do
        if item.Character == characterId then
            order += 1
            local owned = state.economy.OwnedSkins[id] == true
            local equipped = state.economy.EquippedSkin == id
            local b = skinButton(list, item, owned, equipped)
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

    local barBack = Instance.new("Frame")
    barBack.Size = UDim2.fromScale(0.55, 0.10)
    barBack.Position = UDim2.fromScale(0.025, 0.77)
    barBack.BackgroundColor3 = Color3.fromRGB(45, 46, 58)
    barBack.BorderSizePixel = 0
    barBack.Parent = frame
    corner(barBack, 5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(ratio, 1)
    fill.BackgroundColor3 = quest.Completed and successColor or accent
    fill.BorderSizePixel = 0
    fill.Parent = barBack
    corner(fill, 5)

    local progressText = label(frame, tostring(progress) .. " / " .. tostring(target), UDim2.fromScale(0.25, 0.20), UDim2.fromScale(0.60, 0.72), Enum.Font.GothamBold, 9)
    progressText.TextXAlignment = Enum.TextXAlignment.Right

    local reward = label(frame, "+" .. tostring(quest.Reward or 0) .. " C", UDim2.fromScale(0.25, 0.22), UDim2.fromScale(0.70, 0.20), Enum.Font.GothamBlack, 14)
    reward.TextXAlignment = Enum.TextXAlignment.Right
end

local function renderQuests()
    clearContent()

    local info = label(content, "DAILY • " .. tostring(state.quests.Totals.Daily or 24) .. "  |  WEEKLY • " .. tostring(state.quests.Totals.Weekly or 24) .. "  |  MASTERY • " .. tostring(state.quests.Totals.General or 24), UDim2.fromScale(1, 0.07), UDim2.fromScale(0, 0), Enum.Font.GothamBold, 10)
    info.TextColor3 = muted
    info.TextXAlignment = Enum.TextXAlignment.Center

    local list = listFrame(content)
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

local function passStatus(key: string)
    return state.passes[key] == true and "OWNED" or (GamePassConfig[key].Id > 0 and "BUY" or "ID NOT SET")
end

local function promptPass(key: string)
    local pass = GamePassConfig[key]

    if not pass or pass.Id <= 0 then
        return false
    end

    if state.passes[key] then
        return true
    end

    pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, pass.Id)
    end)

    return true
end

local function ownedCurrentSkins()
    local result = {}

    for id in pairs(state.economy.OwnedSkins) do
        local item = shop.Skins[id]
        if item and item.Character == (player:GetAttribute("CharacterId") or "") then
            table.insert(result, item)
        end
    end

    table.sort(result, function(a, b)
        return a.Name < b.Name
    end)

    return result
end

local function skinSelector(parent: Instance, titleText: string, currentId: string, action: string, passKey: string)
    local head = label(parent, titleText, UDim2.fromScale(1, 0.07), UDim2.new(), Enum.Font.GothamBlack, 12)
    head.TextColor3 = accent

    local passButton = button(parent, "Pass_" .. passKey, passStatus(passKey), UDim2.fromScale(0.27, 0.09), UDim2.fromScale(0.72, 0))
    passButton.TextSize = 10

    if passKey == "UltimateSkin" then
        passButton.Activated:Connect(function()
            promptPass(passKey)
        end)
    else
        passButton.Activated:Connect(function()
            promptPass(passKey)
        end)
    end

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.fromScale(1, 0.78)
    list.Position = UDim2.fromScale(0, 0.10)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 4
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = list

    for _, item in ipairs(ownedCurrentSkins()) do
        local selected = item.Id == currentId
        local b = button(list, item.Id, (selected and "• " or "") .. item.Name, UDim2.new(1, -5, 0, 46), UDim2.new())

        if selected then
            b.TextColor3 = accent
        end

        b.Activated:Connect(function()
            if not state.passes[passKey] then
                promptPass(passKey)
                return
            end

            gamePassAction:FireServer(action, {
                skinId = item.Id
            })
        end)
    end

    local empty = (#ownedCurrentSkins() == 0)
    if empty then
        local none = label(list, "No owned skins for this character yet.", UDim2.new(1, -8, 0, 42), UDim2.new(), Enum.Font.Gotham, 11)
        none.TextColor3 = muted
    end
end

local function renderPasses()
    clearContent()

    local list = listFrame(content)
    list.Size = UDim2.fromScale(1, 1)

    local passInfo = {
        {
            key = "UltimateSkin",
            action = "SetUltimateSkin",
            title = "ULTIMATE SKIN",
            text = "Automatically equip a chosen owned skin when AwakeningActive starts."
        },
        {
            key = "InstantSkin",
            action = "ApplyInstantSkin",
            title = "INSTANT SKIN SWAP",
            text = "Swap to any owned skin for the current character during a match."
        },
        {
            key = "KillSound",
            action = "",
            title = "KILL SOUND",
            text = "Unlocks a custom kill sound for eliminations."
        }
    }

    for index, info in ipairs(passInfo) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -8, 0, info.key == "KillSound" and 112 or 235)
        card.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
        card.BorderSizePixel = 0
        card.LayoutOrder = index
        card.Parent = list
        corner(card, 12)
        stroke(card, Color3.fromRGB(68, 71, 88), 1)

        local title = label(card, info.title, UDim2.fromScale(0.66, 0.16), UDim2.fromScale(0.025, 0.055), Enum.Font.GothamBlack, 14)
        title.TextColor3 = accent

        local desc = label(card, info.text, UDim2.fromScale(0.90, 0.20), UDim2.fromScale(0.025, 0.22), Enum.Font.Gotham, 10)
        desc.TextColor3 = muted

        local status = button(card, "Status", passStatus(info.key), UDim2.fromScale(0.25, 0.15), UDim2.fromScale(0.72, 0.055))
        status.TextSize = 10
        status.Activated:Connect(function()
            promptPass(info.key)
        end)

        if info.key ~= "KillSound" then
            skinSelector(card, info.title, info.key == "UltimateSkin" and state.economy.UltimateSkin or state.economy.EquippedSkin, info.action, info.key)
        else
            local audio = label(card, GamePassConfig.KillSoundId == "" and "Kill sound asset: configure GamePassConfig.KillSoundId" or "Kill sound asset configured.", UDim2.fromScale(0.92, 0.26), UDim2.fromScale(0.025, 0.52), Enum.Font.Gotham, 10)
            audio.TextColor3 = muted
        end
    end
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

local function animateOpen()
    panel.Visible = true
    panelScale.Scale = 0.96
    TweenService:Create(panelScale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

local function animateClose()
    local tween = TweenService:Create(panelScale, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.97})
    tween:Play()

    task.delay(0.10, function()
        if panel.Parent then
            panel.Visible = false
        end
    end)
end

local function toggleMenu()
    local open = not panel.Visible

    if open then
        closeOwner()
        setMenuOpen(true)
        accountAction:FireServer("Sync", {})
        gamePassAction:FireServer("Sync", {})
        render()
        animateOpen()

        if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
            GuiService.SelectedObject = tabShop
        end
    else
        setMenuOpen(false)
        animateClose()
    end
end

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

menuButton.Activated:Connect(toggleMenu)

close.Activated:Connect(function()
    setMenuOpen(false)
    animateClose()
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonStart then
        toggleMenu()
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
        if player:GetAttribute("CCHUD_OwnerPanelOpen") == true then
            return
        end
        showToast(tostring(payload and payload.Message or ""), payload and payload.Success == true)

    elseif event == "AdminPlayers" then
        return
    elseif event == "Platform" then
        platformLabel.Text = tostring(payload or "PC")
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
        local reason = tostring(payload and payload.Reason or "")
        local messages = {
            PASS_REQUIRED = "This feature requires its GamePass.",
            INVALID_SKIN = "That skin is not owned or does not belong to this character.",
            APPLY_FAILED = "The skin could not be applied.",
            SKIN_APPLIED = "Skin changed instantly.",
            ULTIMATE_SKIN_SET = "Ultimate skin selected."
        }

        showToast(messages[reason] or reason, payload and payload.Success == true)

        if panel.Visible then
            gamePassAction:FireServer("Sync", {})
            accountAction:FireServer("Sync", {})
        end

    elseif event == "KillSound" then
        local soundId = tostring(payload and payload.SoundId or "")

        if soundId == "" then
            return
        end

        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = tonumber(payload.Volume) or 1
        sound.Parent = workspace
        sound:Play()
        Debris:AddItem(sound, 5)
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
    state.shopCharacter = player:GetAttribute("CharacterId") or "PotentialMan"
    if panel.Visible and state.activeTab == "Shop" then
        render()
    end
end)

updatePlatformLabel()
setMenuOpen(false)
accountAction:FireServer("Sync", {})
gamePassAction:FireServer("Sync", {})
