local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local accountAction = remotes:WaitForChild("AccountAction")
local accountEvent = remotes:WaitForChild("AccountEvent")
local shop = require(ReplicatedStorage.Economy.ShopDefinitions)

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionAccountUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local accent = Color3.fromRGB(155, 112, 255)
local panelColor = Color3.fromRGB(10, 12, 18)
local textColor = Color3.fromRGB(236, 237, 244)
local muted = Color3.fromRGB(155, 158, 176)
local successColor = Color3.fromRGB(104, 222, 148)
local errorColor = Color3.fromRGB(235, 82, 102)

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = 0.28
    s.Parent = parent
end

local function label(parent, text, size, position, font, textSize)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.Size = size
    l.Position = position
    l.Font = font or Enum.Font.Gotham
    l.TextSize = textSize or 15
    l.TextColor3 = textColor
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function button(parent, name, text, size, position)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = text
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = Color3.fromRGB(24, 27, 37)
    b.BackgroundTransparency = 0.05
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextColor3 = textColor
    b.AutoButtonColor = true
    b.Selectable = true
    b.Parent = parent
    corner(b, 10)
    stroke(b, Color3.fromRGB(78, 82, 102), 1)
    return b
end

local menuButton = button(gui, "AccountMenu", "MENU", UDim2.fromScale(0.075, 0.06), UDim2.fromScale(0.91, 0.025))
menuButton.TextSize = 12

local panel = Instance.new("Frame")
panel.Name = "AccountPanel"
panel.Size = UDim2.fromScale(0.86, 0.80)
panel.Position = UDim2.fromScale(0.50, 0.51)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = panelColor
panel.BackgroundTransparency = 0.02
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
corner(panel, 18)
stroke(panel, accent, 1.5)

local header = label(panel, "PROFILE • SHOP • MISSIONS", UDim2.fromScale(0.65, 0.08), UDim2.fromScale(0.035, 0.025), Enum.Font.GothamBlack, 19)
local creditsLabel = label(panel, "500 CREDITS", UDim2.fromScale(0.24, 0.06), UDim2.fromScale(0.68, 0.028), Enum.Font.GothamBold, 14)
creditsLabel.TextXAlignment = Enum.TextXAlignment.Right
local platformLabel = label(panel, "PC", UDim2.fromScale(0.30, 0.045), UDim2.fromScale(0.68, 0.085), Enum.Font.Gotham, 11)
platformLabel.TextXAlignment = Enum.TextXAlignment.Right
platformLabel.TextColor3 = muted

local close = button(panel, "Close", "×", UDim2.fromScale(0.07, 0.075), UDim2.fromScale(0.92, 0.025))
close.TextSize = 22

local tabs = Instance.new("Frame")
tabs.Size = UDim2.fromScale(0.94, 0.09)
tabs.Position = UDim2.fromScale(0.03, 0.13)
tabs.BackgroundTransparency = 1
tabs.Parent = panel

local tabShop = button(tabs, "ShopTab", "SHOP", UDim2.fromScale(0.22, 0.85), UDim2.fromScale(0, 0))
local tabQuest = button(tabs, "QuestTab", "MISSIONS", UDim2.fromScale(0.22, 0.85), UDim2.fromScale(0.245, 0))
local tabEmote = button(tabs, "EmoteTab", "EMOTES", UDim2.fromScale(0.22, 0.85), UDim2.fromScale(0.49, 0))
local tabAdmin = button(tabs, "AdminTab", "OWNER", UDim2.fromScale(0.22, 0.85), UDim2.fromScale(0.735, 0))
tabAdmin.Visible = false

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.fromScale(0.94, 0.74)
content.Position = UDim2.fromScale(0.03, 0.23)
content.BackgroundTransparency = 1
content.Parent = panel

