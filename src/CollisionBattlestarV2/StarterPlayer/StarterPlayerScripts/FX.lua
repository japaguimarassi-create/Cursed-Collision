--!strict

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local FX = {}
FX.__index = FX

local function pulse(position: Vector3, size: number, duration: number, color: Color3)
    local p = Instance.new("Part")
    p.Name = "CBS2_FX"
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Shape = Enum.PartType.Ball
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Size = Vector3.new(size, size, size)
    p.Position = position
    p.Parent = workspace

    TweenService:Create(
        p,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = p.Size * 0.15, Transparency = 1}
    ):Play()

    Debris:AddItem(p, duration + 0.05)
end

local function sparks(position: Vector3, count: number, color: Color3)
    local directions = {
        Vector3.xAxis,
        -Vector3.xAxis,
        Vector3.zAxis,
        -Vector3.zAxis,
        Vector3.yAxis,
        -Vector3.yAxis,
    }

    for index = 1, count do
        local direction = directions[((index - 1) % #directions) + 1]
        local p = Instance.new("Part")
        p.Name = "CBS2_Spark"
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Color = color
        p.Size = Vector3.new(0.18, 0.18, 0.7)
        p.CFrame = CFrame.lookAt(position, position + direction)
        p.Parent = workspace

        TweenService:Create(
            p,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {CFrame = p.CFrame + direction * 3, Transparency = 1}
        ):Play()

        Debris:AddItem(p, 0.25)
    end
end

function FX.new(remotes)
    return setmetatable({
        remotes = remotes,
        connection = nil,
    }, FX)
end

function FX:Start()
    self.connection = self.remotes.FX.OnClientEvent:Connect(function(kind, payload)
        if type(payload) ~= "table" then
            return
        end

        local position = payload.position
        if typeof(position) ~= "Vector3" then
            local camera = workspace.CurrentCamera
            position = camera and camera.CFrame.Position or Vector3.zero
        end

        if kind == "Hit" then
            pulse(position, 1.4, 0.12, Color3.fromRGB(245, 245, 255))
            sparks(position, 3, Color3.fromRGB(220, 225, 255))
        elseif kind == "Critical" then
            pulse(position, 2.2, 0.16, Color3.fromRGB(255, 215, 90))
            sparks(position, 5, Color3.fromRGB(255, 220, 110))
        elseif kind == "Defeat" then
            local boss = payload.boss == true
            pulse(position, boss and 7 or payload.elite and 4 or 2.5, boss and 0.35 or 0.18, boss and Color3.fromRGB(255, 70, 80) or Color3.fromRGB(125, 190, 255))
            sparks(position, boss and 8 or 4, boss and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(130, 200, 255))
        elseif kind == "WaveStart" then
            pulse(Vector3.new(0, 1, 0), payload.boss and 10 or 6, payload.boss and 0.45 or 0.25, payload.boss and Color3.fromRGB(255, 65, 75) or Color3.fromRGB(130, 90, 255))
        elseif kind == "Dash" then
            pulse(position, 5, 0.12, Color3.fromRGB(120, 190, 255))
        elseif kind == "Spawn" and payload.boss then
            pulse(position, 7, 0.35, Color3.fromRGB(255, 60, 70))
        elseif kind == "EchoHit" then
            pulse(position, 1.2, 0.12, Color3.fromRGB(90, 235, 170))
        end
    end)
end

function FX:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

return FX
