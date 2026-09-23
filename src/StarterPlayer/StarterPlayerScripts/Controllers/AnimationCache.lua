--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationData = require(ReplicatedStorage.Animation.AnimationData)

type TrackCache = {[string]: AnimationTrack}
type AnimatorMap = {[Animator]: TrackCache}

local animations: {[string]: Animation} = {}
local tracks: AnimatorMap = setmetatable({}, {__mode = "k"}) :: any

local AnimationCache = {}

local function normalizeId(id: string): string?
    if id == "" or id == "0" or id == "rbxassetid://0" then
        return nil
    end

    if string.find(id, "rbxassetid://", 1, true) then
        return id
    end

    if tonumber(id) then
        return "rbxassetid://" .. id
    end

    return nil
end

local function getAnimation(cacheKey: string, rawId: string): Animation?
    local assetId = normalizeId(rawId)
    if not assetId then
        return nil
    end

    local cached = animations[cacheKey]
    if cached then
        return cached
    end

    local animation = Instance.new("Animation")
    animation.Name = "CC_Animation_" .. cacheKey
    animation.AnimationId = assetId
    animations[cacheKey] = animation
    return animation
end

local function bucketFor(animator: Animator): TrackCache
    local bucket = tracks[animator]
    if not bucket then
        bucket = {}
        tracks[animator] = bucket
    end
    return bucket
end

function AnimationCache:GetTrack(animator: Animator, key: string): AnimationTrack?
    local definition = AnimationData[key]
    if not definition then
        return nil
    end

    local bucket = bucketFor(animator)
    local cached = bucket[key]

    if cached and cached.Parent then
        return cached
    end

    local animation = getAnimation(definition.Key, definition.AnimationId)
    if not animation then
        return nil
    end

    local track = animator:LoadAnimation(animation)
    track.Looped = definition.Loop
    track.Priority = definition.Priority
    bucket[key] = track
    return track
end

function AnimationCache:GetTrackForId(
    animator: Animator,
    cacheKey: string,
    animationId: string,
    looped: boolean,
    priority: Enum.AnimationPriority
): AnimationTrack?
    local normalized = normalizeId(animationId)
    if not normalized then
        return nil
    end

    local bucket = bucketFor(animator)
    local cached = bucket[cacheKey]

    if cached then
        return cached
    end

    local animation = getAnimation(cacheKey, normalized)
    if not animation then
        return nil
    end

    local track = animator:LoadAnimation(animation)
    track.Looped = looped
    track.Priority = priority
    bucket[cacheKey] = track
    return track
end

function AnimationCache:Play(
    animator: Animator,
    key: string,
    speed: number?
): AnimationTrack?
    local definition = AnimationData[key]
    if not definition then
        return nil
    end

    local track = self:GetTrack(animator, key)
    if not track then
        return nil
    end

    track.Looped = definition.Loop
    track.Priority = definition.Priority
    track:Play(definition.FadeIn, 1, speed or definition.Speed)
    return track
end

function AnimationCache:PlayExternal(
    animator: Animator,
    cacheKey: string,
    animationId: string,
    looped: boolean,
    priority: Enum.AnimationPriority,
    fadeIn: number,
    speed: number
): AnimationTrack?
    local track = self:GetTrackForId(
        animator,
        cacheKey,
        animationId,
        looped,
        priority
    )

    if not track then
        return nil
    end

    track:Play(math.max(0, fadeIn), 1, speed)
    return track
end

function AnimationCache:Stop(animator: Animator, key: string, fade: number?)
    local bucket = tracks[animator]
    local track = bucket and bucket[key]

    if track and track.IsPlaying then
        local definition = AnimationData[key]
        track:Stop(fade or (definition and definition.FadeOut or 0.06))
    end
end

function AnimationCache:StopAll(animator: Animator, fade: number?)
    local bucket = tracks[animator]
    if not bucket then
        return
    end

    for key, track in pairs(bucket) do
        if track.IsPlaying then
            local definition = AnimationData[key]
            track:Stop(
                fade or (definition and definition.FadeOut or 0.06)
            )
        end
    end
end

return AnimationCache
