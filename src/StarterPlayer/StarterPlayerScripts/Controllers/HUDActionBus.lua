--!strict

local BindableEvent = Instance.new("BindableEvent")

local HUDActionBus = {}

export type Action = "M1" | "Dash" | "BlockToggle" | "SprintToggle" | "Special" | "Ultimate" | "Awakening"

function HUDActionBus:Emit(action: Action)
    BindableEvent:Fire(action)
end

function HUDActionBus:Connect(handler: (Action) -> ())
    return BindableEvent.Event:Connect(handler)
end

return HUDActionBus
