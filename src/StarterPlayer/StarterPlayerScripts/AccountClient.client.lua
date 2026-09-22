local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remotes then
    return
end

local accountAction = remotes:WaitForChild("AccountAction", 15)
local accountEvent = remotes:WaitForChild("AccountEvent", 15)
if not accountAction or not accountEvent then
    return
end

local shop = require(ReplicatedStorage.Economy.ShopDefinitions)

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

local header = label(panel, "Cursed Collision", UDim2.fromScale(0.48, 0.075), UDim2.fromScale(0.035, 0.025), Enum.Font.GothamBlack, 20)
local subheader = label(panel, "PROFILE • SHOP • MISSIONS", UDim2.fromScale(0.52, 0.05), UDim2.fromScale(0.035, 0.092), Enum.Font.Gotham, 9)
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

local tabShop = button(tabs, "ShopTab", "SHOP", UDim2.fromScale(0.30, 0.85), UDim2.fromScale(0, 0))
local tabQuest = button(tabs, "QuestTab", "MISSIONS", UDim2.fromScale(0.30, 0.85), UDim2.fromScale(0.35, 0))
local tabEmote = button(tabs, "EmoteTab", "EMOTES", UDim2.fromScale(0.30, 0.85), UDim2.fromScale(0.70, 0))

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.fromScale(0.94, 0.71)
content.Position = UDim2.fromScale(0.03, 0.245)
content.BackgroundTransparency = 1
content.Parent = panel

