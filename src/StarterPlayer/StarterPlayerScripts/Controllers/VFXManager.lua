--!strict

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local VFXManager = {}

local palettes: {[string]: Color3} = {
    Yuji = Color3.fromRGB(235, 235, 245),
    Gojo = Color3.fromRGB(105, 196, 255),
    Megumi = Color3.fromRGB(118, 92, 190),
    Sukuna = Color3.fromRGB(225, 62, 72)
}

local function reduced(): boolean
    return game:GetService("Players").LocalPlayer:GetAttribute("CC_ReducedEffects") == true
end

local function safeDirection(direction: any): Vector3
    if typeof(direction) == "Vector3" and direction.Magnitude > 0.01 then
        return direction.Unit
    end
    return Vector3.zAxis
end

local function makePart(position: Vector3, size: Vector3, color: Color3, transparency: number?): Part
    local object = Instance.new("Part")
    object.Name = "CC_VFX"
    object.Anchored = true
    object.CanCollide = false
    object.CanTouch = false
    object.CanQuery = false
    object.CastShadow = false
    object.Material = Enum.Material.Neon
    object.Color = color
    object.Transparency = transparency or 0.08
    object.Size = size
    object.Position = position
    object.Parent = workspace
    return object
end

local function tween(object: Instance, duration: number, properties: {[string]: any}, style: Enum.EasingStyle?)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(
            math.max(0.01, duration),
            style or Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        properties
    )
    animation:Play()
    Debris:AddItem(object, duration + 0.08)
    return animation
end

local function ring(position: Vector3, radius: number, color: Color3, duration: number, thickness: number?)
    if reduced() then
        radius *= 0.80
        duration *= 0.85
    end

    local object = makePart(
        position,
        Vector3.new(math.max(0.12, thickness or 0.12), 0.45, 0.45),
        color,
        0.18
    )
    object.Shape = Enum.PartType.Cylinder
    object.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))

    tween(object, duration, {
        Size = Vector3.new(object.Size.X, radius, radius),
        Transparency = 1
    })
end

local function slash(position: Vector3, direction: Vector3, length: number, width: number, color: Color3, roll: number?)
    direction = safeDirection(direction)

    if reduced() then
        length *= 0.82
        width *= 0.85
    end

    local midpoint = position + direction * length * 0.40
    local object = makePart(
        midpoint,
        Vector3.new(width, width, length),
        color,
        0.03
    )
    object.CFrame =
        CFrame.lookAt(midpoint, midpoint + direction)
        * CFrame.Angles(0, 0, math.rad(roll or 0))

    tween(object, 0.14, {
        Size = Vector3.new(width * 0.22, width * 0.22, length * 1.16),
        Transparency = 1
    })
end

local function beam(a: Vector3, b: Vector3, color: Color3, width: number, duration: number)
    if reduced() then
        width *= 0.72
    end

    local pa = makePart(a, Vector3.one * 0.10, color, 1)
    local pb = makePart(b, Vector3.one * 0.10, color, 1)

    local aa = Instance.new("Attachment")
    aa.Parent = pa

    local ab = Instance.new("Attachment")
    ab.Parent = pb

    local beamObject = Instance.new("Beam")
    beamObject.Attachment0 = aa
    beamObject.Attachment1 = ab
    beamObject.Width0 = width
    beamObject.Width1 = width * 0.35
    beamObject.LightEmission = 1
    beamObject.FaceCamera = true
    beamObject.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
    beamObject.Transparency = NumberSequence.new(0.06, 0.86)
    beamObject.Parent = pa

    Debris:AddItem(pa, duration + 0.06)
    Debris:AddItem(pb, duration + 0.06)
end

local function burst(position: Vector3, radius: number, color: Color3, count: number)
    ring(position, radius, color, 0.24, 0.13)

    local attachment = Instance.new("Attachment")
    attachment.Name = "CC_VFX_Burst"
    attachment.WorldPosition = position
    attachment.Parent = workspace.Terrain

    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.16, 0.30)
    emitter.Speed = NumberRange.new(radius * 0.75, radius * 1.45)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.LightEmission = 1
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, math.clamp(radius * 0.05, 0.10, 0.55)),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Color = ColorSequence.new(color)
    emitter.Parent = attachment
    emitter:Emit(reduced() and math.max(4, math.floor(count * 0.55)) or count)

    Debris:AddItem(attachment, 0.55)
