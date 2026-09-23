--!strict

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- Combat input now belongs exclusively to the isolated Combat HUD module.
-- Este script permanece apenas como compatibilidade para navegação de console.
local function sync()
    GuiService.GuiNavigationEnabled =
        UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
end

sync()
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(sync)
