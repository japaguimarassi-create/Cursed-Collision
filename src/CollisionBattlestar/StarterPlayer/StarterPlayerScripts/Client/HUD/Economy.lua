--!strict

local Economy = {}

function Economy.Mount(root, config, player)
    local panel = root.Panel(root.Gui, UDim2.fromOffset(235, 70), UDim2.new(1, -18, 0, 18), Vector2.new(1, 0))

    local credits = root.Label(panel, "0 C", 17)
    credits.Size = UDim2.new(1, -20, 0, 28)
    credits.Position = UDim2.fromOffset(10, 4)

    local stats = root.Label(panel, "DMG 0  •  DEF 0  •  SPD 0", 9, config.UI.Muted)
    stats.Size = UDim2.new(1, -20, 0, 22)
    stats.Position = UDim2.fromOffset(10, 34)

    local function refresh()
        credits.Text = ("%d C"):format(player:GetAttribute("Credits") or 0)
        stats.Text = ("DMG %d  •  DEF %d  •  SPD %d"):format(
            player:GetAttribute("DamageLevel") or 0,
            player:GetAttribute("DefenseLevel") or 0,
            player:GetAttribute("SpeedLevel") or 0
        )
    end

    for _, attribute in ipairs({"Credits", "DamageLevel", "DefenseLevel", "SpeedLevel"}) do
        player:GetAttributeChangedSignal(attribute):Connect(refresh)
    end

    refresh()

    return {
        Credits = credits,
        Stats = stats,
    }
end

return Economy