end

local function orb(position: Vector3, radius: number, color: Color3, duration: number)
    local object = makePart(
        position,
        Vector3.new(radius, radius, radius),
        color,
        0.05
    )
    object.Shape = Enum.PartType.Ball

    tween(object, duration, {
        Size = Vector3.new(radius * 2.6, radius * 2.6, radius * 2.6),
        Transparency = 1
    }, Enum.EasingStyle.Quad)
end

local function afterimages(position: Vector3, direction: Vector3, color: Color3)
    if reduced() then
        return
    end

    direction = safeDirection(direction)

    for index = 1, 4 do
        local ghost = makePart(
            position - direction * index * 1.35,
            Vector3.new(1.7, 3.2, 1.0),
            color,
            0.78
        )
        ghost.CFrame = CFrame.lookAt(ghost.Position, ghost.Position + direction)
        tween(ghost, 0.24 + index * 0.02, {
            Transparency = 1,
            Size = ghost.Size * 0.72
        })
    end
end

local function shockwave(position: Vector3, color: Color3, radius: number)
    ring(position, radius, color, 0.28, 0.15)
    ring(position + Vector3.new(0, 0.08, 0), radius * 0.62, Color3.new(1, 1, 1), 0.20, 0.08)
end

local function screenFlash(color: Color3, strength: number, duration: number)
    if reduced() then
        strength *= 0.55
        duration *= 0.8
    end

    local effect = Instance.new("ColorCorrectionEffect")
    effect.Name = "CC_VFX_Flash"
    effect.Brightness = strength
    effect.Contrast = strength * 0.45
    effect.Saturation = -0.08
    effect.TintColor = color
    effect.Parent = Lighting

    task.delay(duration, function()
        if effect.Parent then
            TweenService:Create(
                effect,
                TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Brightness = 0, Contrast = 0, Saturation = 0}
            ):Play()
            Debris:AddItem(effect, 0.15)
        end
    end)
end

local function characterColor(name: string): Color3
    return palettes[name] or Color3.fromRGB(175, 130, 255)
end

local function playYuji(position: Vector3, direction: Vector3, move: string, transformed: boolean)
    if string.find(move, "Black Flash") or string.find(move, "BlackFlash") then
        burst(position, transformed and 13 or 9, Color3.fromRGB(26, 27, 33), transformed and 30 or 22)
        beam(position - direction * 1.5, position + direction * 6, Color3.fromRGB(255, 82, 108), 0.34, 0.18)
        screenFlash(Color3.fromRGB(255, 72, 102), transformed and 0.11 or 0.07, 0.13)
    elseif string.find(move, "Dismantle") then
        slash(position, direction, transformed and 25 or 16, transformed and 0.34 or 0.22, Color3.fromRGB(245, 70, 88), 24)
        slash(position + Vector3.new(0, 0.9, 0), direction, transformed and 20 or 12, 0.13, Color3.new(1, 1, 1), -24)
    elseif string.find(move, "Piercing Blood") then
        beam(position, position + direction * (transformed and 34 or 22), Color3.fromRGB(205, 35, 58), 0.42, 0.24)
        orb(position + direction * 4, 0.75, Color3.fromRGB(255, 95, 112), 0.20)
    elseif string.find(move, "Blood Hardened Fist") then
        burst(position + direction * 3, 7, Color3.fromRGB(155, 40, 54), 18)
    elseif string.find(move, "Divergent") or string.find(move, "Cursed Strikes") then
        slash(position + direction * 2, direction, 9, 0.18, Color3.fromRGB(238, 238, 246), 18)
        burst(position + direction * 3, 4.5, Color3.fromRGB(255, 255, 255), 10)
    elseif string.find(move, "Crushing") or string.find(move, "Kick") then
        shockwave(position, Color3.fromRGB(238, 238, 246), 8)
        burst(position + direction * 3, 5, Color3.fromRGB(245, 165, 178), 12)
    end
end

