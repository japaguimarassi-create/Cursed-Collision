--!strict

local Navigation = {}

function Navigation.Mount(root, config, player, travel)
    local holder = Instance.new("Frame")
    holder.Name = "Navigation"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(190, 52)
    holder.Position = UDim2.new(1, -210, 1, -184)
    holder.Parent = root.Gui

    local travelButton = root.Button(holder, "BattlegroundsButton", "BATTLEGROUNDS", UDim2.fromScale(1, 1))
    travelButton.TextSize = 10

    local function refresh()
        local zone = player:GetAttribute("Zone") or "PvE"
        travelButton.Text = zone == "PvP" and "RETURN TO PVE" or "BATTLEGROUNDS"
        travelButton.TextColor3 = zone == "PvP" and config.UI.Danger or config.UI.Text
    end

    travelButton.Activated:Connect(function()
        local zone = player:GetAttribute("Zone") or "PvE"
        travel:FireServer(zone == "PvP" and "PvE" or "PvP")
    end)

    player:GetAttributeChangedSignal("Zone"):Connect(refresh)
    refresh()

    return {
        Travel = travelButton,
    }
end

return Navigation
