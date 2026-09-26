--!strict
local TweenService = game:GetService("TweenService")
local Economy = {}

function Economy.Mount(root, config, player)
    local holder = Instance.new("Frame")
    holder.Name = "Economy"
    holder.Size = UDim2.fromOffset(154, 48)
    holder.Position = UDim2.new(1, -18, 0, 18)
    holder.AnchorPoint = Vector2.new(1, 0)
    holder.BackgroundTransparency = 1
    holder.Parent = root.Gui

    local panel = root.Pill(holder, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), config.UI.Surface, 0.08)

    local icon = root.Label(panel, "◈", 14, config.UI.Warning)
    icon.Size = UDim2.fromOffset(24, 24)
    icon.Position = UDim2.fromOffset(10, 0)
    icon.TextXAlignment = Enum.TextXAlignment.Center

    local credits = root.Label(panel, "0", 15)
    credits.Size = UDim2.fromOffset(108, 24)
    credits.Position = UDim2.fromOffset(38, 0)

    local caption = root.Label(panel, "CREDITS", 7, config.UI.Muted, Enum.Font.GothamMedium)
    caption.Size = UDim2.fromOffset(108, 14)
    caption.Position = UDim2.fromOffset(38, 25)

    local flash = Instance.new("Frame")
    flash.Size = UDim2.fromScale(1, 1)
    flash.BackgroundColor3 = config.UI.Warning
    flash.BackgroundTransparency = 1
    flash.BorderSizePixel = 0
    flash.ZIndex = panel.ZIndex + 2
    flash.Parent = panel
    root.Rounded(flash, 14)

    local function refresh()
        credits.Text = tostring(player:GetAttribute("Credits") or 0)
    end

    local last = player:GetAttribute("Credits") or 0
    player:GetAttributeChangedSignal("Credits"):Connect(function()
        local current = player:GetAttribute("Credits") or 0
        if current ~= last then
            flash.BackgroundTransparency = 0.88
            TweenService:Create(flash, TweenInfo.new(0.28, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
        end
        last = current
        refresh()
    end)

    refresh()
    root.AnimateIn(holder, "Right")
    return {Holder = holder, Credits = credits}
end

return Economy
