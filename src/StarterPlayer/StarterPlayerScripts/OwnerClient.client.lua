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
local adminAction = remotes:WaitForChild("AdminAction", 15)
if not accountAction or not accountEvent or not adminAction then
    return
end

local oldGui = playerGui:FindFirstChild("CursedCollisionOwnerUI")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionOwnerUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local accent = Color3.fromRGB(255, 177, 76)
local panelColor = Color3.fromRGB(11, 12, 17)
local textColor = Color3.fromRGB(240, 241, 246)
local muted = Color3.fromRGB(158, 161, 177)
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
    s.Transparency = 0.24
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
    b.BackgroundTransparency = 0.04
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextColor3 = textColor
    b.AutoButtonColor = true
    b.Active = true
    b.Selectable = true
    b.Parent = parent
    corner(b, 10)
    stroke(b, Color3.fromRGB(82, 84, 101), 1)
    return b
end

local ownerButton = button(gui, "OwnerButton", "OWNER", UDim2.fromScale(0.105, 0.06), UDim2.fromScale(0.755, 0.022))
ownerButton.TextColor3 = accent
ownerButton.Visible = false

local panel = Instance.new("Frame")
panel.Name = "OwnerPanel"
panel.Size = UDim2.fromScale(0.90, 0.82)
panel.Position = UDim2.fromScale(0.50, 0.51)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = panelColor
panel.BackgroundTransparency = 0.02
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
corner(panel, 18)
stroke(panel, accent, 1.6)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(300, 480)
sizeConstraint.MaxSize = Vector2.new(920, 740)
sizeConstraint.Parent = panel

local panelScale = Instance.new("UIScale")
panelScale.Scale = 0.96
panelScale.Parent = panel

label(panel, "OWNER CONTROL", UDim2.fromScale(0.55, 0.075), UDim2.fromScale(0.035, 0.025), Enum.Font.GothamBlack, 20)
local subtitle = label(panel, "SERVER-AUTHORIZED • OWNER ONLY", UDim2.fromScale(0.60, 0.05), UDim2.fromScale(0.035, 0.092), Enum.Font.Gotham, 9)
subtitle.TextColor3 = muted

local close = button(panel, "Close", "×", UDim2.fromScale(0.07, 0.075), UDim2.fromScale(0.92, 0.025))
close.TextSize = 22

local selectedLabel = label(panel, "TARGET: SELF", UDim2.fromScale(0.64, 0.06), UDim2.fromScale(0.035, 0.145), Enum.Font.GothamBlack, 12)
selectedLabel.TextColor3 = accent

local targetFrame = Instance.new("ScrollingFrame")
targetFrame.Name = "Players"
targetFrame.Size = UDim2.fromScale(0.34, 0.73)
targetFrame.Position = UDim2.fromScale(0.035, 0.22)
targetFrame.BackgroundTransparency = 1
targetFrame.BorderSizePixel = 0
targetFrame.ScrollBarThickness = 4
targetFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
targetFrame.CanvasSize = UDim2.fromOffset(0, 0)
targetFrame.Parent = panel

local targetLayout = Instance.new("UIListLayout")
targetLayout.Padding = UDim.new(0, 7)
targetLayout.SortOrder = Enum.SortOrder.LayoutOrder
targetLayout.Parent = targetFrame

local toolsFrame = Instance.new("Frame")
toolsFrame.Name = "Actions"
toolsFrame.Size = UDim2.fromScale(0.59, 0.73)
toolsFrame.Position = UDim2.fromScale(0.39, 0.22)
toolsFrame.BackgroundTransparency = 1
toolsFrame.Parent = panel

local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.fromScale(0.47, 0.10)
amountBox.Position = UDim2.fromScale(0, 0)
amountBox.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
amountBox.BorderSizePixel = 0
amountBox.TextColor3 = textColor
amountBox.PlaceholderText = "Amount"
amountBox.Text = "1000"
amountBox.Font = Enum.Font.Gotham
amountBox.TextSize = 13
amountBox.ClearTextOnFocus = false
amountBox.Parent = toolsFrame
corner(amountBox, 9)
stroke(amountBox, Color3.fromRGB(68, 71, 88), 1)

