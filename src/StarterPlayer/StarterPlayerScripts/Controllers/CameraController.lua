-- Camera controller

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CameraController = {}

local shake = 0
local shakeSpeed = 26
local fovBase = 70
local fovKick = 0
local connection: RBXScriptConnection?

local function ensure()
    if connection then
        return
    end

    connection = RunService.RenderStepped:Connect(function(dt: number)
        local camera = Workspace.CurrentCamera
        if not camera then
            return
        end

        local targetFov = fovBase + fovKick
        camera.FieldOfView += (targetFov - camera.FieldOfView) * math.min(1, dt * 12)
        fovKick *= math.exp(-dt * 8)

        if shake > 0.01 then
            local t = os.clock() * shakeSpeed
            local offset = Vector3.new(
                math.noise(t, 0, 0),
                math.noise(0, t, 0),
                math.noise(t, t, 0)
            ) * shake
            camera.CFrame = camera.CFrame * CFrame.new(offset)
            shake *= math.exp(-dt * 10)
        else
            shake = 0
        end
    end)
end

function CameraController:Impact(strength, fov)
    ensure()
    shake = math.clamp(shake + (tonumber(strength) or 0.15), 0, 1.8)
    fovKick = math.clamp(fovKick + (tonumber(fov) or 0), -8, 14)
end

function CameraController:SetBaseFov(value)
    fovBase = math.clamp(tonumber(value) or 70, 55, 90)
end

function CameraController:Dash()
    ensure()
    fovKick = math.max(fovKick, 4)
end

function CameraController:Heavy()
    self:Impact(0.22, 5)
end

function CameraController:StrongHit()
    self:Impact(0.3, 6)
end

return CameraController
