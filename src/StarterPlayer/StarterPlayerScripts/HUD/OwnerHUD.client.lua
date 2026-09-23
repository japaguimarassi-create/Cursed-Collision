--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.HUDTheme)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local admin = remotes and remotes:WaitForChild("AdminAction", 15)
if not admin then
    return
end

local gui = Theme.CreateGui("CursedCollisionHUD_Owner", 80)
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

local panel = Theme.Panel(root, "OwnerPanel", UDim2.fromScale(0.84, 0.74))
panel.Visible = false

local title = Theme.Label(panel, "Title", "OWNER CONTROL", UDim2.fromScale(0.62, 0.08), UDim2.fromScale(0.04, 0.04), 20)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack
title.TextColor3 = Theme.Colors.Warning

local close = Theme.Button(panel, "Close", "×", UDim2.fromOffset(52, 44), UDim2.fromScale(0.94, 0.04), 44)
close.AnchorPoint = Vector2.new(1, 0)
close.TextSize = 21

local amount = Instance.new("TextBox")
amount.Size = UDim2.fromScale(0.34, 0.075)
amount.Position = UDim2.fromScale(0.05, 0.16)
amount.Text = "1000"
amount.PlaceholderText = "Amount"
amount.TextColor3 = Theme.Colors.Text
amount.BackgroundColor3 = Theme.Colors.Surface2
amount.BorderSizePixel = 0
amount.ClearTextOnFocus = false
amount.Font = Enum.Font.Gotham
amount.TextSize = 12
amount.Parent = panel
Theme.Corner(amount, 10)

local list = Instance.new("Frame")
list.Size = UDim2.fromScale(0.88, 0.65)
list.Position = UDim2.fromScale(0.06, 0.27)
list.BackgroundTransparency = 1
list.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.48, 0, 0.17, 0)
grid.CellPadding = UDim2.fromOffset(8, 8)
grid.Parent = list

local function send(name: string, extra: {[string]: any}?)
    if player:GetAttribute("IsGameOwner") ~= true then
        return
    end

    local payload = extra or {}
    payload.targetUserId = player.UserId
    admin:FireServer(name, payload)
end

local actions = {
    {"GrantCredits", "GIVE CREDITS"},
    {"SetCredits", "SET CREDITS"},
    {"RemoveCredits", "REMOVE CREDITS"},
    {"GiveAllEmotes", "GIVE 150 EMOTES"},
    {"GiveAllSkins", "GIVE SKINS"},
    {"Heal", "HEAL SELF"},
    {"SaveAll", "SAVE ALL"},
    {"Kick", "KICK SELF"}
}

for _, data in ipairs(actions) do
    local key, text = data[1], data[2]
    local button = Theme.Button(list, key, text, UDim2.new(), UDim2.new(), 56)
    button.TextSize = 9
    button.Activated:Connect(function()
        local extra: {[string]: any} = {}
        if key == "GrantCredits" or key == "SetCredits" or key == "RemoveCredits" then
            extra.amount = tonumber(amount.Text) or 0
        elseif key == "Kick" then
            extra.reason = "Removed by Cursed Collision Owner."
        end
        send(key, extra)
    end)
end

local function closePanel()
    panel.Visible = false
    backdrop.Visible = false
    player:SetAttribute("CCHUD_OwnerPanelOpen", false)
end

local function openPanel()
    if player:GetAttribute("IsGameOwner") ~= true then
        closePanel()
        return
    end

    player:SetAttribute("CCHUD_MenuOpen", false)
    player:SetAttribute("CCHUD_CharacterMenuOpen", false)
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
    player:SetAttribute("CCHUD_SettingsOpen", false)
    player:SetAttribute("CCHUD_OwnerPanelOpen", true)
    panel.Visible = true
    backdrop.Visible = true
end

close.Activated:Connect(closePanel)
backdrop.Activated:Connect(closePanel)

player:GetAttributeChangedSignal("CCHUD_OwnerPanelOpen"):Connect(function()
    if player:GetAttribute("CCHUD_OwnerPanelOpen") == true then
        openPanel()
    else
        closePanel()
    end
end)

player:GetAttributeChangedSignal("IsGameOwner"):Connect(function()
    if player:GetAttribute("IsGameOwner") ~= true then
        closePanel()
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.P and player:GetAttribute("IsGameOwner") == true then
        if panel.Visible then closePanel() else openPanel() end
    end
end)