local function playGojo(position: Vector3, direction: Vector3, move: string, transformed: boolean)
    if string.find(move, "Blue") then
        orb(position + direction * 2.5, transformed and 2.5 or 1.9, Color3.fromRGB(91, 191, 255), 0.24)
        ring(position, transformed and 12 or 8, Color3.fromRGB(135, 215, 255), 0.24)
        afterimages(position, -direction, Color3.fromRGB(115, 205, 255))
    elseif string.find(move, "Red") then
        orb(position + direction * 3.2, transformed and 2.7 or 2.1, Color3.fromRGB(255, 76, 88), 0.22)
        shockwave(position, Color3.fromRGB(255, 104, 112), transformed and 17 or 10)
        screenFlash(Color3.fromRGB(255, 88, 95), 0.08, 0.11)
    elseif string.find(move, "Purple") then
        orb(position + direction * 4.5, transformed and 3.8 or 3.0, Color3.fromRGB(190, 105, 255), 0.26)
        beam(position + direction * 2, position + direction * 30, Color3.fromRGB(207, 135, 255), 0.60, 0.26)
        shockwave(position, Color3.fromRGB(164, 103, 255), transformed and 22 or 16)
        screenFlash(Color3.fromRGB(170, 110, 255), 0.14, 0.16)
    elseif string.find(move, "Void") then
        ring(position, transformed and 24 or 18, Color3.fromRGB(118, 165, 255), 0.35)
        burst(position + Vector3.new(0, 3, 0), transformed and 13 or 9, Color3.fromRGB(150, 190, 255), transformed and 30 or 22)
        screenFlash(Color3.fromRGB(105, 150, 255), 0.12, 0.20)
    elseif string.find(move, "Rapid") or string.find(move, "Kick") then
        afterimages(position, direction, characterColor("Gojo"))
        slash(position + direction * 2, direction, 10, 0.16, Color3.fromRGB(205, 236, 255), -20)
    end
end

local function playMegumi(position: Vector3, direction: Vector3, move: string, transformed: boolean)
    if string.find(move, "Mahoraga") then
        shockwave(position, Color3.fromRGB(255, 220, 140), transformed and 24 or 18)
        burst(position + Vector3.new(0, 2, 0), transformed and 15 or 10, Color3.fromRGB(218, 196, 146), transformed and 36 or 24)
        screenFlash(Color3.fromRGB(214, 187, 127), 0.08, 0.14)
    elseif string.find(move, "Elephant") then
        burst(position + direction * 4, 11, Color3.fromRGB(102, 91, 145), 20)
        shockwave(position, Color3.fromRGB(130, 117, 180), 12)
    elseif string.find(move, "Deer") or string.find(move, "Garden") then
        ring(position, 15, Color3.fromRGB(83, 77, 142), 0.32)
        burst(position + Vector3.new(0, 1.5, 0), 8, Color3.fromRGB(132, 111, 206), 16)
    elseif string.find(move, "Toad") or string.find(move, "Serpent") or string.find(move, "Nue") then
        beam(position + Vector3.new(0, 1, 0), position + direction * 12 + Vector3.new(0, 1.5, 0), Color3.fromRGB(111, 93, 183), 0.22, 0.24)
        burst(position + direction * 3, 6, Color3.fromRGB(102, 82, 157), 12)
    else
        burst(position + direction * 2, transformed and 9 or 6, Color3.fromRGB(85, 69, 145), transformed and 18 or 10)
    end
end

local function playSukuna(position: Vector3, direction: Vector3, move: string, transformed: boolean)
    if string.find(move, "Dismantle") or string.find(move, "Cleave") or string.find(move, "Slash") then
        local length = transformed and 28 or 16
        slash(position, direction, length, transformed and 0.35 or 0.24, Color3.fromRGB(235, 50, 58), 22)
        slash(position + Vector3.new(0, 1.1, 0), direction, length * 0.82, 0.13, Color3.new(1, 1, 1), -22)
    elseif string.find(move, "Rush") then
        afterimages(position, -direction, Color3.fromRGB(200, 44, 58))
        shockwave(position + direction * 4, Color3.fromRGB(239, 76, 83), 7)
    elseif string.find(move, "Fuga") or string.find(move, "Fire") then
        orb(position + direction * 4, transformed and 4.0 or 3.0, Color3.fromRGB(255, 106, 43), 0.24)
        beam(position + direction * 4, position + direction * 28, Color3.fromRGB(255, 132, 51), 0.70, 0.28)
        shockwave(position, Color3.fromRGB(255, 92, 41), transformed and 20 or 13)
        screenFlash(Color3.fromRGB(255, 100, 45), 0.10, 0.15)
    elseif string.find(move, "Spiderweb") then
        for angle = 0, 3 do
            local radians = angle * math.pi * 0.5
            local radial = Vector3.new(math.cos(radians), 0, math.sin(radians))
            slash(position, radial, 10, 0.15, Color3.fromRGB(226, 52, 62), angle * 45)
        end
        ring(position, 11, Color3.fromRGB(235, 58, 68), 0.24)
    end
