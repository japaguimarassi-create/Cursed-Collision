--!strict

export type EmoteData = {
    Id: string,
    Name: string,
    Category: string,
    AnimationId: string,
    SoundId: string,
    VFXId: string?,
    Duration: number,
    Loop: boolean,
    Price: number,
    Unlock: string
}

local Emotes: {[string]: EmoteData} = {
    emote_001 = {
        Id = "emote_001",
        Name = "Cursed Stride",
        Category = "Traversal",
        AnimationId = "",
        SoundId = "",
        VFXId = nil,
        Duration = 5.6,
        Loop = true,
        Price = 125,
        Unlock = "Credits"
    },
    emote_002 = {
        Id = "emote_002",
        Name = "Void Salute",
        Category = "Stationary",
        AnimationId = "",
        SoundId = "",
        VFXId = nil,
        Duration = 2.8,
        Loop = false,
        Price = 125,
        Unlock = "Credits"
    },
    emote_003 = {
        Id = "emote_003",
        Name = "Lucky Pulse",
        Category = "Celebration",
        AnimationId = "",
        SoundId = "",
        VFXId = nil,
        Duration = 4.2,
        Loop = true,
        Price = 125,
        Unlock = "Credits"
    },
    emote_004 = {
        Id = "emote_004",
        Name = "Menace Lean",
        Category = "Taunt",
        AnimationId = "",
        SoundId = "",
        VFXId = nil,
        Duration = 3.8,
        Loop = true,
        Price = 125,
        Unlock = "Credits"
    },
    emote_005 = {
        Id = "emote_005",
        Name = "Victory Snap",
        Category = "Victory",
        AnimationId = "",
        SoundId = "",
        VFXId = nil,
        Duration = 3.1,
        Loop = false,
        Price = 125,
        Unlock = "Credits"
    }
}

return Emotes
