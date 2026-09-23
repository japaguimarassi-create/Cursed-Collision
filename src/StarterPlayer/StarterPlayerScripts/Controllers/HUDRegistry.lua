--!strict

local BindableEvent = Instance.new("BindableEvent")
local current: any = nil

local HUDRegistry = {}

function HUDRegistry:Set(hud: any)
    current = hud
    BindableEvent:Fire(hud)
end

function HUDRegistry:Get(): any
    return current
end

function HUDRegistry:Wait(): any
    if current then
        return current
    end
    return BindableEvent.Event:Wait()
end

return HUDRegistry
