--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer

local function sync()
    local preferred = UserInputService.PreferredInput
    player:SetAttribute("InputDevice", tostring(preferred))

    if preferred == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
    end
end

sync()
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(sync)

return nil
