--!strict

local VisualProfile = {}

function VisualProfile.fallback(classId: string, variantSeed: number)
    local palettes = {
        Vanguard = {{68,78,94},{30,35,46},{88,190,255}},
        Striker = {{70,52,96},{34,24,48},{190,100,255}},
        Guardian = {{58,86,78},{24,40,34},{88,220,172}},
        Support = {{92,82,58},{42,38,28},{255,202,96}},
    }
    local palette = palettes[classId] or palettes.Vanguard
    local variant = math.max(1, math.floor(math.abs(variantSeed)) % 4 + 1)
    return {
        ClassId = classId,
        Variant = variant,
        Primary = palette[1],
        Secondary = palette[2],
        Accent = palette[3],
    }
end

return table.freeze(VisualProfile)
