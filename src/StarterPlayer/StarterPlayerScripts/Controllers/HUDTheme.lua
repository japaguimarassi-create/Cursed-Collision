--!strict

local HUDTheme = {
    Colors = {
        Background = Color3.fromRGB(7, 9, 13),
        Panel = Color3.fromRGB(13, 16, 23),
        Surface = Color3.fromRGB(20, 24, 33),
        SurfacePressed = Color3.fromRGB(31, 36, 48),
        Border = Color3.fromRGB(86, 91, 112),
        Text = Color3.fromRGB(241, 243, 248),
        Muted = Color3.fromRGB(158, 163, 181),
        Accent = Color3.fromRGB(160, 116, 255),
        AccentSoft = Color3.fromRGB(101, 78, 153),
        Health = Color3.fromRGB(219, 74, 92),
        Ready = Color3.fromRGB(105, 224, 151),
        Warning = Color3.fromRGB(255, 206, 93),
        Ultimate = Color3.fromRGB(157, 117, 255),
        Awakening = Color3.fromRGB(255, 105, 181)
    },
    Radius = {
        Small = 8,
        Medium = 12,
        Large = 18,
        Pill = 999
    },
    Sizes = {
        TouchMinButton = 54,
        TouchActionButton = 68,
        TouchSkillHeight = 76
    }
}

return HUDTheme