local function actionButton(name: string, textValue: string, x: number, y: number)
    local b = button(toolsFrame, name, textValue, UDim2.fromScale(0.46, 0.105), UDim2.fromScale(x, y))
    return b
end

local selectedUserId = player.UserId
local actionButtons = {}

actionButtons.GrantCredits = actionButton("GrantCredits", "GIVE CREDITS", 0, 0.13)
actionButtons.SetCredits = actionButton("SetCredits", "SET CREDITS", 0, 0.26)
actionButtons.RemoveCredits = actionButton("RemoveCredits", "REMOVE CREDITS", 0, 0.39)
actionButtons.GiveAllEmotes = actionButton("GiveAllEmotes", "GIVE 150 EMOTES", 0, 0.52)
actionButtons.GiveAllSkins = actionButton("GiveAllSkins", "GIVE SKINS", 0, 0.65)
actionButtons.Heal = actionButton("Heal", "HEAL TARGET", 0.51, 0.13)
actionButtons.ResetQuests = actionButton("ResetQuests", "RESET QUESTS", 0.51, 0.26)
actionButtons.SaveAll = actionButton("SaveAll", "SAVE ALL", 0.51, 0.39)

local questIdBox = Instance.new("TextBox")
questIdBox.Size = UDim2.fromScale(0.97, 0.10)
questIdBox.Position = UDim2.fromScale(0, 0.52)
questIdBox.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
questIdBox.BorderSizePixel = 0
questIdBox.TextColor3 = textColor
questIdBox.PlaceholderText = "Quest ID"
questIdBox.Text = ""
questIdBox.Font = Enum.Font.Gotham
questIdBox.TextSize = 12
questIdBox.ClearTextOnFocus = false
questIdBox.Parent = toolsFrame
corner(questIdBox, 9)
stroke(questIdBox, Color3.fromRGB(68, 71, 88), 1)

local completeQuest = actionButton("CompleteQuest", "COMPLETE QUEST", 0, 0.65)

local announcement = Instance.new("TextBox")
announcement.Size = UDim2.fromScale(0.97, 0.13)
announcement.Position = UDim2.fromScale(0, 0.78)
announcement.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
announcement.BorderSizePixel = 0
announcement.TextColor3 = textColor
announcement.PlaceholderText = "Owner broadcast..."
announcement.Text = ""
announcement.Font = Enum.Font.Gotham
announcement.TextSize = 12
announcement.TextWrapped = true
announcement.TextYAlignment = Enum.TextYAlignment.Top
announcement.ClearTextOnFocus = false
announcement.Parent = toolsFrame
corner(announcement, 9)
stroke(announcement, Color3.fromRGB(68, 71, 88), 1)

local broadcast = actionButton("Broadcast", "BROADCAST", 0, 0.93)
local kick = actionButton("Kick", "KICK TARGET", 0.51, 0.93)

local playerList = {}

local function send(action: string, payload: {[string]: any}?)
    payload = payload or {}
    payload.targetUserId = selectedUserId
    adminAction:FireServer(action, payload)
end

actionButtons.GrantCredits.Activated:Connect(function()
    send("GrantCredits", {amount = tonumber(amountBox.Text) or 0})
end)

actionButtons.SetCredits.Activated:Connect(function()
    send("SetCredits", {amount = tonumber(amountBox.Text) or 0})
end)

actionButtons.RemoveCredits.Activated:Connect(function()
    send("RemoveCredits", {amount = tonumber(amountBox.Text) or 0})
end)

actionButtons.GiveAllEmotes.Activated:Connect(function()
    send("GiveAllEmotes")
end)

actionButtons.GiveAllSkins.Activated:Connect(function()
    send("GiveAllSkins")
end)

actionButtons.Heal.Activated:Connect(function()
    send("Heal")
end)

actionButtons.ResetQuests.Activated:Connect(function()
    send("ResetQuests")
end)

actionButtons.SaveAll.Activated:Connect(function()
    send("SaveAll", {targetUserId = player.UserId})
end)

completeQuest.Activated:Connect(function()
    send("CompleteQuest", {questId = questIdBox.Text})
    questIdBox.Text = ""
end)

