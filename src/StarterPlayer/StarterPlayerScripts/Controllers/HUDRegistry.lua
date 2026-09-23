--!strict

local signal = Instance.new("BindableEvent")
local current: any = nil

local Registry = {}

function Registry:Set(hud: any)
    current = hud
    signal:Fire(hud)
end

function Registry:Wait(): any
    if current then
        return current
    end
    return signal.Event:Wait()
end

return Registry
