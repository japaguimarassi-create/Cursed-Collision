--!strict
local Navigation = {}

function Navigation.Mount(root, config, player, travel)
    local holder = Instance.new("Frame")
    holder.Name = "Navigation"
    holder.Size = UDim2.fromOffset(246, 38)
    holder.Position = UDim2.new(1, -18, 0, 74)
    holder.AnchorPoint = Vector2.new(1, 0)
    holder.BackgroundTransparency = 1
    holder.Parent = root.Gui

    local zone = root.Pill(holder, UDim2.fromOffset(68, 30), UDim2.fromOffset(0, 4), config.UI.Good, 0.84)
    local zoneText = root.Label(zone, "PVE", 8, config.UI.Good)
    zoneText.Size = UDim2.fromScale(1, 1)
    zoneText.TextXAlignment = Enum.TextXAlignment.Center

    local button = root.Button(holder, "BattlegroundsButton", "BATTLEGROUND", UDim2.fromOffset(164, 36))
    button.Position = UDim2.fromOffset(78, 0)
    button.TextSize = 8

    local function refresh()
        local current = player:GetAttribute("Zone") or "PvE"
        local pvp = current == "PvP"
        zoneText.Text = if pvp then "PVP" else "PVE"
        zoneText.TextColor3 = if pvp then config.UI.Danger else config.UI.Good
        zone.BackgroundColor3 = if pvp then config.UI.Danger else config.UI.Good
        button.Text = if pvp then "RETURN TO CITY" else "BATTLEGROUND"
    end

    button.Activated:Connect(function()
        local current = player:GetAttribute("Zone") or "PvE"
        travel:FireServer(if current == "PvP" then "PvE" else "PvP")
    end)

    player:GetAttributeChangedSignal("Zone"):Connect(refresh)
    refresh()
    root.AnimateIn(holder, "Right")
    return {Holder = holder, Travel = button, Zone = zoneText}
end

return Navigation
