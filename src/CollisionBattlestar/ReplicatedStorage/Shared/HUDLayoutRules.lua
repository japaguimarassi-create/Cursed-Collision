--!strict

local Rules = {}

local function clampScale(viewportX: number, viewportY: number): number
    local shortest = math.min(viewportX, viewportY)
    return math.clamp(shortest / 720, 0.78, 1)
end

function Rules.get(viewportX: number, viewportY: number, touch: boolean)
    local scale = clampScale(viewportX, viewportY)
    local tiny = math.min(viewportX, viewportY) < 600

    local edge = math.max(12, math.floor(16 * scale))
    local statsWidth = if touch then math.min(352, viewportX * 0.84) else 360
    if touch and viewportX < 500 then
        statsWidth = math.clamp(viewportX * 0.43, 132, 180)
    elseif tiny then
        statsWidth = math.min(statsWidth, 310)
    end

    local actionSize = if touch then math.clamp(92 * scale, 74, 96) else math.clamp(88 * scale, 76, 96)
    local dashWidth = if touch then math.clamp(actionSize * 0.72, 62, 78) else math.clamp(actionSize * 0.82, 64, 78)
    local combatWidth = if touch then math.clamp(viewportX - statsWidth - edge * 2 - 8, 150, 206) else 206
    local bottomGap = math.max(12, math.floor(14 * scale))
    local bottomClearance = if touch then actionSize + math.max(40, math.floor(48 * scale)) else actionSize + math.max(18, math.floor(22 * scale))
    local stackGap = math.max(6, math.floor(8 * scale))

    return {
        Scale = scale,
        TouchControls = touch,
        UseCustomControls = touch,
        SafeInsetMode = "CoreUISafeInsets",
        StatsWidth = math.floor(statsWidth),
        ActionSize = math.floor(actionSize),
        DashWidth = math.floor(dashWidth),
        CombatWidth = math.floor(combatWidth),
        Edge = edge,
        BottomGap = bottomGap,
        BottomClearance = bottomClearance,
        StackGap = stackGap,
    }
end

function Rules.actionZones(viewportX: number, viewportY: number, touch: boolean)
    local metrics = Rules.get(viewportX, viewportY, touch)
    local s = metrics.Scale
    local size = metrics.ActionSize
    local edge = metrics.Edge
    local gap = metrics.StackGap

    local bottom = viewportY - edge
    local right = viewportX - edge

    local m1 = {
        Name = "M1",
        X = right - size,
        Y = bottom - size,
        Width = size,
        Height = size,
    }

    local dash = {
        Name = "Dash",
        X = right - size,
        Y = m1.Y - gap - math.floor(size * 0.78),
        Width = size,
        Height = math.floor(size * 0.78),
    }

    local menu = {
        Name = "Navigation",
        X = viewportX - edge - math.floor(120 * s),
        Y = edge,
        Width = math.floor(120 * s),
        Height = math.floor(42 * s),
    }

    return {m1, dash, menu}
end

local function intersects(a, b): boolean
    return a.X < b.X + b.Width
        and b.X < a.X + a.Width
        and a.Y < b.Y + b.Height
        and b.Y < a.Y + a.Height
end

function Rules.nonOverlapping(zones): boolean
    for i = 1, #zones do
        for j = i + 1, #zones do
            if intersects(zones[i], zones[j]) then
                return false
            end
        end
    end
    return true
end

return Rules
