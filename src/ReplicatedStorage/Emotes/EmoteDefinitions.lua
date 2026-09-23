--!strict

export type EmoteData = {
    Id: string,
    Name: string,
    Category: string,
    AnimationId: string?,
    SoundId: string?,
    VFX: string?,
    Duration: number,
    Loop: boolean,
    Price: number,
    Accent: Color3
}

local Emotes: {[string]: EmoteData} = {
    emote_001 = {
        Id = "emote_001",
        Name = "Cursed Stride",
        Category = "Traversal",
        AnimationId = nil,
        SoundId = nil,
        VFX = nil,
        Duration = 5.6,
        Loop = true,
        Price = 125,
        Accent = Color3.fromRGB(151, 103, 255)
    },
    emote_002 = {
        Id = "emote_002",
        Name = "Void Salute",
        Category = "Stationary",
        AnimationId = nil,
        SoundId = nil,
        VFX = nil,
        Duration = 2.8,
        Loop = false,
        Price = 125,
        Accent = Color3.fromRGB(104, 190, 255)
    },
    emote_003 = {
        Id = "emote_003",
        Name = "Lucky Pulse",
        Category = "Celebration",
        AnimationId = nil,
        SoundId = nil,
        VFX = nil,
        Duration = 4.2,
        Loop = true,
        Price = 125,
        Accent = Color3.fromRGB(104, 222, 148)
    },
    emote_004 = {
        Id = "emote_004",
        Name = "Menace Lean",
        Category = "Taunt",
        AnimationId = nil,
        SoundId = nil,
        VFX = nil,
        Duration = 3.8,
        Loop = true,
        Price = 125,
        Accent = Color3.fromRGB(255, 110, 129)
    },
    emote_005 = {
        Id = "emote_005",
        Name = "Victory Snap",
        Category = "Victory",
        AnimationId = nil,
        SoundId = nil,
        VFX = nil,
        Duration = 3.1,
        Loop = false,
        Price = 125,
        Accent = Color3.fromRGB(255, 210, 92)
    }
}

return Emotes
