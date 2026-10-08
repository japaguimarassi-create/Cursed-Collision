--!strict

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local CombatFX = {}
CombatFX.__index = CombatFX

local function makeImpact(position: Vector3, elite: boolean)
    local part = Instance.new("Part")
    part.Name = "CBS_LocalImpact"
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Shape = Enum.PartType.Ball
    part.Size = elite and Vector3.new(2.2, 2.2, 2.2) or Vector3.new(1.3, 1.3, 1.3)
    part.Color = elite and Color3.fromRGB(255, 50, 60) or Color3.fromRGB(245, 245, 255)
    part.Position = position
    part.Parent = workspace

    local light = Instance.new("PointLight")
    light.Brightness = elite and 4 or 1.5
    light.Range = elite and 12 or 6
    light.Color = part.Color
    light.Parent = part

    TweenService:Create(
        part,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = part.Size * 0.25,
            Transparency = 1,
        }
    ):Play()

    Debris:AddItem(part, 0.15)
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
            makeImpact(payload.position, payload.elite == true)
        elseif kind == "Dash" and typeof(payload.position) == "Vector3" then
            self:MakeDashPulse(payload.position)
        end
    end)
end

function CombatFX:MakeDashPulse(position: Vector3)
    local part = Instance.new("Part")
    part.Name = "CBS_LocalDash"
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Shape = Enum.PartType.Cylinder
    part.Size = Vector3.new(0.25, 2, 2)
    part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    part.Color = Color3.fromRGB(120, 190, 255)
    part.Parent = workspace

    TweenService:Create(
        part,
        TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(0.25, 7, 7),
            Transparency = 1,
        }
    ):Play()

    Debris:AddItem(part, 0.18)
end

function CombatFX:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

return CombatFX
