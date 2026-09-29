--!strict

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Service = {}
local active = 0
local maxActive = 24

local function emitBall(position: Vector3, size: number, color: Color3, lifetime: number)
    if active >= maxActive then
        return
    end

    active += 1
    local part = Instance.new("Part")
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(size, size, size)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.1
    part.Parent = workspace

    TweenService:Create(part, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(size * 3, size * 3, size * 3),
        Transparency = 1,
    }):Play()

    Debris:AddItem(part, lifetime + 0.05)
    task.delay(lifetime + 0.1, function()
        active = math.max(0, active - 1)
    end)
end

function Service.Init()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    remotes:WaitForChild("FX").OnClientEvent:Connect(function(kind: string, position: Vector3)
        if kind == "M1" then
            emitBall(position, 0.28, Color3.fromRGB(74, 220, 255), 0.12)
        elseif kind == "Hit" then
            emitBall(position, 0.45, Color3.fromRGB(255, 222, 108), 0.18)
        elseif kind == "Dash" then
            emitBall(position, 0.35, Color3.fromRGB(103, 242, 187), 0.16)
        end
    end)
end

return Service