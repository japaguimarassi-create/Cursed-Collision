--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local state = remotes:WaitForChild("State") :: RemoteEvent
local fx = remotes:WaitForChild("FX") :: RemoteEvent

local BASE_FOV = 70
local DASH_FOV = 84
local ATTACK_FOV = 73
local HIT_FOV = 76

local camera: Camera?
local blur: BlurEffect?
local correction: ColorCorrectionEffect?
local shake = 0
local seed = math.random() * 100

local function ensure()
    local current = workspace.CurrentCamera
    if current ~= camera then
        camera = current
        if blur then blur:Destroy() end
        if correction then correction:Destroy() end
        blur = Instance.new("BlurEffect")
        blur.Name = "CBS_CameraBlur"
        blur.Size = 0
        blur.Parent = current
        correction = Instance.new("ColorCorrectionEffect")
        correction.Name = "CBS_CameraGrade"
        correction.Contrast = 0
        correction.Saturation = 0
        correction.Brightness = 0
        correction.TintColor = Color3.new(1, 1, 1)
        correction.Parent = current
    end
    return current
end

local function tweenFov(value: number, duration: number)
    if player:GetAttribute("CameraFOVEnabled") == false then return end
    local current = ensure()
    if not current then return end
    TweenService:Create(current, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {FieldOfView = value}):Play()
end

local function pulseBlur(size: number, duration: number)
    if player:GetAttribute("ReducedVFX") == true then return end
    ensure()
    if not blur then return end
    TweenService:Create(blur, TweenInfo.new(duration * 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = size}):Play()
    task.delay(duration * 0.35, function()
        if blur then
            TweenService:Create(blur, TweenInfo.new(duration * 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0}):Play()
        end
    end)
end

local function pulseGrade(tint: Color3, contrast: number, brightness: number, duration: number)
    if player:GetAttribute("ReducedVFX") == true then return end
    ensure()
    if not correction then return end
    correction.TintColor = tint
    correction.Contrast = contrast
    correction.Brightness = brightness
    task.delay(duration, function()
        if correction then
            TweenService:Create(correction, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TintColor = Color3.new(1, 1, 1),
                Contrast = 0,
                Brightness = 0,
            }):Play()
        end
    end)
end

local function addShake(amount: number)
    if player:GetAttribute("CameraShakeEnabled") == false then return end
    shake = math.clamp(shake + amount, 0, 3.5)
end

local function dash()
    tweenFov(DASH_FOV, 0.08)
    pulseBlur(7, 0.28)
    addShake(0.55)
    task.delay(0.13, function()
        tweenFov(BASE_FOV, 0.18)
    end)
end

local function attack()
    tweenFov(ATTACK_FOV, 0.05)
    addShake(0.12)
    task.delay(0.08, function()
        tweenFov(BASE_FOV, 0.12)
    end)
end

local function hit()
    tweenFov(HIT_FOV, 0.04)
    pulseBlur(3, 0.14)
    pulseGrade(Color3.fromRGB(255, 228, 228), 0.16, 0.02, 0.11)
    addShake(0.78)
    task.delay(0.07, function()
        tweenFov(BASE_FOV, 0.14)
    end)
end

state.OnClientEvent:Connect(function(kind: string)
    if kind == "Dash" then
        dash()
    elseif kind == "Attack" then
        attack()
    elseif kind == "PvpHit" then
        hit()
    end
end)

fx.OnClientEvent:Connect(function(kind: string)
    if kind == "Dash" then
        dash()
    elseif kind == "Hit" then
        hit()
    elseif kind == "M1" or kind == "Swing" then
        attack()
    end
end)

RunService:BindToRenderStep("CBS_CameraFX", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local current = ensure()
    if not current then return end
    if current.FieldOfView == 0 then
        current.FieldOfView = BASE_FOV
    end
    if shake > 0.01 then
        seed += dt * 18
        local x = math.noise(seed, 0, 0) * shake
        local y = math.noise(0, seed, 0) * shake
        local z = math.noise(0, 0, seed) * shake
        current.CFrame *= CFrame.Angles(math.rad(y), math.rad(x), math.rad(z * 0.45))
        shake = math.max(0, shake - dt * 5.5)
    else
        shake = 0
    end
end)

ensure()
if camera then
    camera.FieldOfView = BASE_FOV
end
