--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local fx = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FX") :: RemoteEvent

local folder = Instance.new("Folder")
folder.Name = "CBS_LocalFX"
folder.Parent = workspace

local function pulse(position: Vector3, size: number, lifetime: number, color: Color3)
    local part = Instance.new("Part")
    part.Name = "Pulse"
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(0.6, 0.6, 0.6)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.18
    part.Parent = folder
    TweenService:Create(part, TweenInfo.new(lifetime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = Vector3.new(size, size, size),
        Transparency = 1,
    }):Play()
    Debris:AddItem(part, lifetime + 0.05)
end

local function streak(origin: Vector3, direction: Vector3, length: number, color: Color3)
    local part = Instance.new("Part")
    part.Name = "Streak"
    part.Size = Vector3.new(0.25, 0.25, length)
    part.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -length / 2)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.1
    part.Parent = folder
    TweenService:Create(part, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.03, 0.03, length * 0.65),
        Transparency = 1,
    }):Play()
    Debris:AddItem(part, 0.22)
end

local function slash(position: Vector3, rotation: number)
    local part = Instance.new("Part")
    part.Name = "Slash"
    part.Size = Vector3.new(0.22, 3.2, 7.5)
    part.CFrame = CFrame.new(position + Vector3.new(0, 2, 0)) * CFrame.Angles(math.rad(-15), math.rad(rotation), math.rad(18))
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(235, 242, 255)
    part.Transparency = 0.05
    part.Parent = folder
    TweenService:Create(part, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.05, 1.2, 10),
        Transparency = 1,
        CFrame = part.CFrame * CFrame.new(0, 0, -1.6),
    }):Play()
    Debris:AddItem(part, 0.25)
end

local function hitBurst(position: Vector3)
    pulse(position + Vector3.new(0, 1.4, 0), 3.5, 0.17, Color3.fromRGB(255, 238, 214))
    if Players.LocalPlayer:GetAttribute("ReducedVFX") == true then
        return
    end
    for index = 1, 6 do
        local angle = (index / 6) * math.pi * 2
        streak(position + Vector3.new(0, 1.2, 0), Vector3.new(math.cos(angle), 0.1, math.sin(angle)).Unit, 4, Color3.fromRGB(255, 182, 112))
    end
end

fx.OnClientEvent:Connect(function(kind: string, position: Vector3, extra)
    if typeof(position) ~= "Vector3" then return end
    if kind == "M1" or kind == "Swing" then
        slash(position, tonumber(extra) and tonumber(extra) * 55 or 20)
        pulse(position + Vector3.new(0, 1.5, 0), 2.2, 0.14, Color3.fromRGB(205, 221, 255))
    elseif kind == "Hit" then
        hitBurst(position)
    elseif kind == "Dash" then
        local direction = if typeof(extra) == "Vector3" and extra.Magnitude > 0.05 then extra.Unit else Vector3.new(0, 0, -1)
        local steps = if Players.LocalPlayer:GetAttribute("ReducedVFX") == true then 1 else 3
        for step = 1, steps do
            local offset = direction * (-step * 2.6) + Vector3.new(0, 0.8, 0)
            pulse(position + offset, 1.7 + step * 0.35, 0.18 + step * 0.02, Color3.fromRGB(150, 196, 255))
        end
        streak(position + Vector3.new(0, 0.8, 0), direction, 7, Color3.fromRGB(175, 214, 255))
    end
end)
