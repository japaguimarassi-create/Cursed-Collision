--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local InputManager = {}
InputManager.__index = InputManager

export type InputCode = Enum.KeyCode | Enum.UserInputType
export type ActionCallback = (string, Enum.UserInputState, InputObject) -> ()

local player = Players.LocalPlayer
local callbacks: {[string]: ActionCallback} = {}
local bindings: {[string]: {InputCode}} = {}
local started = false

function InputManager:BindAction(
    name: string,
    callback: ActionCallback,
    inputCodes: {InputCode},
    touchButton: boolean
)
    self:UnbindAction(name)

    bindings[name] = inputCodes
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
        table.unpack(inputCodes)
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

function InputManager:UnbindAll()
    for name in pairs(bindings) do
        ContextActionService:UnbindAction(name)
        bindings[name] = nil
        callbacks[name] = nil
    end
end

function InputManager:Emit(name: string, state: Enum.UserInputState, object: InputObject?)
    local callback = callbacks[name]
    if callback then
        callback(name, state, object :: InputObject)
    end
end

function InputManager:IsTouch(): boolean
    return UserInputService.PreferredInput == Enum.PreferredInput.Touch
end

function InputManager:IsGamepad(): boolean
    return UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
end

function InputManager:GetPreferredInput(): Enum.PreferredInput
    return UserInputService.PreferredInput
end

function InputManager:Start()
    if started then
        return
    end

    started = true
    player:SetAttribute("InputDevice", tostring(UserInputService.PreferredInput))
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
    player:SetAttribute("InputDevice", tostring(UserInputService.PreferredInput))
end)

InputManager:Start()

return InputManager
