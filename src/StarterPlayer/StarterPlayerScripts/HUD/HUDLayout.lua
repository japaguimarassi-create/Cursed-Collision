--!strict

export type Layout = {
    CombatScaleReference: number,
    CombatMinScale: number,
    CombatMaxScale: number,
    SkillsY: number,
    ActionsX: number,
    ActionsY: number,
    TopbarHeight: number,
    MenuWidth: number,
    MenuHeight: number
}

local layouts: {[string]: Layout} = {
    Mobile = {
        CombatScaleReference = 720,
        CombatMinScale = 0.78,
        CombatMaxScale = 1.08,
        SkillsY = 0.89,
        ActionsX = 0.885,
        ActionsY = 0.67,
        TopbarHeight = 42,
        MenuWidth = 0.92,
        MenuHeight = 0.84
    },
    Console = {
        CombatScaleReference = 820,
        CombatMinScale = 0.76,
        CombatMaxScale = 1.08,
        SkillsY = 0.87,
        ActionsX = 0.87,
        ActionsY = 0.62,
        TopbarHeight = 42,
        MenuWidth = 0.86,
        MenuHeight = 0.80
    },
    PC = {
        CombatScaleReference = 900,
        CombatMinScale = 0.72,
        CombatMaxScale = 1.08,
        SkillsY = 0.865,
        ActionsX = 0.86,
        ActionsY = 0.61,
        TopbarHeight = 42,
        MenuWidth = 0.84,
        MenuHeight = 0.78
    }
}

local HUDLayout = {}

function HUDLayout:Get(platform: string): Layout
    return layouts[platform] or layouts.PC
end

return HUDLayout