--!strict

local Status = {}

function Status.Mount(root, config)
    local panel = root.Panel(root.Gui, UDim2.fromOffset(310, 70), UDim2.fromScale(0.5, 0), Vector2.new(0.5, 0))

    local title = root.Label(panel, "WAVE 0", 22)
    title.Size = UDim2.new(0.5, -12, 0, 42)
    title.Position = UDim2.fromOffset(12, 5)

    local enemies = root.Label(panel, "0 ENEMIES", 10, config.UI.Muted)
    enemies.Size = UDim2.new(0.5, -12, 0, 42)
    enemies.Position = UDim2.new(0.5, 0, 0, 5)
    enemies.TextXAlignment = Enum.TextXAlignment.Right

    local zone = root.Label(root.Gui, "PVE", 9, config.UI.Muted)
    zone.Size = UDim2.fromOffset(180, 24)
    zone.Position = UDim2.fromOffset(20, 94)

    return {
        Wave = title,
        Enemies = enemies,
        Zone = zone,
    }
end

return Status
