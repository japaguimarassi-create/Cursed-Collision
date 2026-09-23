--!strict

local TweenService = game:GetService("TweenService")
local AnimationPriorityManager = require(script.Parent.AnimationPriorityManager)

local AnimationBlender = {}

function AnimationBlender:Load(animator: Animator, animationId: number): AnimationTrack?
    if animationId <= 0 then
        return nil
    end

    local animation=Instance.new("Animation")
    animation.AnimationId="rbxassetid://"..tostring(animationId)

    local ok,track=pcall(function()
        return animator:LoadAnimation(animation)
    end)

    animation:Destroy()

    if not ok or not track then
        return nil
    end

    return track
end

function AnimationBlender:Play(animator: Animator, key: string, track: AnimationTrack, priority: Enum.AnimationPriority, fade: number)
    return AnimationPriorityManager:Play(animator,key,track,priority,fade)
end

function AnimationBlender:BlendWeight(track: AnimationTrack, weight: number, duration: number)
    if not track.IsPlaying then return end
    local target=math.clamp(weight,0,1)
    if duration <= 0 then
        track:AdjustWeight(target)
        return
    end
    local value=Instance.new("NumberValue")
    value.Value=track.WeightCurrent
    local connection=value.Changed:Connect(function(v)
        if track.IsPlaying then
            track:AdjustWeight(v)
        end
    end)
    local tween=TweenService:Create(value,TweenInfo.new(duration),{Value=target})
    tween.Completed:Connect(function() connection:Disconnect(); value:Destroy() end)
    tween:Play()
end

return AnimationBlender
