--!strict

export type InputPreset = {
    Skill: {[number]: string},
    M1: string,
    Dash: string,
    Block: string,
    Special: string,
    Sprint: string,
    Ultimate: string,
    Awakening: string
}

local HUDConfig = {
    Scale = {
        ReferenceShortAxis = 720,
        Minimum = 0.72,
        Maximum = 1.08,
        TouchMinimumButton = 58,
        TouchRecommendedButton = 72,
        GamepadRecommendedButton = 60
    },

    Colors = {
        Panel = Color3.fromRGB(10, 12, 18),
        PanelSoft = Color3.fromRGB(18, 21, 29),
        Stroke = Color3.fromRGB(76, 78, 95),
        Text = Color3.fromRGB(239, 240, 246),
        Muted = Color3.fromRGB(155, 158, 176),
        Accent = Color3.fromRGB(157, 117, 255),
        Danger = Color3.fromRGB(216, 72, 88),
        Ready = Color3.fromRGB(104, 222, 148)
    },

    Inputs: {
        KeyboardAndMouse = {
            Skill = {
                [1] = "1",
                [2] = "2",
                [3] = "3",
                [4] = "4"
            },
            M1 = "LMB",
            Dash = "Q",
            Block = "F",
            Special = "E",
            Sprint = "Shift",
            Ultimate = "R",
            Awakening = "G"
        } :: InputPreset,

        Gamepad = {
            Skill = {
                [1] = "RB",
                [2] = "Y",
                [3] = "D-PAD ↑",
                [4] = "D-PAD ↓"
            },
            M1 = "RT",
            Dash = "A",
            Block = "LT",
            Special = "X",
            Sprint = "LB",
            Ultimate = "R3",
            Awakening = "L3"
        } :: InputPreset,

        Touch = {
            Skill = {
                [1] = "",
                [2] = "",
                [3] = "",
                [4] = ""
            },
            M1 = "",
            Dash = "",
            Block = "",
            Special = "",
            Sprint = "",
            Ultimate = "",
            Awakening = ""
        } :: InputPreset
    }
}

return HUDConfig
