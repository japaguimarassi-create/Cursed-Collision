--!strict

local UserInputService = game:GetService("UserInputService")

export type Platform = "Touch" | "Gamepad" | "Keyboard"

local HUDPlatform = {}

local function read(): Platform
    local preferred = UserInputService.PreferredInput

    if preferred == Enum.PreferredInput.Touch then
        return "Touch"
    end

    if preferred == Enum.PreferredInput.Gamepad then
        return "Gamepad"
    end

    return "Keyboard"
end

function HUDPlatform:Get(): Platform
    return read()
end

function HUDPlatform:IsTouch(): boolean
    return read() == "Touch"
end

function HUDPlatform:IsGamepad(): boolean
    return read() == "Gamepad"
end

function HUDPlatform:Refresh(handler: (Platform) -> ())
    handler(read())

    return UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
        handler(read())
    end)
end

function HUDPlatform:Hint(action: string): string
    local platform = read()

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
        Awakening = "R3",
        Sprint = "Shift"
    })[action] or action
end

return HUDPlatform
