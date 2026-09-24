--!strict

export type Platform = "Mobile" | "Console" | "PC"

export type Action =
    "M1" | "Dash" | "Block" | "Special"
    | "Skill1" | "Skill2" | "Skill3" | "Skill4"
    | "Ultimate" | "Awakening" | "Sprint"

local ControlMap = {}

local hints: {[Platform]: {[string]: string}} = {
    Mobile = {
        M1 = "✊",
        Dash = "➜",
        Block = "◉",
        Special = "★",
        Skill1 = "1",
        Skill2 = "2",
        Skill3 = "3",
        Skill4 = "4",
        Ultimate = "ULT",
        Awakening = "AWK",
        Sprint = "↗"
    },


    Console = {
        M1 = "B",
        Dash = "Y",
        Block = "X",
        Special = "D←",
        Skill1 = "LB",
        Skill2 = "LT",
        Skill3 = "RB",
        Skill4 = "RT",
        Ultimate = "D→",
        Awakening = "D↑",
        Sprint = "L3"
    },

    PC = {
        M1 = "M1",
        Dash = "Q",
        Block = "F",
        Special = "R",
        Skill1 = "1",
        Skill2 = "2",
        Skill3 = "3",
        Skill4 = "4",
        Ultimate = "T",
        Awakening = "G",
        Sprint = "SHIFT"
    }
}

local bindings: {[Platform]: {[string]: {any}}} = {
    PC = {
        M1 = {Enum.UserInputType.MouseButton1},
        Dash = {Enum.KeyCode.Q},
        Block = {Enum.KeyCode.F},
        Special = {Enum.KeyCode.R},
        Skill1 = {Enum.KeyCode.One},
        Skill2 = {Enum.KeyCode.Two},
        Skill3 = {Enum.KeyCode.Three},
        Skill4 = {Enum.KeyCode.Four},
        Ultimate = {Enum.KeyCode.T},
        Awakening = {Enum.KeyCode.G},
        Sprint = {Enum.KeyCode.LeftShift}
    },

    Console = {
        M1 = {Enum.KeyCode.ButtonB},
        Dash = {Enum.KeyCode.ButtonY},
        Block = {Enum.KeyCode.ButtonX},
        Special = {Enum.KeyCode.DPadLeft},
        Skill1 = {Enum.KeyCode.ButtonL1},
        Skill2 = {Enum.KeyCode.ButtonL2},
        Skill3 = {Enum.KeyCode.ButtonR1},
        Skill4 = {Enum.KeyCode.ButtonR2},
        Ultimate = {Enum.KeyCode.DPadRight},
        Awakening = {Enum.KeyCode.DPadUp},
        Sprint = {Enum.KeyCode.ButtonL3}
    }
}

function ControlMap:GetPlatform(preferred: Enum.PreferredInput): Platform
    if preferred == Enum.PreferredInput.Touch then
        return "Mobile"
    end

    if preferred == Enum.PreferredInput.Gamepad then
        return "Console"
    end

    return "PC"
end

function ControlMap:GetHint(platform: Platform, action: string): string
    local set: {[string]: string} = hints[platform] or (hints :: any)["PC"]
    return set[action] or action
end

function ControlMap:GetKeyboardConsoleBindings(platform: "Console" | "PC", action: string): {any}
    local set = bindings[platform]
    return if set then set[action] or {} else {}
end

return ControlMap
