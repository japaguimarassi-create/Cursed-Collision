--!strict
local Admin = {}

function Admin.Mount(root, config, player, remote)
    if player:GetAttribute("IsOwner") ~= true then
        return nil
    end

    local button = root.Button(root.Gui, "AdminMenuButton", "CONTROL", UDim2.fromOffset(92, 30))
    button.Position = UDim2.fromOffset(18, 82)
    button.TextSize = 8
    button.BackgroundColor3 = config.UI.Danger

    local panel = root.Pill(root.Gui, UDim2.fromOffset(246, 258), UDim2.fromOffset(18, 120), config.UI.Surface, 0.04)
    panel.Name = "AdminMenuPanel"
    panel.Visible = false

    local title = root.Label(panel, "OWNER CONTROL", 12)
    title.Size = UDim2.new(1, -26, 0, 24)
    title.Position = UDim2.fromOffset(13, 10)

    local hint = root.Label(panel, "SERVER AUTHORITY", 7, config.UI.Muted, Enum.Font.GothamMedium)
    hint.Size = UDim2.new(1, -26, 0, 16)
    hint.Position = UDim2.fromOffset(13, 32)

    local list = Instance.new("Frame")
    list.BackgroundTransparency = 1
    list.Size = UDim2.new(1, -24, 1, -66)
    list.Position = UDim2.fromOffset(12, 56)
    list.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.Parent = list

    local function action(name, text, order)
        local actionButton = root.Button(list, "Action_" .. name, text, UDim2.new(1, 0, 0, 37))
        actionButton.LayoutOrder = order
        actionButton.Activated:Connect(function()
            remote:FireServer(name)
            panel.Visible = false
        end)
    end

    action("NextWave", "NEXT WAVE", 1)
    action("Reward", "+1000 CREDITS", 2)
    action("Heal", "HEAL PLAYER", 3)
    action("Clear", "CLEAR ENEMIES", 4)

    button.Activated:Connect(function()
        panel.Visible = not panel.Visible
    end)

    return {Button = button, Panel = panel}
end

return Admin
