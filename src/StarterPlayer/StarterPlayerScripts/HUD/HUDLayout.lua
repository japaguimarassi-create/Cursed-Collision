--!strict

export type Layout = {
    CombatScaleReference: number,
    CombatMinScale: number,
    CombatMaxScale: number,
    SkillsWidth: number,
    SkillsY: number,
    ActionsX: number,
    ActionsY: number,
    IdentityWidth: number,
    TopbarButtonWidth: number,
    TopbarHeight: number,
    MenuWidth: number,
    MenuHeight: number
}

local layouts: {[string]: Layout} = {
    Mobile = {
        CombatScaleReference = 720,
        CombatMinScale = 0.78,
        CombatMaxScale = 1.05,
        SkillsWidth = 0.46,
        SkillsY = 0.91,
        ActionsX = 0.87,
        ActionsY = 0.64,
        IdentityWidth = 0.34,
        TopbarButtonWidth = 76,
        TopbarHeight = 44,
        MenuWidth = 0.92,
        MenuHeight = 0.84
    },
    Console = {
        CombatScaleReference = 820,
        CombatMinScale = 0.76,
        CombatMaxScale = 1.06,
        SkillsWidth = 0.43,
        SkillsY = 0.88,
        ActionsX = 0.86,
        ActionsY = 0.61,
        IdentityWidth = 0.30,
        TopbarButtonWidth = 92,
        TopbarHeight = 44,
        MenuWidth = 0.86,
        MenuHeight = 0.80
    },
    PC = {
        CombatScaleReference = 900,
        CombatMinScale = 0.72,
        CombatMaxScale = 1.05,
        SkillsWidth = 0.41,
        SkillsY = 0.875,
        ActionsX = 0.86,
        ActionsY = 0.61,
        IdentityWidth = 0.28,
        TopbarButtonWidth = 92,
        TopbarHeight = 44,
        MenuWidth = 0.84,
        MenuHeight = 0.78
    }
}

local HUDLayout = {}

function HUDLayout:Get(platform: string): Layout
    return layouts[platform] or layouts.PC
end

return HUDLayout
