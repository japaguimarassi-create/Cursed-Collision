--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(script.Parent.Util)

local player = Players.LocalPlayer
local M = {}
local started = false

function M.Start()
    if started then return end
    started = true

    local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
    if not remotes then return end

    local adminAction = remotes:WaitForChild("AdminAction", 15)
    local accountAction = remotes:WaitForChild("AccountAction", 15)
    if not adminAction or not accountAction then return end

    local gui = Util.makeGui("CursedCollisionOwnerUI", 30)
    local root = Util.makeRoot(gui)

    local ownerButton = Util.button(root, "OwnerButton", "◆", UDim2.fromScale(0.060, 0.052), UDim2.fromScale(0.845, 0.020), true)
    ownerButton.TextSize = 17
    ownerButton.Visible = player:GetAttribute("IsGameOwner") == true

    local panel = Instance.new("Frame")
    panel.Name = "OwnerPanel"
    panel.Size = UDim2.fromScale(0.86, 0.80)
    panel.Position = UDim2.fromScale(0.50, 0.51)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = root
    Util.corner(panel, 16)
    Util.stroke(panel, Color3.fromRGB(255, 177, 76), 0.48, 1.5)

    local title = Util.label(panel, "OWNER CONTROL", UDim2.fromScale(0.50, 0.07), UDim2.fromScale(0.035, 0.025), 18, Enum.Font.GothamBlack)
    title.TextColor3 = Color3.fromRGB(255, 190, 102)
    title.TextXAlignment = Enum.TextXAlignment.Left

    local subtitle = Util.label(panel, "SERVER AUTHORIZED", UDim2.fromScale(0.40, 0.045), UDim2.fromScale(0.035, 0.093), 8)
    subtitle.TextColor3 = Util.Colors.Muted
    subtitle.TextXAlignment = Enum.TextXAlignment.Left

    local close = Util.button(panel, "Close", "×", UDim2.fromScale(0.062, 0.078), UDim2.fromScale(0.923, 0.022), true)
    close.TextSize = 22

    local targetLabel = Util.label(panel, "TARGET: SELF", UDim2.fromScale(0.40, 0.055), UDim2.fromScale(0.035, 0.155), 10, Enum.Font.GothamBlack)
    targetLabel.TextColor3 = Color3.fromRGB(255, 190, 102)
    targetLabel.TextXAlignment = Enum.TextXAlignment.Left

    local targets = Instance.new("ScrollingFrame")
    targets.Size = UDim2.fromScale(0.34, 0.66)
    targets.Position = UDim2.fromScale(0.035, 0.235)
    targets.BackgroundTransparency = 1
    targets.BorderSizePixel = 0
    targets.ScrollBarThickness = 4
    targets.AutomaticCanvasSize = Enum.AutomaticSize.Y
    targets.CanvasSize = UDim2.fromOffset(0, 0)
    targets.Parent = panel

    local targetLayout = Instance.new("UIListLayout")
    targetLayout.Padding = UDim.new(0, 7)
    targetLayout.SortOrder = Enum.SortOrder.LayoutOrder
    targetLayout.Parent = targets

    local actions = Instance.new("Frame")
    actions.Size = UDim2.fromScale(0.56, 0.66)
    actions.Position = UDim2.fromScale(0.405, 0.235)
    actions.BackgroundTransparency = 1
    actions.Parent = panel

    local amount = Instance.new("TextBox")
    amount.Size = UDim2.fromScale(0.46, 0.10)
    amount.Position = UDim2.fromScale(0, 0)
    amount.BackgroundColor3 = Util.Colors.PanelSoft
    amount.BorderSizePixel = 0
    amount.TextColor3 = Util.Colors.Text
    amount.Text = "1000"
    amount.PlaceholderText = "Amount"
    amount.Font = Enum.Font.Gotham
    amount.TextSize = 11
    amount.ClearTextOnFocus = false
    amount.Selectable = true
    amount.Parent = actions
    Util.corner(amount, 8)

    local function actionButton(name: string, text: string, x: number, y: number): TextButton
        return Util.button(actions, name, text, UDim2.fromScale(0.46, 0.105), UDim2.fromScale(x, y), true)
    end

    local buttons = {
        Grant = actionButton("Grant", "GIVE CREDITS", 0, 0.14),
        Set = actionButton("Set", "SET CREDITS", 0, 0.27),
        Remove = actionButton("Remove", "REMOVE", 0, 0.40),
        Emotes = actionButton("Emotes", "GIVE EMOTES", 0, 0.53),
        Skins = actionButton("Skins", "GIVE SKINS", 0, 0.66),
        Heal = actionButton("Heal", "HEAL", 0.51, 0.14),
        Reset = actionButton("Reset", "RESET QUESTS", 0.51, 0.27),
        Save = actionButton("Save", "SAVE ALL", 0.51, 0.40),
        Kick = actionButton("Kick", "KICK", 0.51, 0.66)
    }

    local selectedUserId = player.UserId
    local playersList: {Player} = {}

    local function send(action: string, payload: {[string]: any}?)
        local data = {} :: {[string]: any}
        if payload ~= nil then
            for key, value in pairs(payload) do
                data[key] = value
            end
        end
        data.targetUserId = selectedUserId
        adminAction:FireServer(action, data)
    end

    buttons.Grant.Activated:Connect(function()
        send("GrantCredits", {amount = tonumber(amount.Text) or 0})
    end)
    buttons.Set.Activated:Connect(function()
        send("SetCredits", {amount = tonumber(amount.Text) or 0})
    end)
    buttons.Remove.Activated:Connect(function()
        send("RemoveCredits", {amount = tonumber(amount.Text) or 0})
    end)
    buttons.Emotes.Activated:Connect(function()
        send("GiveAllEmotes")
    end)
    buttons.Skins.Activated:Connect(function()
        send("GiveAllSkins")
    end)
    buttons.Heal.Activated:Connect(function()
        send("Heal")
    end)
    buttons.Reset.Activated:Connect(function()
        send("ResetQuests")
    end)
    buttons.Save.Activated:Connect(function()
        send("SaveAll")
    end)
    buttons.Kick.Activated:Connect(function()
        send("Kick", {reason = "Removed by Cursed Collision Owner."})
    end)

    local function renderTargets()
        for _, child in ipairs(targets:GetChildren()) do
            if child:IsA("GuiButton") then
                child:Destroy()
            end
        end

        playersList = Players:GetPlayers()

        for index, target in ipairs(playersList) do
            local selected = target.UserId == selectedUserId
            local buttonTarget = Util.button(
                targets,
                "Target_" .. target.UserId,
                (selected and "◆ " or "") .. target.DisplayName .. "\n@" .. target.Name,
                UDim2.new(1, -4, 0, 50),
                UDim2.new(),
                true
            )
            buttonTarget.LayoutOrder = index
            buttonTarget.TextXAlignment = Enum.TextXAlignment.Left
            buttonTarget.TextColor3 = selected and Color3.fromRGB(255, 190, 102) or Util.Colors.Text
            buttonTarget.Activated:Connect(function()
                selectedUserId = target.UserId
                targetLabel.Text = "TARGET: " .. target.Name
                renderTargets()
            end)
        end
    end

    local function setOpen(open: boolean)
        panel.Visible = open
        Util.setMenuAttributes("Owner", open)

        if open then
            Util.closeKnownPanels("Owner")
            Util.setMenuAttributes("Owner", true)
            Util.setGamepadNavigation(true)
            GuiService.SelectedObject = targets:FindFirstChildWhichIsA("GuiButton")
        end
    end

    ownerButton.Activated:Connect(function()
        if player:GetAttribute("IsGameOwner") ~= true then
            ownerButton.Visible = false
            return
        end
        setOpen(not panel.Visible)
    end)

    close.Activated:Connect(function()
        setOpen(false)
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.O then
            if player:GetAttribute("IsGameOwner") == true then
                setOpen(not panel.Visible)
            end
        end
    end)

    player:GetAttributeChangedSignal("IsGameOwner"):Connect(function()
        local allowed = player:GetAttribute("IsGameOwner") == true
        ownerButton.Visible = allowed
        if not allowed then
            setOpen(false)
        end
    end)

    Players.PlayerAdded:Connect(renderTargets)
    Players.PlayerRemoving:Connect(function(target)
        if target.UserId == selectedUserId then
            selectedUserId = player.UserId
        end
        renderTargets()
    end)

    renderTargets()
    Util.setMenuAttributes("Owner", false)
end

return M
