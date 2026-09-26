--!strict

return {
    BuildVersion = "tag-1.0.0",
    UniverseId = 5290480963,
    PlaceId = 15338267657,
    GameMode = "Tag",

    World = {
        Seed = 260926,
        Size = 1000,
        RoadWidth = 28,
        BlockSize = 84,
    },

    Tag = {
        RoundDuration = 90,
        Intermission = 8,
        TagDistance = 6.5,
        TagCooldown = 0.85,
    },

    Movement = {
        WalkSpeed = 18,
        JumpPower = 52,
    },

    UI = {
        Surface = Color3.fromRGB(12, 14, 20),
        Surface2 = Color3.fromRGB(24, 28, 38),
        Stroke = Color3.fromRGB(70, 78, 96),
        Text = Color3.fromRGB(242, 245, 250),
        Muted = Color3.fromRGB(158, 167, 182),
        Good = Color3.fromRGB(110, 225, 170),
        Danger = Color3.fromRGB(255, 70, 78),
        Warning = Color3.fromRGB(255, 194, 90),
    },
}
