--!strict

local AnimationPriorityManager = {}
AnimationPriorityManager.__index = AnimationPriorityManager

local active: {[Animator]: {[string]: AnimationTrack}} = setmetatable({}, {__mode="k"}) :: any

function AnimationPriorityManager:_bucket(animator: Animator)
    local bucket=active[animator]
    if not bucket then
        bucket={}
        active[animator]=bucket
    end
    return bucket
end

function AnimationPriorityManager:Play(animator: Animator, key: string, track: AnimationTrack, priority: Enum.AnimationPriority, fade: number)
    local bucket=self:_bucket(animator)

    for otherKey, otherTrack in pairs(bucket) do
        if otherKey ~= key
            and otherTrack.IsPlaying
            and otherTrack.Priority.Value <= priority.Value then
            otherTrack:Stop(math.max(0, fade))
            bucket[otherKey]=nil
        end
    end

    track.Priority=priority
    track:Play(math.max(0, fade),1,1)
    bucket[key]=track
    return track
end

function AnimationPriorityManager:Stop(animator: Animator, key: string, fade: number)
    local bucket=active[animator]
    local track=bucket and bucket[key]
    if track then
        track:Stop(math.max(0,fade))
        bucket[key]=nil
    end
end

function AnimationPriorityManager:StopAll(animator: Animator, fade: number)
    local bucket=active[animator]
    if not bucket then return end
    for key,track in pairs(bucket) do
        track:Stop(math.max(0,fade))
        bucket[key]=nil
    end
end

return AnimationPriorityManager
