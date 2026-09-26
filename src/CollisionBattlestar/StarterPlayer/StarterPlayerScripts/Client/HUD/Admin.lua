--!strict

local Admin = {}

function Admin.Mount(root, config, player, remote)
    if player:GetAttribute("IsOwner") ~= true then
        return nil
    end

    local button = root.Button(root.Gui, "AdminMenuButton", "ADMIN MENU", UDim2.fromOffset(154, 46))
    button.Position = UDim2.new(0, 20, 1, -154)
    button.BackgroundColor3 = config.UI.Danger
    button.TextSize = 10

    local panel = root.Panel(root.Gui, UDim2.fromOffset(278, 292), UDim2.new(0, 20, 1, -470))
    panel.Name = "AdminMenuPanel"
    panel.Visible = false

    local title = root.Label(panel, "ADMIN CONTROL", 15)
    title.Size = UDim2.new(1, -30, 0, 30)
    title.Position = UDim2.fromOffset(15, 10)

    local hint = root.Label(panel, "SERVER AUTHORITY • OWNER", 8, config.UI.Muted)
    hint.Size = UDim2.new(1, -30, 0, 18)
    hint.Position = UDim2.fromOffset(15, 38)

    local list = Instance.new("Frame")
    list.BackgroundTransparency = 1
    list.Size = UDim2.new(1, -24, 1, -72)
    list.Position = UDim2.fromOffset(12, 64)
    list.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.Parent = list

    local function action(name, text, order)
        local b = root.Button(list, "Action_" .. name, text, UDim2.new(1, 0, 0, 39))
        b.LayoutOrder = order
        b.Activated:Connect(function()
            remote:FireServer(name)
        end)
    end

    action("NextWave", "NEXT WAVE", 1)
    action("Reward", "+1000 CREDITS", 2)
    action("Heal", "HEAL PLAYER", 3)
    action("Clear", "CLEAR ENEMIES", 4)

    button.Activated:Connect(function()
        panel.Visible = not panel.Visible
    end)

    return {
        Button = button,
        Panel = panel,
    }
end

return Admin
