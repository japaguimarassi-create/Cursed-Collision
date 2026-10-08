--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local InputService = {}
InputService.__index = InputService

local ATTACK_ACTION = "CBS_Attack"
local DASH_ACTION = "CBS_Dash"

function InputService.new(remotes, hud)
    return setmetatable({
        remotes = remotes,
        hud = hud,
        enabled = false,
        stateConnection = nil,
        attackConnection = nil,
        dashConnection = nil,
    }, InputService)
end

function InputService:GetDashDirection()
    local player = Players.LocalPlayer
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        local moveDirection = humanoid.MoveDirection
        local horizontal = Vector3.new(moveDirection.X, 0, moveDirection.Z)
        if horizontal.Magnitude >= 0.1 then
            return horizontal.Unit
        end
    end

    local camera = workspace.CurrentCamera
    if camera then
        local look = camera.CFrame.LookVector
        local horizontalLook = Vector3.new(look.X, 0, look.Z)
        if horizontalLook.Magnitude >= 0.1 then
            return horizontalLook.Unit
        end
    end

    return Vector3.new(0, 0, 1)
end

function InputService:Attack()
    if not self.enabled then
        return
    end

    self.remotes.Combat:FireServer({
        action = "Attack",
    })
end

function InputService:Dash()
    if not self.enabled then
        return
    end

    self.remotes.Combat:FireServer({
        action = "Dash",
        direction = self:GetDashDirection(),
    })
end

function InputService:BindAction(name: string, callback)
    ContextActionService:BindAction(name, function(_, state)
        if state ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Pass
        end

        callback()
        return Enum.ContextActionResult.Sink
    end, false, name == ATTACK_ACTION
        and Enum.UserInputType.MouseButton1
        or Enum.KeyCode.Q
    )
end

function InputService:Start()
    self:BindAction(ATTACK_ACTION, function()
        self:Attack()
    end)

    ContextActionService:BindAction(ATTACK_ACTION .. "_Controller", function(_, state)
        if state == Enum.UserInputState.Begin then
            self:Attack()
        end
        return Enum.ContextActionResult.Sink
    end, false, Enum.KeyCode.ButtonR2)

    ContextActionService:BindAction(DASH_ACTION .. "_Keyboard", function(_, state)
        if state == Enum.UserInputState.Begin then
            self:Dash()
        end
        return Enum.ContextActionResult.Sink
    end, false, Enum.KeyCode.Q)

    ContextActionService:BindAction(DASH_ACTION .. "_Controller", function(_, state)
        if state == Enum.UserInputState.Begin then
            self:Dash()
        end
        return Enum.ContextActionResult.Sink
    end, false, Enum.KeyCode.ButtonB)

    self.attackConnection = self.hud:GetAttackButton().Activated:Connect(function()
        self:Attack()
    end)

    self.dashConnection = self.hud:GetDashButton().Activated:Connect(function()
        self:Dash()
    end)

    self.stateConnection = self.remotes.State.OnClientEvent:Connect(function(kind, snapshot)
        if kind ~= "Snapshot" or type(snapshot) ~= "table" then
            return
        end

        local ready = snapshot.worldReady == true and snapshot.phase ~= "Booting"
        self:SetEnabled(ready)
    end)

    self.remotes.State:FireServer({
        action = "RequestState",
    })
end

function InputService:SetEnabled(enabled: boolean)
    if self.enabled == enabled then
        return
    end

    self.enabled = enabled
    self.hud:SetControlsEnabled(enabled)
end

function InputService:Stop()
    ContextActionService:UnbindAction(ATTACK_ACTION)
    ContextActionService:UnbindAction(ATTACK_ACTION .. "_Controller")
    ContextActionService:UnbindAction(DASH_ACTION .. "_Keyboard")
    ContextActionService:UnbindAction(DASH_ACTION .. "_Controller")

    if self.stateConnection then
        self.stateConnection:Disconnect()
        self.stateConnection = nil
    end

    if self.attackConnection then
        self.attackConnection:Disconnect()
        self.attackConnection = nil
    end

    if self.dashConnection then
        self.dashConnection:Disconnect()
        self.dashConnection = nil
    end
end

return InputService
