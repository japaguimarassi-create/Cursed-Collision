--!strict

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local CombatFX = {}
CombatFX.__index = CombatFX

local function makePart(name: string, size: Vector3, position: Vector3, color: Color3, transparency: number?)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Size = size
    part.Color = color
    part.Transparency = transparency or 0
    part.Position = position
    part.Parent = workspace
    return part
end

local function makeRing(position: Vector3, size: number, color: Color3, life: number)
    local part = makePart(
        "CBS_LocalRing",
        Vector3.new(0.22, 1.5, 1.5),
        position,
        color,
        0.1
    )

    part.Shape = Enum.PartType.Cylinder
    part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))

    TweenService:Create(
        part,
        TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(0.22, size, size),
            Transparency = 1,
        }
    ):Play()

    Debris:AddItem(part, life + 0.04)
end

local function makeBurst(position: Vector3, color: Color3, count: number, speed: number)
    local directions = {
        Vector3.new(1, 0.4, 0),
        Vector3.new(-1, 0.5, 0.2),
        Vector3.new(0.2, 0.6, 1),
        Vector3.new(-0.3, 0.5, -1),
        Vector3.new(0, 1, 0),
        Vector3.new(0, -0.3, 1),
    }

    for index = 1, count do
        local direction = directions[((index - 1) % #directions) + 1]
        local part = makePart(
            "CBS_LocalSpark",
            Vector3.new(0.18, 0.18, 0.65),
            position,
            color
        )

        part.CFrame = CFrame.lookAt(position, position + direction)
        TweenService:Create(
            part,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                CFrame = part.CFrame + direction.Unit * speed,
                Transparency = 1,
            }
        ):Play()

        Debris:AddItem(part, 0.24)
    end
end

local function makeImpact(position: Vector3, elite: boolean, critical: boolean)
    local color = elite
        and Color3.fromRGB(255, 55, 65)
        or critical
            and Color3.fromRGB(255, 215, 90)
            or Color3.fromRGB(245, 245, 255)

    local core = makePart(
        "CBS_LocalImpact",
        elite and Vector3.new(2.2, 2.2, 2.2) or Vector3.new(1.3, 1.3, 1.3),
        position,
        color,
        0.05
    )
    core.Shape = Enum.PartType.Ball

    TweenService:Create(
        core,
        TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = core.Size * 0.2,
            Transparency = 1,
        }
    ):Play()

    makeRing(position, elite and 9 or 5, color, 0.18)
    makeBurst(position, color, elite and 6 or critical and 4 or 3, elite and 3.5 or 2.5)
end

function CombatFX.new(remotes)
    return setmetatable({
        remotes = remotes,
        connection = nil,
    }, CombatFX)
end

function CombatFX:Start()
    self.connection = self.remotes.FX.OnClientEvent:Connect(function(kind, payload)
        if type(payload) ~= "table" then
            return
        end

        if kind == "Hit" and typeof(payload.position) == "Vector3" then
            makeImpact(
                payload.position,
                payload.elite == true,
                payload.critical == true
            )
        elseif kind == "PvPHit" and typeof(payload.position) == "Vector3" then
            makeImpact(payload.position, false, payload.critical == true)
        elseif kind == "EnemyDefeated" and typeof(payload.position) == "Vector3" then
            makeRing(payload.position, payload.boss and 14 or payload.elite and 10 or 7, payload.boss and Color3.fromRGB(255, 70, 75) or Color3.fromRGB(120, 210, 255), payload.boss and 0.35 or 0.2)
            makeBurst(payload.position, payload.boss and Color3.fromRGB(255, 70, 75) or Color3.fromRGB(120, 210, 255), payload.boss and 8 or 4, payload.boss and 5 or 3)
        elseif kind == "WaveStart" and typeof(payload.position) == "Vector3" then
            makeRing(payload.position, 24, Color3.fromRGB(140, 90, 255), 0.35)
        elseif kind == "BossSpawn" and typeof(payload.position) == "Vector3" then
            makeRing(payload.position, 30, Color3.fromRGB(255, 50, 60), 0.5)
            makeBurst(payload.position, Color3.fromRGB(255, 70, 75), 8, 4.5)
        elseif kind == "EchoHeal" and typeof(payload.position) == "Vector3" then
            makeRing(payload.position, 6, Color3.fromRGB(90, 235, 150), 0.22)
        elseif kind == "Dash" and typeof(payload.position) == "Vector3" then
            self:MakeDashPulse(payload.position)
        end
    end)
end

function CombatFX:MakeDashPulse(position: Vector3)
    makeRing(position, 7, Color3.fromRGB(120, 190, 255), 0.14)
end

function CombatFX:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

return CombatFX
