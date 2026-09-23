--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationData = require(ReplicatedStorage.Animation.AnimationData)

type TrackCache = {[string]: AnimationTrack}
type AnimatorMap = {[Animator]: TrackCache}

local animations: {[string]: Animation} = {}
local tracks: AnimatorMap = setmetatable({}, {__mode = "k"}) :: AnimatorMap

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

local function getAnimation(definition: any): Animation?
    local assetId = normalizeId(tostring(definition.AnimationId or ""))
    if not assetId then
        return nil
    end

    local cached = animations[definition.Key]
    if cached and cached.Parent then
        return cached
    end

    local animation = Instance.new("Animation")
    animation.Name = "CC_Animation_" .. definition.Key
    animation.AnimationId = assetId
    animations[definition.Key] = animation
    return animation
end

function AnimationCache:GetTrack(animator: Animator, key: string): AnimationTrack?
    local definition = AnimationData[key]
    if not definition then
        return nil
    end

    local animatorTracks = tracks[animator]
    if not animatorTracks then
        animatorTracks = {}
        tracks[animator] = animatorTracks
    end

    local cached = animatorTracks[key]
    if cached and cached.Parent then
        return cached
    end

    local animation = getAnimation(definition)
    if not animation then
        return nil
    end

    local track = animator:LoadAnimation(animation)
    track.Looped = definition.Loop
    track.Priority = definition.Priority
    animatorTracks[key] = track

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

function AnimationCache:Stop(animator: Animator, key: string, fade: number?)
    local animatorTracks = tracks[animator]
    local track = animatorTracks and animatorTracks[key]
    if track and track.IsPlaying then
        local definition = AnimationData[key]
        track:Stop(fade or (definition and definition.FadeOut or 0.06))
    end
end

function AnimationCache:StopAll(animator: Animator, fade: number?)
    local animatorTracks = tracks[animator]
    if not animatorTracks then
        return
    end

    for key, track in pairs(animatorTracks) do
        if track.IsPlaying then
            local definition = AnimationData[key]
            track:Stop(fade or (definition and definition.FadeOut or 0.06))
        end
    end
end

return AnimationCache
