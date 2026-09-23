--!strict

local UserInputService = game:GetService("UserInputService")

export type Platform = "Touch" | "Gamepad" | "Keyboard"

local HUDPlatform = {}

function HUDPlatform:Get(): Platform
    local preferred = UserInputService.PreferredInput
    if preferred == Enum.PreferredInput.Touch then
        return "Touch"
    end
    if preferred == Enum.PreferredInput.Gamepad then
        return "Gamepad"
    end
    return "Keyboard"
end

function HUDPlatform:IsTouch(): boolean
    return self:Get() == "Touch"
end

function HUDPlatform:IsGamepad(): boolean
    return self:Get() == "Gamepad"
end

function HUDPlatform:Hint(action: string): string
    local platform = self:Get()

    if platform == "Touch" then
        return ({
            M1 = "✊",
            Dash = "➤",
            Block = "◈",
            Special = "★",
            Ultimate = "ULT",
            Awakening = "AWK",
            Sprint = "RUN"
        })[action] or action
    end

    if platform == "Gamepad" then
        return ({
            M1 = "B",
            Dash = "Y",
            Block = "X",
            Special = "D←",
            Ultimate = "D↑",
            Awakening = "R3",
            Sprint = "L1"
        })[action] or action
    end

    return ({
        M1 = "M1",
        Dash = "Q",
        Block = "F",
        Special = "R",
        Ultimate = "G",
        Awakening = "G",
        Sprint = "Shift"
    })[action] or action
end

function HUDPlatform:Changed(callback: (Platform) -> ()): RBXScriptConnection
    callback(self:Get())
    return UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
        callback(self:Get())
    end)
end

return HUDPlatform