broadcast.Activated:Connect(function()
    adminAction:FireServer("Announce", {message = announcement.Text})
    announcement.Text = ""
end)

kick.Activated:Connect(function()
    send("Kick", {reason = "Removed by Cursed Collision Owner."})
end)

local function renderTargets()
    for _, child in ipairs(targetFrame:GetChildren()) do
        if child:IsA("GuiButton") then
            child:Destroy()
        end
    end

    for index, info in ipairs(playerList) do
        local isSelected = info.UserId == selectedUserId
        local b = button(
            targetFrame,
            "Target_" .. tostring(info.UserId),
            (isSelected and "• " or "") .. info.DisplayName .. "  @" .. info.Name,
            UDim2.new(1, -5, 0, 44),
            UDim2.new()
        )
        b.LayoutOrder = index
        if isSelected then
            b.TextColor3 = accent
        end

        b.Activated:Connect(function()
            selectedUserId = info.UserId
            selectedLabel.Text = "TARGET: " .. info.Name
            renderTargets()
        end)
    end
end

local function setOwnerVisible(visible: boolean)
    ownerButton.Visible = visible
    if not visible then
        panel.Visible = false
        player:SetAttribute("CCHUD_OwnerPanelOpen", false)
    end
end

local function setMenuOpen(open: boolean)
    player:SetAttribute("CCHUD_OwnerPanelOpen", open)
    if open then
        player:SetAttribute("CCHUD_MenuOpen", true)
    elseif player:GetAttribute("CCHUD_MenuOpen") == true then
        player:SetAttribute("CCHUD_MenuOpen", false)
    end
end

local function closeMainMenu()
    local accountGui = playerGui:FindFirstChild("CursedCollisionAccountUI")
    local accountPanel = accountGui and accountGui:FindFirstChild("AccountPanel")
    if accountPanel and accountPanel:IsA("GuiObject") then
        accountPanel.Visible = false
    end
end

local function toggle()
    if player:GetAttribute("IsGameOwner") ~= true then
        setOwnerVisible(false)
        return
    end

    if panel.Visible then
        panel.Visible = false
        setMenuOpen(false)
        return
    end

    closeMainMenu()
    setMenuOpen(true)
    accountAction:FireServer("SyncOwner", {})
    panelScale.Scale = 0.96
    panel.Visible = true
    TweenService:Create(panelScale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    GuiService.SelectedObject = targetFrame
end

ownerButton.Activated:Connect(toggle)

close.Activated:Connect(function()
    panel.Visible = false
    setMenuOpen(false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.UserInputType == Enum.UserInputType.Gamepad1
        and input.KeyCode == Enum.KeyCode.ButtonBack
        and panel.Visible then
        panel.Visible = false
        setMenuOpen(false)
    end
end)

accountEvent.OnClientEvent:Connect(function(event, payload)
    if event == "Sync" then
        setOwnerVisible(payload and payload.IsOwner == true)

    elseif event == "AdminPlayers" then
        playerList = payload or {}
        if panel.Visible then
            renderTargets()
        end

    elseif event == "Notice" then
        if player:GetAttribute("CCHUD_OwnerPanelOpen") ~= true then
            return
        end

        local message = payload and payload.Message or ""
        if message == "" then
            return
        end

        local toast = label(gui, message, UDim2.fromScale(0.54, 0.055), UDim2.fromScale(0.23, 0.90), Enum.Font.GothamBold, 12)
        toast.TextXAlignment = Enum.TextXAlignment.Center
        toast.BackgroundTransparency = 0.10
        toast.BackgroundColor3 = payload.Success and Color3.fromRGB(22, 54, 37) or Color3.fromRGB(63, 25, 34)
        toast.TextColor3 = payload.Success and successColor or errorColor
        corner(toast, 9)
        Debris:AddItem(toast, 2.4)
    end
end)

local function refreshOwner()
    setOwnerVisible(player:GetAttribute("IsGameOwner") == true)
end

player:GetAttributeChangedSignal("IsGameOwner"):Connect(refreshOwner)
refreshOwner()
setMenuOpen(false)
if player:GetAttribute("IsGameOwner") == true then
    accountAction:FireServer("SyncOwner", {})
end
renderTargets()
