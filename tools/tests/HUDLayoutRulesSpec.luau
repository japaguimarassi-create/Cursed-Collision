--!strict

return function()
    local Rules = require("../../src/CollisionBattlestar/ReplicatedStorage/Shared/HUDLayoutRules")

    local phone = Rules.get(390, 844, true)
    assert(phone.Scale >= 0.78 and phone.Scale <= 1)
    assert(phone.TouchControls == true)
    assert(phone.ActionSize >= 74)
    assert(phone.Edge >= 12)
    assert(phone.BottomGap >= 12)
    assert(phone.BottomClearance > phone.ActionSize)

    local desktop = Rules.get(1920, 1080, false)
    assert(desktop.Scale == 1)
    assert(desktop.TouchControls == false)
    assert(desktop.ActionSize <= 96)

    local portrait = Rules.get(430, 932, true)
    assert(portrait.ActionSize <= phone.ActionSize + 8)
    assert(portrait.StatsWidth <= 360)

    local tiny = Rules.get(320, 568, true)
    assert(tiny.Scale >= 0.78)
    assert(tiny.StatsWidth <= 180)
    assert(tiny.CombatWidth >= 150)
    assert(tiny.StatsWidth + tiny.CombatWidth + tiny.Edge * 2 <= 320)
    assert(tiny.BottomClearance >= tiny.ActionSize + 40)
    assert(tiny.ActionSize >= 74)
    assert(tiny.StackGap >= 6)

    local zones = Rules.actionZones(390, 844, true)
    assert(Rules.nonOverlapping(zones))
    assert(Rules.nonOverlapping(Rules.actionZones(320, 568, true)))
    assert(Rules.nonOverlapping(Rules.actionZones(1920, 1080, false)))
end
