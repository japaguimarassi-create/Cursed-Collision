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

local Data: {[string]: AnimationDefinition} = {
    Idle = {
        Key = "Idle",
        Name = "Combat Idle",
        AnimationId = "",
        Loop = true,
        Priority = Idle,
        Marker = nil,
        FadeIn = 0.10,
        FadeOut = 0.10,
        Speed = 1
    },
    Walk = {
        Key = "Walk",
        Name = "Combat Walk",
        AnimationId = "",
        Loop = true,
        Priority = Movement,
        Marker = nil,
        FadeIn = 0.10,
        FadeOut = 0.10,
        Speed = 1
    },
    Run = {
        Key = "Run",
        Name = "Combat Run",
        AnimationId = "",
        Loop = true,
        Priority = Movement,
        Marker = nil,
        FadeIn = 0.08,
        FadeOut = 0.08,
        Speed = 1
    },
    Sprint = {
        Key = "Sprint",
        Name = "Combat Sprint",
        AnimationId = "",
        Loop = true,
        Priority = Movement,
        Marker = nil,
        FadeIn = 0.06,
        FadeOut = 0.08,
        Speed = 1
    },
    Jump = {
        Key = "Jump",
        Name = "Jump",
        AnimationId = "",
        Loop = false,
        Priority = Movement,
        Marker = nil,
        FadeIn = 0.04,
        FadeOut = 0.06,
        Speed = 1
    },
    Fall = {
        Key = "Fall",
        Name = "Fall",
        AnimationId = "",
        Loop = true,
        Priority = Movement,
        Marker = nil,
        FadeIn = 0.04,
        FadeOut = 0.08,
        Speed = 1
    },
    Land = {
        Key = "Land",
        Name = "Landing",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.02,
        FadeOut = 0.08,
        Speed = 1
    },
    M1_1 = {
        Key = "M1_1",
        Name = "M1 Light 1",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.05,
        Speed = 1,
        EnergyCost = 0
    },
    M1_2 = {
        Key = "M1_2",
        Name = "M1 Light 2",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.05,
        Speed = 1,
        EnergyCost = 0
    },
    M1_3 = {
        Key = "M1_3",
        Name = "M1 Light 3",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.05,
        Speed = 1,
        EnergyCost = 0
    },
    M1_4 = {
        Key = "M1_4",
        Name = "M1 Finisher",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.10,
        Speed = 1,
        EnergyCost = 0
    },
    BackDash = {
        Key = "BackDash",
        Name = "Back Dash",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.02,
        FadeOut = 0.06,
        Speed = 1
    },
    SideDash = {
        Key = "SideDash",
        Name = "Side Dash",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.02,
        FadeOut = 0.06,
        Speed = 1
    },
    Heavy = {
        Key = "Heavy",
        Name = "Heavy Attack",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.10,
        Speed = 1,
        EnergyCost = 0
    },
    Dash = {
        Key = "Dash",
        Name = "Dash",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.02,
        FadeOut = 0.06,
        Speed = 1
    },
    BackDash = {
        Key = "BackDash",
        Name = "Back Dash",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.02,
        FadeOut = 0.06,
        Speed = 1
    },
    SideDash = {
        Key = "SideDash",
        Name = "Side Dash",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.02,
        FadeOut = 0.06,
        Speed = 1
    },
    BackDash = {
        Key = "BackDash",
        Name = "Back Dash",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.02,
        FadeOut = 0.06,
        Speed = 1
    },
    SideDash = {
        Key = "SideDash",
        Name = "Side Dash",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.02,
        FadeOut = 0.06,
        Speed = 1
    },
    AirDash = {
        Key = "AirDash",
        Name = "Air Dash",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.02,
        FadeOut = 0.06,
        Speed = 1
    },
    Block = {
        Key = "Block",
        Name = "Block",
        AnimationId = "",
        Loop = true,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.04,
        FadeOut = 0.04,
        Speed = 1
    },
    Parry = {
        Key = "Parry",
        Name = "Perfect Block",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.01,
        FadeOut = 0.08,
        Speed = 1
    },
    HitLight = {
        Key = "HitLight",
        Name = "Light Hit Reaction",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.01,
        FadeOut = 0.06,
        Speed = 1
    },
    HitHeavy = {
        Key = "HitHeavy",
        Name = "Heavy Hit Reaction",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.01,
        FadeOut = 0.10,
        Speed = 1
    },
    Ragdoll = {
        Key = "Ragdoll",
        Name = "Ragdoll Recovery",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.01,
        FadeOut = 0.08,
        Speed = 1
    },
    Recovery = {
        Key = "Recovery",
        Name = "Combat Recovery",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.04,
        FadeOut = 0.08,
        Speed = 1
    },
    Dodge = {
        Key = "Dodge",
        Name = "Dodge",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.01,
        FadeOut = 0.05,
        Speed = 1
    },
    Skill1 = {
        Key = "Skill1",
        Name = "Skill 1",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.08,
        Speed = 1,
        EnergyCost = 10
    },
    Skill2 = {
        Key = "Skill2",
        Name = "Skill 2",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.08,
        Speed = 1,
        EnergyCost = 20
    },
    Skill3 = {
        Key = "Skill3",
        Name = "Skill 3",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.10,
        Speed = 1,
        EnergyCost = 30
    },
    Skill4 = {
        Key = "Skill4",
        Name = "Skill 4",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.12,
        Speed = 1,
        EnergyCost = 40
    },
    Special = {
        Key = "Special",
        Name = "Special",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.10,
        Speed = 1,
        EnergyCost = 25
    },
    Ultimate = {
        Key = "Ultimate",
        Name = "Ultimate",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.14,
        Speed = 1,
        EnergyCost = 100
    },
    Awakening = {
        Key = "Awakening",
        Name = "Awakening",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.16,
        Speed = 1,
        EnergyCost = 100
    },
    Emote_001 = {
        Key = "Emote_001",
        Name = "Cursed Stride",
        AnimationId = "",
        Loop = true,
        Priority = Idle,
        Marker = nil,
        FadeIn = 0.08,
        FadeOut = 0.10,
        Speed = 1
    },
    Emote_002 = {
        Key = "Emote_002",
        Name = "Void Salute",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.05,
        FadeOut = 0.10,
        Speed = 1
    },
    Emote_003 = {
        Key = "Emote_003",
        Name = "Lucky Pulse",
        AnimationId = "",
        Loop = true,
        Priority = Idle,
        Marker = nil,
        FadeIn = 0.08,
        FadeOut = 0.10,
        Speed = 1
    },
    Emote_004 = {
        Key = "Emote_004",
        Name = "Menace Lean",
        AnimationId = "",
        Loop = true,
        Priority = Idle,
        Marker = nil,
        FadeIn = 0.08,
        FadeOut = 0.10,
        Speed = 1
    },
    Emote_005 = {
        Key = "Emote_005",
        Name = "Victory Snap",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.05,
        FadeOut = 0.12,
        Speed = 1
    },
    Interaction = {
        Key = "Interaction",
        Name = "Interaction",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.04,
        FadeOut = 0.08,
        Speed = 1
    },
    Emote = {
        Key = "Emote",
        Name = "Emote",
        AnimationId = "",
        Loop = true,
        Priority = Action,
        Marker = nil,
        FadeIn = 0.08,
        FadeOut = 0.08,
        Speed = 1
    },
    Execution = {
        Key = "Execution",
        Name = "Execution",
        AnimationId = "",
        Loop = false,
        Priority = Action,
        Marker = "Hit",
        FadeIn = 0.02,
        FadeOut = 0.20,
        Speed = 1
    }
}

return Data