local state = {
    economy = {Credits=0, OwnedEmotes={}, OwnedSkins={}, EquippedEmote="", EquippedSkin=""},
    quests = {Daily={}, Weekly={}, General={}, Totals={}},
    isOwner = false,
    adminPlayers = {},
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

local function itemButton(parent, item, owned, equipped, category)
    local text = item.Name
    local right = owned and (equipped and "EQUIPPED" or "OWNED") or (tostring(item.Price) .. " C")

    local b = button(parent, item.Id, "", UDim2.new(1, -8, 0, 58), UDim2.new())
    b.LayoutOrder = tonumber(item.Id:match("%d+")) or 0

    local name = label(b, text, UDim2.new(0.65, 0, 0.56, 0), UDim2.fromScale(0.025, 0.04), Enum.Font.GothamBold, 13)
    local rarity = label(b, item.Rarity or "ITEM", UDim2.new(0.42, 0, 0.30, 0), UDim2.fromScale(0.025, 0.58), Enum.Font.Gotham, 9)
    rarity.TextColor3 = muted

    local action = label(b, right, UDim2.new(0.29, 0, 0.75, 0), UDim2.fromScale(0.68, 0.12), Enum.Font.GothamBlack, 12)
    action.TextXAlignment = Enum.TextXAlignment.Right
    action.TextColor3 = equipped and accent or (owned and successColor or textColor)

    b.Activated:Connect(function()
        if not owned then
            accountAction:FireServer("Buy", {category=category, id=item.Id})
        elseif category == "Emotes" then
            accountAction:FireServer("PlayEmote", {id=item.Id})
        else
            accountAction:FireServer("Equip", {category=category, id=item.Id})
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

    if category == "Emotes" then
        for _, item in pairs(shop.Emotes) do
            itemButton(list, item, state.economy.OwnedEmotes[item.Id] == true, state.economy.EquippedEmote == item.Id, "Emotes")
        end
    else
        for _, item in pairs(shop.Skins) do
            itemButton(list, item, state.economy.OwnedSkins[item.Id] == true, state.economy.EquippedSkin == item.Id, "Skins")
        end
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

local function questCard(parent, quest)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 92)
    frame.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    corner(frame, 10)
    stroke(frame, Color3.fromRGB(69, 72, 90), 1)

    label(frame, quest.Name, UDim2.fromScale(0.66, 0.24), UDim2.fromScale(0.025, 0.07), Enum.Font.GothamBold, 12)
    local desc = label(frame, quest.Description, UDim2.fromScale(0.66, 0.33), UDim2.fromScale(0.025, 0.31), Enum.Font.Gotham, 10)
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

    local progressText = label(frame, tostring(progress).." / "..tostring(target), UDim2.fromScale(0.25, 0.20), UDim2.fromScale(0.60, 0.72), Enum.Font.GothamBold, 9)
    progressText.TextXAlignment = Enum.TextXAlignment.Right

    local reward = label(frame, "+"..tostring(quest.Reward).." C", UDim2.fromScale(0.25, 0.22), UDim2.fromScale(0.70, 0.20), Enum.Font.GothamBlack, 14)
    reward.TextXAlignment = Enum.TextXAlignment.Right
    reward.TextColor3 = Color3.fromRGB(255, 213, 101)

    local stateText = label(frame, quest.Completed and "COMPLETED" or "ACTIVE", UDim2.fromScale(0.25, 0.18), UDim2.fromScale(0.70, 0.46), Enum.Font.GothamBold, 9)
    stateText.TextXAlignment = Enum.TextXAlignment.Right
    stateText.TextColor3 = quest.Completed and successColor or muted
end

local function renderQuests()
    clearContent()

    local headerText = "DAILY • "..tostring(state.quests.Totals.Daily or 24).."  |  WEEKLY • "..tostring(state.quests.Totals.Weekly or 24).."  |  MASTERY • "..tostring(state.quests.Totals.General or 24)
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

    local function section(titleText, quests)
        local title = label(list, titleText, UDim2.new(1, -8, 0, 30), UDim2.new(), Enum.Font.GothamBlack, 14)
        title.LayoutOrder = 0
        title.TextColor3 = accent
        for _, quest in ipairs(quests or {}) do
            questCard(list, quest)
        end
    end

    section("DAILY", state.quests.Daily)
    section("WEEKLY", state.quests.Weekly)
    section("GENERAL / MASTERY", state.quests.General)
end

local function renderEmotes()
    clearContent()

    local info = label(content, "Owned emotes • tap to play • 150 collectible entries", UDim2.fromScale(1, 0.08), UDim2.fromScale(0, 0), Enum.Font.GothamBold, 11)
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
        label(list, "No emotes owned.", UDim2.new(1, -8, 0, 40), UDim2.new(), Enum.Font.Gotham, 12).TextColor3 = muted
    end
end

local function renderAdmin()
    clearContent()

    if not state.isOwner then
        label(content, "OWNER ONLY", UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0.3), Enum.Font.GothamBlack, 24).TextXAlignment = Enum.TextXAlignment.Center
        return
    end

    local selectedUserId = player.UserId
    local selectedLabel = label(content, "TARGET: "..player.Name, UDim2.fromScale(0.60, 0.07), UDim2.fromScale(0.02, 0), Enum.Font.GothamBlack, 13)

    local targetFrame = Instance.new("ScrollingFrame")
    targetFrame.Size = UDim2.fromScale(0.34, 0.85)
    targetFrame.Position = UDim2.fromScale(0, 0.10)
    targetFrame.BackgroundTransparency = 1
    targetFrame.BorderSizePixel = 0
    targetFrame.ScrollBarThickness = 4
    targetFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    targetFrame.CanvasSize = UDim2.fromOffset(0, 0)
    targetFrame.Parent = content

    local targetLayout = Instance.new("UIListLayout")
    targetLayout.Padding = UDim.new(0, 6)
    targetLayout.Parent = targetFrame

    for _, info in ipairs(state.adminPlayers) do
        local b = button(targetFrame, "Target_"..tostring(info.UserId), info.DisplayName.."  @"..info.Name, UDim2.new(1, -5, 0, 42), UDim2.new())
        b.Activated:Connect(function()
            selectedUserId = info.UserId
            selectedLabel.Text = "TARGET: "..info.Name
        end)
    end

    local toolsFrame = Instance.new("Frame")
    toolsFrame.Size = UDim2.fromScale(0.63, 0.84)
    toolsFrame.Position = UDim2.fromScale(0.37, 0.10)
    toolsFrame.BackgroundTransparency = 1
    toolsFrame.Parent = content

    local amountBox = Instance.new("TextBox")
    amountBox.Size = UDim2.fromScale(0.46, 0.11)
    amountBox.Position = UDim2.fromScale(0, 0)
    amountBox.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    amountBox.TextColor3 = textColor
    amountBox.PlaceholderText = "Amount"
    amountBox.Text = "1000"
    amountBox.Font = Enum.Font.Gotham
    amountBox.TextSize = 13
    amountBox.ClearTextOnFocus = false
    amountBox.Parent = toolsFrame
    corner(amountBox, 8)

    local function adminButton(text, action, y)
        local b = button(toolsFrame, "Admin_"..action, text, UDim2.fromScale(0.46, 0.11), UDim2.fromScale(0, y))
        b.Activated:Connect(function()
            accountAction.Parent = accountAction.Parent
            remotes.AdminAction:FireServer(action, {
                targetUserId = selectedUserId,
                amount = tonumber(amountBox.Text) or 0
            })
        end)
    end

    adminButton("GIVE CREDITS", "GrantCredits", 0.14)
    adminButton("SET CREDITS", "SetCredits", 0.27)
    adminButton("REMOVE CREDITS", "RemoveCredits", 0.40)
    adminButton("GIVE 150 EMOTES", "GiveAllEmotes", 0.53)
    adminButton("GIVE SKINS", "GiveAllSkins", 0.66)

    local heal = button(toolsFrame, "Admin_Heal", "HEAL TARGET", UDim2.fromScale(0.46, 0.11), UDim2.fromScale(0.51, 0.14))
    heal.Activated:Connect(function()
        remotes.AdminAction:FireServer("Heal", {targetUserId=selectedUserId})
    end)

    local reset = button(toolsFrame, "Admin_Reset", "RESET QUESTS", UDim2.fromScale(0.46, 0.11), UDim2.fromScale(0.51, 0.27))
    reset.Activated:Connect(function()
        remotes.AdminAction:FireServer("ResetQuests", {targetUserId=selectedUserId})
    end)

    local save = button(toolsFrame, "Admin_Save", "SAVE ALL", UDim2.fromScale(0.46, 0.11), UDim2.fromScale(0.51, 0.40))
    save.Activated:Connect(function()
        remotes.AdminAction:FireServer("SaveAll", {})
    end)

    local announcement = Instance.new("TextBox")
    announcement.Size = UDim2.fromScale(0.97, 0.15)
    announcement.Position = UDim2.fromScale(0, 0.56)
    announcement.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    announcement.TextColor3 = textColor
    announcement.PlaceholderText = "Global owner announcement..."
    announcement.Text = ""
    announcement.Font = Enum.Font.Gotham
    announcement.TextSize = 12
    announcement.TextWrapped = true
    announcement.ClearTextOnFocus = false
    announcement.Parent = toolsFrame
    corner(announcement, 8)

    local send = button(toolsFrame, "Admin_Announce", "BROADCAST", UDim2.fromScale(0.46, 0.11), UDim2.fromScale(0, 0.74))
    send.Activated:Connect(function()
        remotes.AdminAction:FireServer("Announce", {message=announcement.Text})
        announcement.Text = ""
    end)

    local kick = button(toolsFrame, "Admin_Kick", "KICK TARGET", UDim2.fromScale(0.46, 0.11), UDim2.fromScale(0.51, 0.74))
    kick.Activated:Connect(function()
        remotes.AdminAction:FireServer("Kick", {targetUserId=selectedUserId, reason="Removed by Cursed Collision Owner."})
    end)
