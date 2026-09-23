--!strict

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CameraController = {}

local camera = workspace.CurrentCamera
local baseFov = Config.Camera.DefaultFov
local shake = 0
local shakeUntil = 0
local targetFov = baseFov

local function refresh()
    camera = workspace.CurrentCamera or camera
end

local function setFov(value: number, duration: number)
    refresh()
    if not camera then return end
    targetFov = value

    if duration <= 0 then
        camera.FieldOfView = value
        return
    end

    TweenService:Create(
        camera,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {FieldOfView = value}
    ):Play()
end

function CameraController:Shake(intensity: number, duration: number)
    shake = math.max(shake, math.clamp(intensity, 0, 2))
    shakeUntil = math.max(shakeUntil, os.clock() + math.max(0.01, duration))
end

function CameraController:FovKick(amount: number, duration: number)
    setFov(baseFov + math.clamp(amount, -15, 15), 0.04)

    task.delay(math.max(0.04, duration), function()
        if os.clock() >= shakeUntil then
            setFov(baseFov, 0.14)
        end
    end)
end

function CameraController:Impact(strength: number, fov: number)
    self:Shake(strength, 0.10)
    self:FovKick(fov, 0.10)
end

function CameraController:Dash()
    self:FovKick(5, 0.12)
end

function CameraController:Heavy()
    self:Impact(0.40, 5)
end

function CameraController:StrongHit()
    self:Impact(0.55, 6)
end

function CameraController:SetBaseFov(value: number)
    baseFov = math.clamp(tonumber(value) or 70, 45, 100)
    setFov(baseFov, 0.12)
end

function CameraController:OnCombatEvent(kind: string, payload: any)
    if kind == "PerfectBlock" then
        self:Impact(0.34, 4.5)
        return
    end

    if kind == "BlockImpact" then
        self:Impact(0.16, 1.5)
        return
    end

    if kind == "Hit" then
        local reaction = tostring(payload and payload.reaction or "Light")

        if reaction == "Finisher" then
            self:Impact(0.70, 7)
        elseif reaction == "Slam" then
            self:Impact(0.62, 6)
        elseif reaction == "Heavy" then
            self:Impact(0.52, 5.5)
        elseif reaction == "Launch" then
            self:Impact(0.38, 4)
        else
            self:Impact(0.22, 2.5)
        end

        return
    end

    if kind == "CombatAction" and payload then
        local action = tostring(payload.action or "")
        if action == "Dash" then
            self:Dash()
        elseif action == "Special" then
            self:FovKick(4, 0.18)
        elseif string.sub(action, 1, 2) == "M1" then
            self:Shake(0.10, 0.05)
        end

        return
    end

    if kind == "Ultimate" then
        self:Shake(0.55, 0.30)
        self:FovKick(9, 0.40)
    elseif kind == "Awakening" then
        self:Shake(0.70, 0.55)
        self:FovKick(11, 0.65)
    end
end

RunService.RenderStepped:Connect(function()
    refresh()
    if not camera then return end

    local now = os.clock()

    if now < shakeUntil and shake > 0 then
        local fade = math.clamp((shakeUntil - now) / 0.18, 0, 1)
        local amount = shake * fade

        camera.CFrame = camera.CFrame
            * CFrame.Angles(
                math.rad((math.random() - 0.5) * amount * 1.9),
                math.rad((math.random() - 0.5) * amount * 1.9),
                math.rad((math.random() - 0.5) * amount * 1.1)
            )
    else
        shake = 0
        if math.abs(camera.FieldOfView - targetFov) > 0.12 then
            camera.FieldOfView += (targetFov - camera.FieldOfView) * 0.12
        end
    end
end)

return CameraController