local state = {
    economy = {Credits = 0, OwnedEmotes = {}, OwnedSkins = {}, EquippedEmote = "", EquippedSkin = ""},
    quests = {Daily = {}, Weekly = {}, General = {}, Totals = {Daily = 24, Weekly = 24, General = 24}},
    activeTab = "Shop",
    shopCategory = "Emotes"
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

local function itemButton(parent: Instance, item, owned: boolean, equipped: boolean, category: string)
    local right = owned and (equipped and "EQUIPPED" or "OWNED") or (tostring(item.Price) .. " C")
    local b = button(parent, item.Id, "", UDim2.new(1, -8, 0, 58), UDim2.new())
    b.LayoutOrder = tonumber(item.Id:match("%d+")) or 0

    local name = label(b, item.Name, UDim2.new(0.64, 0, 0.56, 0), UDim2.fromScale(0.025, 0.04), Enum.Font.GothamBold, 13)
    local rarity = label(b, item.Rarity or "ITEM", UDim2.new(0.42, 0, 0.30, 0), UDim2.fromScale(0.025, 0.58), Enum.Font.Gotham, 9)
    rarity.TextColor3 = muted

    local action = label(b, right, UDim2.new(0.29, 0, 0.75, 0), UDim2.fromScale(0.68, 0.12), Enum.Font.GothamBlack, 12)
    action.TextXAlignment = Enum.TextXAlignment.Right
    action.TextColor3 = equipped and accent or (owned and successColor or textColor)

    b.Activated:Connect(function()
        if not owned then
            accountAction:FireServer("Buy", {category = category, id = item.Id})
        elseif category == "Emotes" then
            accountAction:FireServer("PlayEmote", {id = item.Id})
        else
            accountAction:FireServer("Equip", {category = category, id = item.Id})
        end
    end)

    return b
end

local function renderShop()
    clearContent()

    local categories = Instance.new("Frame")
    categories.Size = UDim2.fromScale(1, 0.11)
    categories.BackgroundTransparency = 1
    categories.Parent = content

    local emotesTab = button(categories, "Emotes", "EMOTES • 150", UDim2.fromScale(0.30, 0.9), UDim2.fromScale(0, 0))
    local skinsTab = button(categories, "Skins", "SKINS • 72", UDim2.fromScale(0.30, 0.9), UDim2.fromScale(0.32, 0))

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.fromScale(1, 0.87)
    list.Position = UDim2.fromScale(0, 0.13)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 5
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list

    local category = state.shopCategory
    local source = if category == "Emotes" then shop.Emotes else shop.Skins
    for _, item in pairs(source) do
        local owned = if category == "Emotes" then state.economy.OwnedEmotes[item.Id] == true else state.economy.OwnedSkins[item.Id] == true
        local equipped = if category == "Emotes" then state.economy.EquippedEmote == item.Id else state.economy.EquippedSkin == item.Id
        itemButton(list, item, owned, equipped, category)
    end

    emotesTab.Activated:Connect(function()
        state.shopCategory = "Emotes"
        renderShop()
    end)

    skinsTab.Activated:Connect(function()
        state.shopCategory = "Skins"
        renderShop()
    end)
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
    reward.TextColor3 = Color3.fromRGB(255, 213, 101)

    local status = label(frame, quest.Completed and "COMPLETED" or "ACTIVE", UDim2.fromScale(0.25, 0.18), UDim2.fromScale(0.70, 0.46), Enum.Font.GothamBold, 9)
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.TextColor3 = quest.Completed and successColor or muted
end

local function renderQuests()
    clearContent()

    local headerText = "DAILY • " .. tostring(state.quests.Totals.Daily or 24) .. "  |  WEEKLY • " .. tostring(state.quests.Totals.Weekly or 24) .. "  |  MASTERY • " .. tostring(state.quests.Totals.General or 24)
    local info = label(content, headerText, UDim2.fromScale(1, 0.07), UDim2.fromScale(0, 0), Enum.Font.GothamBold, 10)
    info.TextColor3 = muted
    info.TextXAlignment = Enum.TextXAlignment.Center

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.fromScale(1, 0.92)
    list.Position = UDim2.fromScale(0, 0.08)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 5
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = list

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

local function renderEmotes()
    clearContent()

    local info = label(content, "Owned emotes • tap to play", UDim2.fromScale(1, 0.08), UDim2.fromScale(0, 0), Enum.Font.GothamBold, 11)
    info.TextXAlignment = Enum.TextXAlignment.Center
    info.TextColor3 = muted

    local list = listFrame()
    local order = 0
    for id in pairs(state.economy.OwnedEmotes) do
        local item = shop.Emotes[id]
        if item then
            order += 1
            local b = itemButton(list, item, true, state.economy.EquippedEmote == id, "Emotes")
            b.LayoutOrder = order
        end
    end

    if order == 0 then
        local empty = label(list, "No emotes owned.", UDim2.new(1, -8, 0, 40), UDim2.new(), Enum.Font.Gotham, 12)
        empty.TextColor3 = muted
    end
end

local function render()
    if state.activeTab == "Shop" then
        renderShop()
    elseif state.activeTab == "Quests" then
        renderQuests()
    else
        renderEmotes()
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

tabEmote.Activated:Connect(function()
    state.activeTab = "Emotes"
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

local function emoteVFX(accentColor: Color3, name: string)
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart or not rootPart:IsA("BasePart") then
        return
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "CursedCollisionEmoteFX"
    attachment.Parent = rootPart

    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new(accentColor, Color3.fromRGB(255, 255, 255))
    emitter.LightEmission = 0.85
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.5, 0.9)
    emitter.Speed = NumberRange.new(3, 7)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Parent = attachment
    emitter:Emit(18)

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromOffset(230, 48)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = rootPart

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 0.18
    text.BackgroundColor3 = panelColor
    text.Text = string.upper(name)
    text.TextColor3 = accentColor
    text.Font = Enum.Font.GothamBlack
    text.TextScaled = true
    text.Parent = billboard
    corner(text, 10)
    stroke(text, accentColor, 1)

    TweenService:Create(text, TweenInfo.new(0.65), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
    Debris:AddItem(attachment, 1)
    Debris:AddItem(billboard, 1)
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
        local ownerPanelOpen = player:GetAttribute("CCHUD_OwnerPanelOpen") == true
        if ownerPanelOpen then
            return
        end

        local message = payload and payload.Message or ""
        if message ~= "" then
            local toast = label(gui, message, UDim2.fromScale(0.56, 0.06), UDim2.fromScale(0.22, 0.91), Enum.Font.GothamBold, 13)
            toast.TextXAlignment = Enum.TextXAlignment.Center
            toast.BackgroundTransparency = 0.12
            toast.BackgroundColor3 = payload.Success and Color3.fromRGB(22, 54, 37) or Color3.fromRGB(63, 25, 34)
            toast.TextColor3 = payload.Success and successColor or errorColor
            corner(toast, 9)
            Debris:AddItem(toast, 2.2)
        end

    elseif event == "Platform" then
        platformLabel.Text = tostring(payload or "PC")

    elseif event == "PlayEmote" then
        local info = payload or {}
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            task.spawn(function()
                local played = false
                local animationId = tonumber(info.AnimationId) or 0

                if animationId > 0 then
                    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
                    animator.Parent = humanoid

                    local animation = Instance.new("Animation")
                    animation.AnimationId = "rbxassetid://" .. tostring(animationId)

                    local ok, track = pcall(function()
                        return animator:LoadAnimation(animation)
                    end)

                    if ok and track then
                        track:Play()
                        played = true
                        task.delay(10, function()
                            if track.IsPlaying then
                                track:Stop(0.15)
                            end
                            animation:Destroy()
                        end)
                    else
                        animation:Destroy()
                    end
                end

                if not played then
                    pcall(function()
                        humanoid:PlayEmoteAsync(info.Animation or "Wave")
                    end)
                end
            end)
        end

        emoteVFX(info.Accent or accent, info.Name or "EMOTE")
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
updatePlatformLabel()
setMenuOpen(false)
accountAction:FireServer("Sync", {})
