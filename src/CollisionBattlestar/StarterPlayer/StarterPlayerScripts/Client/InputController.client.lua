--!strict

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local actionRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Action") :: RemoteEvent
local Controller = {}
local initialized = false

local function currentDirection(): Vector3?
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end

    local direction = humanoid.MoveDirection
    if direction.Magnitude < 0.1 then
        return nil
    end

    return Vector3.new(direction.X, 0, direction.Z).Unit
end

local function bind(name: string, inputs: {Enum.KeyCode | Enum.UserInputType}, actionName: string)
    ContextActionService:UnbindAction(name)
    ContextActionService:BindAction(name, function(_, state)
        if state ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Pass
        end

        if actionName == "Dash" then
            actionRemote:FireServer(actionName, currentDirection())
        else
            actionRemote:FireServer(actionName)
        end

        return Enum.ContextActionResult.Sink
    end, false, table.unpack(inputs))
end

function Controller:Init()
    if initialized then
        return
    end

    bind("CBS_Attack", {Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2}, "M1")
    bind("CBS_Dash", {Enum.KeyCode.Q, Enum.KeyCode.ButtonB}, "Dash")
    initialized = true
end

return Controller
