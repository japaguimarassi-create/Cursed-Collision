--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationController = require(script.Parent.AnimationController)

local CombatAnimationManager = {}

local function keyForAction(action: string, payload: any): string
    if action == "M1" then
        local combo = math.clamp(tonumber(payload and payload.combo) or 1, 1, 4)
        return "M1_" .. tostring(combo)
    end

    if action == "Hit" then
        local reaction = tostring(payload and payload.reaction or "Light")
        return reaction == "Heavy" and "HitHeavy"
            or reaction == "Launch" and "HitLaunch"
            or reaction == "Slam" and "HitSlam"
            or reaction == "Finisher" and "HitFinisher"
            or "HitLight"
    end

    if action == "BlockStart" then return "Block" end
    if action == "Special" then return "Special" end
    if action == "Dash" then
        local model=payload and payload.actor
        local humanoid=model and model:FindFirstChildOfClass("Humanoid")
        local state=humanoid and humanoid:GetState()
        if state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall then
            return "AirDash"
        end
        return "Dash"
    end

    if string.sub(action,1,5)=="Skill" then
        return action
    end

    return action
end

function CombatAnimationManager:Play(character: Model, action: string, payload: any)
    local key=keyForAction(action,payload)
    return AnimationController:Play(character,key,payload,function(marker)
        character:SetAttribute("AnimationMarker",marker)
    end)
end

return CombatAnimationManager
