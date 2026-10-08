--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraService = {}
CameraService.__index = CameraService

function CameraService.new()
    return setmetatable({
        characterConnection = nil,
        renderConnection = nil,
    }, CameraService)
end

function CameraService:Apply(character: Model)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
    camera.FieldOfView = 72
end

function CameraService:Start()
    local player = Players.LocalPlayer

    self.characterConnection = player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Humanoid", 8)
        self:Apply(character)
    end)

    self.renderConnection = RunService.PreRender:Connect(function()
        local camera = workspace.CurrentCamera
        if camera and camera.CameraType == Enum.CameraType.Scriptable then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                camera.CameraType = Enum.CameraType.Custom
                camera.CameraSubject = humanoid
            end
        end
    end)

    if player.Character then
        self:Apply(player.Character)
    end
end

function CameraService:Stop()
    if self.characterConnection then
        self.characterConnection:Disconnect()
        self.characterConnection = nil
    end

    if self.renderConnection then
        self.renderConnection:Disconnect()
        self.renderConnection = nil
    end
end

return CameraService