end

function VFXManager:Play(kind: string, position: Vector3, payload: any)
    if typeof(position) ~= "Vector3" then
        return
    end

    payload = type(payload) == "table" and payload or {}

    if kind == "CharacterMove" then
        local move = tostring(payload.move or "")
        local character = tostring(payload.character or "")
        local transformed = payload.transformed == true
            or payload.phase == "Awakening"
            or payload.phase == "Ultimate"

        local direction = safeDirection(payload.direction)

        if character == "Yuji" then
            playYuji(position, direction, move, transformed)
        elseif character == "Gojo" then
            playGojo(position, direction, move, transformed)
        elseif character == "Megumi" then
            playMegumi(position, direction, move, transformed)
        elseif character == "Sukuna" then
            playSukuna(position, direction, move, transformed)
        end

        return
    end

    if kind == "Enchain" then
        shockwave(position, Color3.fromRGB(170, 70, 190), 16)
        burst(position + Vector3.new(0, 2, 0), 11, Color3.fromRGB(188, 91, 207), 28)
        screenFlash(Color3.fromRGB(161, 66, 182), 0.09, 0.14)
        return
    end

    if kind == "MahoragaSummon" then
        shockwave(position, Color3.fromRGB(255, 214, 133), 19)
        burst(position + Vector3.new(0, 2, 0), 14, Color3.fromRGB(229, 204, 155), 34)
        return
    end

    if kind == "MahoragaMode" then
        ring(position, 13, Color3.fromRGB(255, 222, 130), 0.30)
        burst(position + Vector3.new(0, 1.5, 0), 8, Color3.fromRGB(235, 225, 200), 20)
        return
    end

    if kind == "PerfectBlock" then
        shockwave(position, Color3.fromRGB(255, 222, 112), 9)
        burst(position, 5, Color3.fromRGB(255, 244, 179), 18)
        return
    end

    if kind == "BlockImpact" then
        ring(position, 5, Color3.fromRGB(110, 189, 255), 0.16)
        burst(position, 3.5, Color3.fromRGB(150, 210, 255), 9)
        return
    end

    if kind == "Hit" then
        local reaction = tostring(payload.reaction or "Light")
        local color = reaction == "Finisher"
            and Color3.fromRGB(255, 70, 92)
            or reaction == "Heavy" and Color3.fromRGB(255, 168, 92)
            or Color3.fromRGB(230, 235, 245)

        burst(position, reaction == "Finisher" and 8 or 4, color, reaction == "Finisher" and 20 or 9)

        if reaction == "Finisher" or reaction == "Slam" then
            shockwave(position, color, 8)
        end
        return
    end

    if kind == "ProjectileImpact" then
        shockwave(position, Color3.fromRGB(200, 165, 255), 7)
        burst(position, 4.5, Color3.fromRGB(235, 225, 255), 12)
        return
    end

    if kind == "Death" then
        shockwave(position, Color3.fromRGB(255, 76, 96), 10)
        burst(position + Vector3.new(0, 1, 0), 8, Color3.fromRGB(255, 91, 111), 22)
        return
    end

    if kind == "CombatAction" then
        if payload.action == "Dash" then
            local direction = safeDirection(payload.direction)
            afterimages(position, direction, Color3.fromRGB(161, 122, 255))
            ring(position, 4.5, Color3.fromRGB(182, 150, 255), 0.15)
        elseif payload.action == "BlockEnd" then
            ring(position, 3.0, Color3.fromRGB(125, 196, 255), 0.12)
        end
        return
    end

    if kind == "Awakening" or kind == "Ultimate" then
        local character = tostring(payload.character or "")
        local color = characterColor(character)
        shockwave(position, color, 18)
        burst(position + Vector3.new(0, 2, 0), 13, color, 34)
        ring(position, 25, Color3.new(1, 1, 1), 0.40, 0.08)
        screenFlash(color, 0.12, 0.18)
        return
    end

    if kind == "AbilityTimeline" and payload.phase == "HitFrame" then
        ring(position, 5.5, Color3.fromRGB(188, 156, 255), 0.18)
    end
end

return VFXManager
