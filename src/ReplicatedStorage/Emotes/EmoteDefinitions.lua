--!strict

export type EmoteDefinition = {
    Id: string,
    Name: string,
    Category: string,
    Duration: number,
    Loop: boolean,
    AnimationKey: string,
    AnimationId: string,
    Priority: Enum.AnimationPriority,
    EnergyCost: number,
    Interrupts: {
        Movement: boolean,
        Damage: boolean,
        Stun: boolean,
        Ragdoll: boolean,
        Combat: boolean
    },
    Accent: Color3
}

local Action = Enum.AnimationPriority.Action
local Idle = Enum.AnimationPriority.Idle

local Emotes: {[string]: EmoteDefinition} = {
    emote_001 = {
        Id = "emote_001",
        Name = "Cursed Stride",
        Category = "Traversal",
        Duration = 5.6,
        Loop = true,
        AnimationKey = "Emote_001",
        AnimationId = "",
        Priority = Idle,
        EnergyCost = 0,
        Interrupts = {
            Movement = true,
            Damage = true,
            Stun = true,
            Ragdoll = true,
            Combat = true
        },
        Accent = Color3.fromRGB(151, 103, 255)
    },
    emote_002 = {
        Id = "emote_002",
        Name = "Void Salute",
        Category = "Stationary",
        Duration = 2.8,
        Loop = false,
        AnimationKey = "Emote_002",
        AnimationId = "",
        Priority = Action,
        EnergyCost = 0,
        Interrupts = {
            Movement = true,
            Damage = true,
            Stun = true,
            Ragdoll = true,
            Combat = true
        },
        Accent = Color3.fromRGB(104, 190, 255)
    },
    emote_003 = {
        Id = "emote_003",
        Name = "Lucky Pulse",
        Category = "Celebration",
        Duration = 4.2,
        Loop = true,
        AnimationKey = "Emote_003",
        AnimationId = "",
        Priority = Idle,
        EnergyCost = 0,
        Interrupts = {
            Movement = true,
            Damage = true,
            Stun = true,
            Ragdoll = true,
            Combat = true
        },
        Accent = Color3.fromRGB(104, 222, 148)
    },
    emote_004 = {
        Id = "emote_004",
        Name = "Menace Lean",
        Category = "Taunt",
        Duration = 3.8,
        Loop = true,
        AnimationKey = "Emote_004",
        AnimationId = "",
        Priority = Idle,
        EnergyCost = 0,
        Interrupts = {
            Movement = true,
            Damage = true,
            Stun = true,
            Ragdoll = true,
            Combat = true
        },
        Accent = Color3.fromRGB(255, 110, 129)
    },
    emote_005 = {
        Id = "emote_005",
        Name = "Victory Snap",
        Category = "Victory",
        Duration = 3.1,
        Loop = false,
        AnimationKey = "Emote_005",
        AnimationId = "",
        Priority = Action,
        EnergyCost = 0,
        Interrupts = {
            Movement = true,
            Damage = true,
            Stun = true,
            Ragdoll = true,
            Combat = true
        },
        Accent = Color3.fromRGB(255, 210, 92)
    }
}

return Emotes