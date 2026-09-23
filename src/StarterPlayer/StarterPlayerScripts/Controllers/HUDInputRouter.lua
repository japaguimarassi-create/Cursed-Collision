--!strict

local HUDInputRouter = {}

export type Callbacks = {
    Action: (string) -> (),
    Dash: () -> (),
    BlockToggle: () -> (),
    SprintToggle: () -> (),
    CharacterMenu: () -> (),
    EmoteMenu: () -> (),
    MainMenu: () -> (),
    OwnerMenu: () -> ()
}

function HUDInputRouter.Bind(hud: any, callbacks: Callbacks)
    for slot = 1, 4 do
        hud.SkillButtons[slot].Activated:Connect(function()
            callbacks.Action("Skill" .. tostring(slot))
        end)
    end

    hud.M1Button.Activated:Connect(function()
        callbacks.Action("M1")
    end)

    hud.DashButton.Activated:Connect(callbacks.Dash)
    hud.BlockButton.Activated:Connect(callbacks.BlockToggle)
    hud.SprintButton.Activated:Connect(callbacks.SprintToggle)
    hud.SpecialButton.Activated:Connect(function()
        callbacks.Action("Special")
    end)

    hud.UltimateButton.Activated:Connect(function()
        callbacks.Action("Ultimate")
    end)

    hud.AwakeningButton.Activated:Connect(function()
        callbacks.Action("Awakening")
    end)

    hud.CharacterButton.Activated:Connect(callbacks.CharacterMenu)
    hud.EmoteButton.Activated:Connect(callbacks.EmoteMenu)
    hud.MenuButton.Activated:Connect(callbacks.MainMenu)
    hud.OwnerButton.Activated:Connect(callbacks.OwnerMenu)
end

return HUDInputRouter
