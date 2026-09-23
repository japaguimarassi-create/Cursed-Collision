--!strict

export type EmoteAnimationDefinition = {
    Id: string,
    Name: string,
    AnimationId: string,
    Loop: boolean,
    Priority: Enum.AnimationPriority,
    FadeIn: number,
    FadeOut: number,
    Speed: number,
    EnergyCost: number
}

local Data: {[string]: EmoteAnimationDefinition} = {
    emote_001 = {
        Id = "emote_001",
        Name = "Cursed Stride",
        AnimationId = "",
        Loop = true,
        Priority = Enum.AnimationPriority.Action,
        FadeIn = 0.08,
        FadeOut = 0.08,
        Speed = 1,
        EnergyCost = 0
    },
    emote_002 = {
        Id = "emote_002",
        Name = "Void Salute",
        AnimationId = "",
        Loop = false,
        Priority = Enum.AnimationPriority.Action,
        FadeIn = 0.06,
        FadeOut = 0.08,
        Speed = 1,
        EnergyCost = 0
    },
    emote_003 = {
        Id = "emote_003",
        Name = "Lucky Pulse",
        AnimationId = "",
        Loop = true,
        Priority = Enum.AnimationPriority.Action,
        FadeIn = 0.08,
        FadeOut = 0.08,
        Speed = 1,
        EnergyCost = 0
    },
    emote_004 = {
        Id = "emote_004",
        Name = "Menace Lean",
        AnimationId = "",
        Loop = true,
        Priority = Enum.AnimationPriority.Action,
        FadeIn = 0.08,
        FadeOut = 0.08,
        Speed = 1,
        EnergyCost = 0
    },
    emote_005 = {
        Id = "emote_005",
        Name = "Victory Snap",
        AnimationId = "",
        Loop = false,
        Priority = Enum.AnimationPriority.Action,
        FadeIn = 0.06,
        FadeOut = 0.10,
        Speed = 1,
        EnergyCost = 0
    }
}

return Data
