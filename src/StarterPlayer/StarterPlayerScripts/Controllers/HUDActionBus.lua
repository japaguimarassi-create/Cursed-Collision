--!strict

local event = Instance.new("BindableEvent")

export type Action = "M1" | "Dash" | "BlockToggle" | "SprintToggle" | "Special" | "Ultimate" | "Awakening" | "Skill1" | "Skill2" | "Skill3" | "Skill4"

local Bus = {}

function Bus:Emit(action: Action)
    event:Fire(action)
end

function Bus:Connect(callback: (Action) -> ()): RBXScriptConnection
    return event.Event:Connect(callback)
end

return Bus
