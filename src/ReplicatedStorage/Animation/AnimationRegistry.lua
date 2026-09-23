local AnimationRegistry = {
    Idle = {Id=0, Priority=Enum.AnimationPriority.Idle, Fade=0.10, Markers={"End"}},
    Walk = {Id=0, Priority=Enum.AnimationPriority.Movement, Fade=0.08, Markers={"End"}},
    Run = {Id=0, Priority=Enum.AnimationPriority.Movement, Fade=0.07, Markers={"End"}},
    Sprint = {Id=0, Priority=Enum.AnimationPriority.Movement, Fade=0.06, Markers={"End"}},
    Jump = {Id=0, Priority=Enum.AnimationPriority.Movement, Fade=0.04, Markers={"End"}},
    Fall = {Id=0, Priority=Enum.AnimationPriority.Movement, Fade=0.05, Markers={"End"}},
    Land = {Id=0, Priority=Enum.AnimationPriority.Action, Fade=0.03, Markers={"Impact","End"}},
    M1_1 = {Id=0, Priority=Enum.AnimationPriority.Action, Fade=0.035, Markers={"Startup","HitFrame","Impact","Recovery","End"}},
    M1_2 = {Id=0, Priority=Enum.AnimationPriority.Action, Fade=0.035, Markers={"Startup","HitFrame","Impact","Recovery","End"}},
    M1_3 = {Id=0, Priority=Enum.AnimationPriority.Action, Fade=0.035, Markers={"Startup","HitFrame","Impact","Recovery","End"}},
    M1_4 = {Id=0, Priority=Enum.AnimationPriority.Action4, Fade=0.025, Markers={"Startup","HitFrame","Impact","Recovery","End"}},
    Dash = {Id=0, Priority=Enum.AnimationPriority.Action, Fade=0.035, Markers={"Startup","End"}},
    BackDash = {Id=0, Priority=Enum.AnimationPriority.Action, Fade=0.035, Markers={"Startup","End"}},
    SideDash = {Id=0, Priority=Enum.AnimationPriority.Action, Fade=0.035, Markers={"Startup","End"}},
    AirDash = {Id=0, Priority=Enum.AnimationPriority.Action, Fade=0.035, Markers={"Startup","End"}},
    Block = {Id=0, Priority=Enum.AnimationPriority.Action, Fade=0.06, Markers={"End"}},
    Parry = {Id=0, Priority=Enum.AnimationPriority.Action4, Fade=0.02, Markers={"Impact","End"}},
    HitLight = {Id=0, Priority=Enum.AnimationPriority.Action, Fade=0.025, Markers={"Impact","End"}},
    HitHeavy = {Id=0, Priority=Enum.AnimationPriority.Action3, Fade=0.02, Markers={"Impact","End"}},
    HitLaunch = {Id=0, Priority=Enum.AnimationPriority.Action3, Fade=0.02, Markers={"Impact","End"}},
    HitSlam = {Id=0, Priority=Enum.AnimationPriority.Action3, Fade=0.02, Markers={"Impact","End"}},
    HitFinisher = {Id=0, Priority=Enum.AnimationPriority.Action4, Fade=0.015, Markers={"Impact","End"}},
    Ragdoll = {Id=0, Priority=Enum.AnimationPriority.Action4, Fade=0.01, Markers={"End"}},
    Skill1 = {Id=0, Priority=Enum.AnimationPriority.Action2, Fade=0.025, Markers={"Startup","HitFrame","Impact","Recovery","End"}},
    Skill2 = {Id=0, Priority=Enum.AnimationPriority.Action2, Fade=0.025, Markers={"Startup","HitFrame","Impact","Recovery","End"}},
    Skill3 = {Id=0, Priority=Enum.AnimationPriority.Action2, Fade=0.025, Markers={"Startup","HitFrame","Impact","Recovery","End"}},
    Skill4 = {Id=0, Priority=Enum.AnimationPriority.Action4, Fade=0.02, Markers={"Startup","HitFrame","Impact","Recovery","End"}},
    Special = {Id=0, Priority=Enum.AnimationPriority.Action4, Fade=0.02, Markers={"Startup","HitFrame","Impact","Recovery","End"}},
    Ultimate = {Id=0, Priority=Enum.AnimationPriority.Action4, Fade=0.01, Markers={"Startup","HitFrame","Impact","Recovery","End"}},
    Awakening = {Id=0, Priority=Enum.AnimationPriority.Action4, Fade=0.01, Markers={"Startup","Impact","End"}},
    Execute = {Id=0, Priority=Enum.AnimationPriority.Action4, Fade=0.01, Markers={"Startup","Impact","End"}},
    Emote = {Id=0, Priority=Enum.AnimationPriority.Action, Fade=0.08, Markers={"End"}}
}

function AnimationRegistry:Get(key: string)
    return self[key]
end

return AnimationRegistry