end

local function render()
    if state.activeTab == "Shop" then
        renderShop()
    elseif state.activeTab == "Quests" then
        renderQuests()
    elseif state.activeTab == "Emotes" then
        renderEmotes()
    elseif state.activeTab == "Admin" then
        renderAdmin()
    end
end

local function selectTab(name)
    state.activeTab = name
    render()
end

tabShop.Activated:Connect(function() selectTab("Shop") end)
tabQuest.Activated:Connect(function() selectTab("Quests") end)
tabEmote.Activated:Connect(function() selectTab("Emotes") end)
tabAdmin.Activated:Connect(function() selectTab("Admin") end)

menuButton.Activated:Connect(function()
    panel.Visible = not panel.Visible
    if panel.Visible then
        accountAction:FireServer("Sync", {})
        if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
            GuiService.SelectedObject = tabShop
        end
        render()
    end
end)

close.Activated:Connect(function()
    panel.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonStart then
        panel.Visible = not panel.Visible
        if panel.Visible then
            accountAction:FireServer("Sync", {})
            GuiService.SelectedObject = tabShop
            render()
        end
    end
end)

local function emoteVFX(accentColor, name)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "CursedCollisionEmoteFX"
    attachment.Parent = root

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
    billboard.Parent = root

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

    TweenService:Create(text, TweenInfo.new(0.65), {
        BackgroundTransparency = 1,
        TextTransparency = 1
    }):Play()

    game:GetService("Debris"):AddItem(attachment, 1)
    game:GetService("Debris"):AddItem(billboard, 1)
