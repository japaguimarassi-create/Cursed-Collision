--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local InputManager = {}
InputManager.__index = InputManager

local player = Players.LocalPlayer
local bindings: {[string]: {Enum.KeyCode}} = {}
local callbacks: {[string]: (string, Enum.UserInputState, InputObject)->()} = {}
local started = false

function InputManager:BindAction(name: string, callback: (string, Enum.UserInputState, InputObject)->(), keyCodes: {Enum.KeyCode}, touchButton: boolean)
    bindings[name] = keyCodes
    callbacks[name] = callback

    ContextActionService:BindAction(
        name,
        function(actionName, state, object)
            local handler = callbacks[actionName]
            if handler then
                handler(actionName, state, object)
            end
            return Enum.ContextActionResult.Pass
        end,
        touchButton == true,
        table.unpack(keyCodes)
    )
end

function InputManager:SetTouchButton(name: string, title: string, position: UDim2)
    pcall(function()
        ContextActionService:SetTitle(name, title)
        ContextActionService:SetPosition(name, position)
    end)
end

function InputManager:UnbindAction(name: string)
    ContextActionService:UnbindAction(name)
    bindings[name] = nil
    callbacks[name] = nil
end

function InputManager:Emit(name: string, state: Enum.UserInputState, object: InputObject?)
    local callback = callbacks[name]
    if callback then
        callback(name, state, object :: any)
    end
end

function InputManager:IsTouch(): boolean
    return UserInputService.PreferredInput == Enum.PreferredInput.Touch
end

function InputManager:IsGamepad(): boolean
    return UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
end

function InputManager:GetPreferredInput()
    return UserInputService.PreferredInput
end

function InputManager:Start()
    if started then return end
    started = true
    player:SetAttribute("InputDevice", tostring(UserInputService.PreferredInput))
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
    player:SetAttribute("InputDevice", tostring(UserInputService.PreferredInput))
end)

InputManager:Start()

return InputManager
