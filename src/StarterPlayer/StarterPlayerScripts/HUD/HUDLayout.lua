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
        CombatScaleReference = 690,
        CombatMinScale = 0.70,
        CombatMaxScale = 1.08,
        SkillsWidth = 0.78,
        SkillsY = 0.81,
        ActionsX = 0.78,
        ActionsY = 0.54,
        IdentityWidth = 0.54,
        TopbarButtonWidth = 82,
        TopbarHeight = 46,
        MenuWidth = 0.92,
        MenuHeight = 0.84
    },
    Console = {
        CombatScaleReference = 820,
        CombatMinScale = 0.72,
        CombatMaxScale = 1.08,
        SkillsWidth = 0.72,
        SkillsY = 0.81,
        ActionsX = 0.75,
        ActionsY = 0.54,
        IdentityWidth = 0.32,
        TopbarButtonWidth = 94,
        TopbarHeight = 48,
        MenuWidth = 0.84,
        MenuHeight = 0.78
    },
    PC = {
        CombatScaleReference = 820,
        CombatMinScale = 0.70,
        CombatMaxScale = 1.10,
        SkillsWidth = 0.72,
        SkillsY = 0.81,
        ActionsX = 0.75,
        ActionsY = 0.54,
        IdentityWidth = 0.32,
        TopbarButtonWidth = 94,
        TopbarHeight = 48,
        MenuWidth = 0.84,
        MenuHeight = 0.78
    }
}

local HUDLayout = {}

function HUDLayout:Get(platform: string): Layout
    return layouts[platform] or layouts.PC
end

return HUDLayout
