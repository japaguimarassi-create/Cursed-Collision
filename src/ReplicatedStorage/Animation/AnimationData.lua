--!strict

export type AnimationDefinition = {
    Key: string,
    Name: string,
    AnimationId: string,
    Loop: boolean,
    Priority: Enum.AnimationPriority,
    Marker: string?,
    FadeIn: number,
    FadeOut: number,
    Speed: number,
    EnergyCost: number?
}

local Action = Enum.AnimationPriority.Action
local Movement = Enum.AnimationPriority.Movement
local Idle = Enum.AnimationPriority.Idle

local function definition(
    key: string,
    name: string,
    marker: string?,
    looped: boolean,
    priority: Enum.AnimationPriority,
    fadeIn: number,
    fadeOut: number,
    energyCost: number?
): AnimationDefinition
    return {
        Key = key,
        Name = name,
        AnimationId = "",
        Loop = looped,
        Priority = priority,
        Marker = marker,
        FadeIn = fadeIn,
        FadeOut = fadeOut,
        Speed = 1,
        EnergyCost = energyCost
    }
end

local Data: {[string]: AnimationDefinition} = {
    Idle = definition("Idle", "Combat Idle", nil, true, Idle, 0.10, 0.10, nil),
    Walk = definition("Walk", "Combat Walk", nil, true, Movement, 0.10, 0.10, nil),
    Run = definition("Run", "Combat Run", nil, true, Movement, 0.08, 0.08, nil),
    Sprint = definition("Sprint", "Combat Sprint", nil, true, Movement, 0.06, 0.08, nil),
    Jump = definition("Jump", "Jump", nil, false, Movement, 0.04, 0.06, nil),
    Fall = definition("Fall", "Fall", nil, true, Movement, 0.04, 0.08, nil),
    Land = definition("Land", "Landing", nil, false, Action, 0.02, 0.08, nil),

    M1_1 = definition("M1_1", "M1 Light 1", "Hit", false, Action, 0.02, 0.05, 0),
    M1_2 = definition("M1_2", "M1 Light 2", "Hit", false, Action, 0.02, 0.05, 0),
    M1_3 = definition("M1_3", "M1 Light 3", "Hit", false, Action, 0.02, 0.05, 0),
    M1_4 = definition("M1_4", "M1 Finisher", "Hit", false, Action, 0.02, 0.10, 0),

    Dash = definition("Dash", "Dash", nil, false, Action, 0.02, 0.06, nil),
    BackDash = definition("BackDash", "Back Dash", nil, false, Action, 0.02, 0.06, nil),
    SideDash = definition("SideDash", "Side Dash", nil, false, Action, 0.02, 0.06, nil),
    AirDash = definition("AirDash", "Air Dash", nil, false, Action, 0.02, 0.06, nil),

    Block = definition("Block", "Block", nil, true, Action, 0.04, 0.04, nil),
    Heavy = definition("Heavy", "Heavy Attack", "Hit", false, Action, 0.02, 0.10, 0),
    Parry = definition("Parry", "Perfect Block", nil, false, Action, 0.01, 0.08, nil),

    HitLight = definition("HitLight", "Light Hit Reaction", nil, false, Action, 0.01, 0.06, nil),
    HitHeavy = definition("HitHeavy", "Heavy Hit Reaction", nil, false, Action, 0.01, 0.10, nil),
    Ragdoll = definition("Ragdoll", "Ragdoll Recovery", nil, false, Action, 0.01, 0.08, nil),
    Recovery = definition("Recovery", "Combat Recovery", nil, false, Action, 0.04, 0.08, nil),
    Dodge = definition("Dodge", "Dodge", nil, false, Action, 0.01, 0.05, nil),

    Skill1 = definition("Skill1", "Skill 1", "Hit", false, Action, 0.02, 0.08, 10),
    Skill2 = definition("Skill2", "Skill 2", "Hit", false, Action, 0.02, 0.08, 20),
    Skill3 = definition("Skill3", "Skill 3", "Hit", false, Action, 0.02, 0.10, 30),
    Skill4 = definition("Skill4", "Skill 4", "Hit", false, Action, 0.02, 0.12, 40),
    Special = definition("Special", "Special", "Hit", false, Action, 0.02, 0.10, 25),
    Ultimate = definition("Ultimate", "Ultimate", "Hit", false, Action, 0.02, 0.14, 100),
    Awakening = definition("Awakening", "Awakening", "Hit", false, Action, 0.02, 0.16, 100),
    Execution = definition("Execution", "Execution", "Hit", false, Action, 0.02, 0.20, nil)
}

return Data