end

accountEvent.OnClientEvent:Connect(function(event, payload)
    if event == "Sync" then
        state.economy = payload.Economy or state.economy
        state.quests = payload.Quests or state.quests
        state.isOwner = payload.IsOwner == true
        player:SetAttribute("IsGameOwner", state.isOwner)
        creditsLabel.Text = tostring(state.economy.Credits or 0).." CREDITS"
        tabAdmin.Visible = state.isOwner
        if panel.Visible then
            render()
        end

    elseif event == "Notice" then
        local message = payload and payload.Message or ""
        if message ~= "" then
            local toast = label(gui, message, UDim2.fromScale(0.54, 0.06), UDim2.fromScale(0.23, 0.91), Enum.Font.GothamBold, 13)
            toast.TextXAlignment = Enum.TextXAlignment.Center
            toast.BackgroundTransparency = 0.12
            toast.BackgroundColor3 = payload.Success and Color3.fromRGB(22, 54, 37) or Color3.fromRGB(63, 25, 34)
            toast.TextColor3 = payload.Success and successColor or errorColor
            corner(toast, 9)
            game:GetService("Debris"):AddItem(toast, 2.2)
        end

    elseif event == "AdminPlayers" then
        state.adminPlayers = payload or {}
        if panel.Visible and state.activeTab == "Admin" then
            render()
        end

    elseif event == "Platform" then
        platformLabel.Text = tostring(payload or "PC")

    elseif event == "PlayEmote" then
        local info = payload or {}
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            task.spawn(function()
                pcall(function()
                    humanoid:PlayEmoteAsync(info.Animation or "Wave")
                end)
            end)
        end
        emoteVFX(info.Accent or accent, info.Name or "EMOTE")
    end
end)

player:GetAttributeChangedSignal("IsGameOwner"):Connect(function()
    state.isOwner = player:GetAttribute("IsGameOwner") == true
    tabAdmin.Visible = state.isOwner
end)

platformLabel.Text = UserInputService.PreferredInput == Enum.PreferredInput.Touch and "MOBILE" or UserInputService.PreferredInput == Enum.PreferredInput.Gamepad and "CONSOLE" or "PC"
accountAction:FireServer("Sync", {})
