--!strict

export type EmoteDefinition = {
    Id: string,
    Name: string,
    Category: string,
    AnimationId: string,
    Duration: number,
    Loop: boolean,
    Price: number,
    Priority: Enum.AnimationPriority,
    Marker: string?,
    EnergyCost: number
}

local Action = Enum.AnimationPriority.Action

local EmoteData: {[string]: EmoteDefinition} = {
    emote_001 = {
        Id = "emote_001",
        Name = "Cursed Stride",
        Category = "Traversal",
        AnimationId = "",
        Duration = 5.6,
        Loop = true,
        Price = 125,
        Priority = Action,
        Marker = nil,
        EnergyCost = 0
    },
    emote_002 = {
        Id = "emote_002",
        Name = "Void Salute",
        Category = "Stationary",
        AnimationId = "",
        Duration = 2.8,
        Loop = false,
        Price = 125,
        Priority = Action,
        Marker = nil,
        EnergyCost = 0
    },
    emote_003 = {
        Id = "emote_003",
        Name = "Lucky Pulse",
        Category = "Celebration",
        AnimationId = "",
        Duration = 4.2,
        Loop = true,
        Price = 125,
        Priority = Action,
        Marker = nil,
        EnergyCost = 0
    },
    emote_004 = {
        Id = "emote_004",
        Name = "Menace Lean",
        Category = "Taunt",
        AnimationId = "",
        Duration = 3.8,
        Loop = true,
        Price = 125,
        Priority = Action,
        Marker = nil,
        EnergyCost = 0
    },
    emote_005 = {
        Id = "emote_005",
        Name = "Victory Snap",
        Category = "Victory",
        AnimationId = "",
        Duration = 3.1,
        Loop = false,
        Price = 125,
        Priority = Action,
        Marker = nil,
        EnergyCost = 0
    }
}

return EmoteData
