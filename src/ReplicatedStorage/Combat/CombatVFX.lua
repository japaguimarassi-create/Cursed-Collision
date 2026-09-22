local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local VFX = {}

local palette = {
    Yuji = Color3.fromRGB(255, 255, 255),
    Gojo = Color3.fromRGB(126, 205, 255),
    Sukuna = Color3.fromRGB(214, 72, 82),
    Megumi = Color3.fromRGB(92, 74, 146),
    Yuta = Color3.fromRGB(189, 116, 255),
    Maki = Color3.fromRGB(214, 214, 222),
    Toji = Color3.fromRGB(105, 112, 126),
    Mahito = Color3.fromRGB(117, 235, 202),
    Todo = Color3.fromRGB(255, 194, 78),
    Hakari = Color3.fromRGB(255, 97, 170),
    Choso = Color3.fromRGB(176, 33, 55),
    Kashimo = Color3.fromRGB(102, 203, 255),
    Naoya = Color3.fromRGB(180, 212, 255),
    Kenjaku = Color3.fromRGB(109, 82, 137),
    Jogo = Color3.fromRGB(255, 109, 55),
    Dagon = Color3.fromRGB(73, 181, 217),
    Hanami = Color3.fromRGB(101, 188, 101),
    Higuruma = Color3.fromRGB(225, 225, 235),
    Takaba = Color3.fromRGB(255, 219, 93),
    Uraume = Color3.fromRGB(161, 235, 255),
    Yorozu = Color3.fromRGB(228, 154, 229),
    Ryu = Color3.fromRGB(231, 129, 69),
    Uro = Color3.fromRGB(157, 209, 255),
    Kusakabe = Color3.fromRGB(185, 194, 207)
}

local white = Color3.fromRGB(255, 255, 255)
local black = Color3.fromRGB(12, 12, 17)
local activeShakes = 0
local shakeMagnitude = 0
local shakeUntil = 0
local fovTween
local baseFov

local function getCamera()
    return Workspace.CurrentCamera
end

local function cleanup(instance, duration)
    Debris:AddItem(instance, duration + 0.05)
end

local function part(position, size, color, material, transparency)
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = material or Enum.Material.Neon
    p.Color = color
    p.Transparency = transparency or 0
    p.Size = size
    p.Position = position
    p.Parent = Workspace
    return p
end

local function sphere(position, size, color, duration)
    local p = part(position, Vector3.new(size, size, size), color, Enum.Material.Neon, 0.05)
    p.Shape = Enum.PartType.Ball
    local tween = TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(size * 2.5, size * 2.5, size * 2.5),
        Transparency = 1
    })
    tween:Play()
    cleanup(p, duration)
    return p
end

local function disc(position, diameter, height, color, duration, finalDiameter)
    local p = part(position, Vector3.new(diameter, height, diameter), color, Enum.Material.Neon, 0.2)
    p.Shape = Enum.PartType.Cylinder
    local tween = TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = Vector3.new(finalDiameter or diameter * 2.2, height, finalDiameter or diameter * 2.2),
        Transparency = 1
    })
    tween:Play()
    cleanup(p, duration)
    return p
end

local function slash(position, direction, length, width, color, rotation, duration)
    if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.01 then
        direction = Vector3.zAxis
    end
    direction = direction.Unit
    local midpoint = position + direction * (length * 0.45)
    local p = part(midpoint, Vector3.new(width, width, length), color, Enum.Material.Neon, 0.05)
    p.CFrame = CFrame.lookAt(midpoint, midpoint + direction) * CFrame.Angles(0, 0, math.rad(rotation or 0))
    local tween = TweenService:Create(p, TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(width * 0.25, width * 0.25, length * 1.15)
    })
    tween:Play()
    cleanup(p, duration or 0.16)
    return p
end

local function line(position, direction, length, width, color, duration)
    if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.01 then
        direction = Vector3.zAxis
    end
    direction = direction.Unit
    local p = part(position + direction * (length * 0.5), Vector3.new(width, width, length), color, Enum.Material.Neon, 0.06)
    p.CFrame = CFrame.lookAt(p.Position, p.Position + direction)
    local tween = TweenService:Create(p, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(width * 0.18, width * 0.18, length * 1.4)
    })
    tween:Play()
    cleanup(p, duration or 0.18)
    return p
end

local function beam(a, b, color, width, duration)
    if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
        return
    end
    local pa = part(a, Vector3.one * 0.2, color, Enum.Material.Neon, 1)
    local pb = part(b, Vector3.one * 0.2, color, Enum.Material.Neon, 1)
    local aa = Instance.new("Attachment")
    aa.Parent = pa
    local ab = Instance.new("Attachment")
    ab.Parent = pb
    local beamObject = Instance.new("Beam")
    beamObject.Attachment0 = aa
    beamObject.Attachment1 = ab
    beamObject.Width0 = width
    beamObject.Width1 = width * 0.55
    beamObject.LightEmission = 1
    beamObject.FaceCamera = true
    beamObject.Color = ColorSequence.new(color, white)
    beamObject.Transparency = NumberSequence.new(0.04, 0.85)
    beamObject.Parent = pa
    cleanup(pa, duration)
    cleanup(pb, duration)
    return beamObject
end

local function shards(position, direction, color, count, spread, size, duration)
    local rng = Random.new()
    direction = typeof(direction) == "Vector3" and direction.Magnitude > 0.01 and direction.Unit or Vector3.zAxis
    for _ = 1, count do
        local offset = direction * rng:NextNumber(1.0, spread) + Vector3.new(
            rng:NextNumber(-spread * 0.35, spread * 0.35),
            rng:NextNumber(-spread * 0.25, spread * 0.25),
            rng:NextNumber(-spread * 0.35, spread * 0.35)
        )
        local p = part(position, Vector3.new(size, size * 0.35, size * 2.4), color, Enum.Material.Neon, 0.08)
        p.CFrame = CFrame.lookAt(position, position + offset.Unit) * CFrame.Angles(
            rng:NextNumber(-0.8, 0.8),
            rng:NextNumber(-0.8, 0.8),
            rng:NextNumber(-0.8, 0.8)
        )
        local goal = position + offset * 1.25
        local tween = TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = goal,
            Transparency = 1
        })
        tween:Play()
        cleanup(p, duration)
    end
end

local function orbit(position, radius, color, count, duration)
    local rng = Random.new()
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local p = sphere(
            position + Vector3.new(math.cos(angle) * radius, rng:NextNumber(-1.5, 1.5), math.sin(angle) * radius),
            rng:NextNumber(0.25, 0.5),
            color,
            duration
        )
        p.Transparency = 0.12
    end
end

local function cameraKick(amount, duration)
    local camera = getCamera()
    if not camera then
        return
    end
    baseFov = baseFov or camera.FieldOfView
    if fovTween then
        fovTween:Cancel()
    end
    camera.FieldOfView = math.clamp(baseFov + amount, 50, 110)
    fovTween = TweenService:Create(camera, TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        FieldOfView = baseFov
    })
    fovTween:Play()

    activeShakes += 1
    shakeMagnitude = math.max(shakeMagnitude, amount * 0.16)
    shakeUntil = math.max(shakeUntil, os.clock() + (duration or 0.16))
end

RunService.RenderStepped:Connect(function()
    if shakeUntil <= os.clock() then
        shakeMagnitude = 0
        return
    end
    local camera = getCamera()
    if not camera then
        return
    end
    local fade = math.clamp((shakeUntil - os.clock()) / 0.18, 0, 1)
    local amount = shakeMagnitude * fade
    local x = (math.random() - 0.5) * amount
    local y = (math.random() - 0.5) * amount
    local z = (math.random() - 0.5) * amount
    camera.CFrame = camera.CFrame * CFrame.new(x, y, z)
end)

local function common(origin, color, power)
    sphere(origin, 1.1 + power * 0.018, color, 0.13)
    disc(origin, 2.8 + power * 0.05, 0.12, color, 0.18, 7 + power * 0.13)
end

local function targetDirection(origin, data)
    if data and typeof(data.target) == "Vector3" then
        local delta = data.target - origin
        if delta.Magnitude > 0.01 then
            return delta.Unit
        end
    end
    if data and typeof(data.direction) == "Vector3" and data.direction.Magnitude > 0.01 then
        return data.direction.Unit
    end
    return Vector3.zAxis
end

local function gojo(origin, direction, move)
    if move == "Lapse Blue" or move == "Blue" then
        sphere(origin + direction * 4, 2.5, Color3.fromRGB(68, 165, 255), 0.22)
        orbit(origin + direction * 4, 2.8, Color3.fromRGB(154, 224, 255), 7, 0.22)
        line(origin + direction * 4, -direction, 10, 0.22, Color3.fromRGB(83, 189, 255), 0.22)
        cameraKick(2.5, 0.13)
    elseif move == "Reversal Red" or move == "Red" then
        sphere(origin + direction * 4, 2.8, Color3.fromRGB(255, 87, 104), 0.18)
        disc(origin + direction * 5, 5, 0.14, Color3.fromRGB(255, 100, 116), 0.22, 18)
        shards(origin + direction * 4, direction, Color3.fromRGB(255, 184, 192), 10, 8, 0.22, 0.28)
        cameraKick(3.5, 0.17)
    else
        local start = origin + direction * 3.5
        local finish = origin + direction * 32
        beam(start, finish, Color3.fromRGB(192, 109, 255), 2.2, 0.32)
        beam(start + Vector3.new(0, 1.2, 0), finish + Vector3.new(0, 1.2, 0), Color3.fromRGB(107, 187, 255), 0.85, 0.3)
        sphere(start, 3.8, Color3.fromRGB(206, 118, 255), 0.24)
        disc(finish, 8, 0.18, Color3.fromRGB(207, 114, 255), 0.28, 20)
        cameraKick(6, 0.3)
    end
end

local function sukuna(origin, direction, move)
    if move == "Fire Arrow" or move == "Fire" then
        sphere(origin + direction * 5, 2.1, Color3.fromRGB(255, 102, 49), 0.2)
        line(origin + direction * 5, direction, 26, 0.55, Color3.fromRGB(255, 127, 47), 0.28)
        shards(origin + direction * 8, direction, Color3.fromRGB(255, 212, 131), 14, 12, 0.2, 0.34)
        cameraKick(4.5, 0.2)
    else
        for i = 1, 4 do
            slash(origin + direction * (i * 1.8), direction, 10 + i, 0.18, Color3.fromRGB(234, 87, 97), (i % 2 == 0 and -28 or 28), 0.14)
        end
        shards(origin + direction * 6, direction, Color3.fromRGB(255, 185, 185), 8, 7, 0.16, 0.22)
        cameraKick(3, 0.16)
    end
end

local function megumi(origin, direction, move)
    local shadow = Color3.fromRGB(66, 51, 107)
    disc(origin, 5, 0.12, shadow, 0.3, 15)
    if move == "Nue" then
        for i = 1, 7 do
            local offset = Vector3.new((i - 4) * 1.2, 2 + math.sin(i) * 0.6, 0) + direction * 3
            sphere(origin + offset, 0.5, Color3.fromRGB(122, 177, 255), 0.28)
        end
        line(origin + direction * 2, direction, 12, 0.26, Color3.fromRGB(133, 189, 255), 0.24)
    elseif move == "Mahoraga" then
        disc(origin, 8, 0.18, Color3.fromRGB(98, 78, 146), 0.45, 27)
        orbit(origin, 5.4, Color3.fromRGB(214, 200, 255), 8, 0.45)
        cameraKick(4, 0.22)
    else
        shards(origin + direction * 3, direction, shadow, 12, 9, 0.24, 0.3)
    end
end

local function yuta(origin, direction, move)
    sphere(origin + Vector3.new(0, 1.6, 0), 2.4, Color3.fromRGB(205, 139, 255), 0.2)
    orbit(origin + Vector3.new(0, 1.6, 0), 3.1, Color3.fromRGB(241, 203, 255), 6, 0.24)
    slash(origin, direction, 8, 0.24, Color3.fromRGB(239, 228, 255), -34, 0.18)
    slash(origin, direction, 7, 0.2, Color3.fromRGB(178, 119, 255), 34, 0.18)
    if move == "Copy / Rika" then
        sphere(origin + direction * 5, 3.4, Color3.fromRGB(161, 90, 235), 0.24)
        cameraKick(3.5, 0.18)
    end
end

local function weaponUser(origin, direction, character)
    local color = palette[character]
    for i = 1, 3 do
        slash(origin + direction * (i * 0.8), direction, 8 + i * 1.5, 0.18 + i * 0.03, color, i % 2 == 0 and -22 or 22, 0.12)
    end
    shards(origin + direction * 3, direction, white, 6, 6, 0.13, 0.2)
    cameraKick(2.8, 0.15)
end

local function mahito(origin, direction, move)
    sphere(origin + direction * 3, 2.2, palette.Mahito, 0.23)
    for i = 1, 5 do
        local angle = (i / 5) * math.pi * 2
        local side = Vector3.new(math.cos(angle), math.sin(angle) * 0.5, math.sin(angle))
        line(origin + side * 1.5, direction + side * 0.5, 6, 0.16, palette.Mahito, 0.24)
    end
    if move == "Body Morph" then
        shards(origin, direction, Color3.fromRGB(203, 255, 238), 12, 6, 0.22, 0.34)
    end
end

local function todo(origin, direction)
    disc(origin, 3.5, 0.12, palette.Todo, 0.2, 11)
    for i = -1, 1, 2 do
        beam(origin + Vector3.new(i * 1.8, 1.2, 0), origin + Vector3.new(i * 1.8, 1.2, 2), white, 0.35, 0.16)
    end
    cameraKick(2.2, 0.12)
end

local function hakari(origin, direction, move)
    local pink = palette.Hakari
    disc(origin, 4, 0.12, pink, 0.25, 14)
    orbit(origin + Vector3.new(0, 1.3, 0), 3.4, Color3.fromRGB(255, 208, 226), 8, 0.28)
    if move == "Jackpot Roll" then
        for i = 1, 8 do
            local offset = Vector3.new((i - 4.5) * 0.9, 1.5 + (i % 2), 0) + direction * 2
            sphere(origin + offset, 0.42, Color3.fromRGB(255, 239, 244), 0.3)
        end
    else
        cameraKick(3, 0.15)
    end
end

local function choso(origin, direction)
    local red = palette.Choso
    line(origin + direction * 3, direction, 24, 0.34, red, 0.27)
    shards(origin + direction * 8, direction, Color3.fromRGB(247, 116, 130), 9, 8, 0.18, 0.3)
    disc(origin + direction * 6, 3.8, 0.12, red, 0.2, 10)
    cameraKick(3, 0.16)
end

local function kashimo(origin, direction)
    local cyan = palette.Kashimo
    beam(origin + Vector3.new(-2, 2, 0), origin + direction * 10 + Vector3.new(2, 4, 0), cyan, 0.45, 0.22)
    beam(origin + Vector3.new(2, 1, 0), origin + direction * 12 + Vector3.new(-2, 5, 0), white, 0.22, 0.22)
    shards(origin + direction * 6, direction, cyan, 12, 10, 0.16, 0.32)
    cameraKick(3.8, 0.18)
end

local function naoya(origin, direction)
    for i = 1, 6 do
        local p = part(origin + direction * (i * 2.2), Vector3.new(0.08, 2.6, 2.6), Color3.fromRGB(196, 223, 255), Enum.Material.Neon, 0.35)
        p.CFrame = CFrame.lookAt(p.Position, p.Position + direction)
        local tween = TweenService:Create(p, TweenInfo.new(0.18), {Transparency = 1})
        tween:Play()
        cleanup(p, 0.18)
    end
    line(origin, direction, 18, 0.18, white, 0.18)
    cameraKick(2.6, 0.14)
end

local function kenjaku(origin, direction, move)
    local purple = palette.Kenjaku
    sphere(origin + direction * 3, 2.3, purple, 0.26)
    orbit(origin + direction * 3, 3.1, Color3.fromRGB(179, 154, 208), 7, 0.3)
    if move == "Technique Stock" then
        shards(origin + direction * 2, direction, Color3.fromRGB(227, 212, 242), 10, 7, 0.2, 0.3)
    else
        disc(origin + direction * 3, 4.5, 0.12, purple, 0.25, 13)
    end
end

local function jogo(origin, direction, move)
    local orange = palette.Jogo
    sphere(origin + direction * 4, 2.6, orange, 0.2)
    shards(origin + direction * 5, direction, Color3.fromRGB(255, 201, 119), 14, 10, 0.22, 0.34)
    if move == "Ember" then
        line(origin + direction * 4, direction, 16, 0.3, Color3.fromRGB(255, 155, 65), 0.24)
    else
        disc(origin, 4.5, 0.14, Color3.fromRGB(255, 89, 50), 0.28, 16)
    end
    cameraKick(3.8, 0.18)
end

local function dagon(origin, direction)
    local blue = palette.Dagon
    disc(origin, 4.2, 0.12, blue, 0.28, 16)
    for i = 1, 6 do
        local angle = i / 6 * math.pi * 2
        local start = origin + Vector3.new(math.cos(angle) * 2.4, 0.8, math.sin(angle) * 2.4)
        line(start, direction + Vector3.new(math.cos(angle) * 0.3, 0.35, math.sin(angle) * 0.3), 7, 0.23, Color3.fromRGB(132, 230, 255), 0.3)
    end
end

local function hanami(origin, direction)
    disc(origin, 4.8, 0.12, palette.Hanami, 0.28, 16)
    for i = 1, 8 do
        local angle = i / 8 * math.pi * 2
        local start = origin + Vector3.new(math.cos(angle), -0.15, math.sin(angle)) * 1.8
        local finish = start + Vector3.new(math.cos(angle), 1, math.sin(angle)) * 4
        beam(start, finish, Color3.fromRGB(152, 231, 133), 0.28, 0.34)
    end
end

local function higuruma(origin, direction)
    local silver = palette.Higuruma
    line(origin + direction * 2, direction, 10, 0.22, silver, 0.18)
    beam(origin + Vector3.new(-2, 3, 0), origin + Vector3.new(2, 3, 0), Color3.fromRGB(241, 215, 150), 0.55, 0.22)
    disc(origin, 4.2, 0.12, Color3.fromRGB(208, 208, 222), 0.25, 13)
    cameraKick(2.5, 0.14)
end

local function takaba(origin, direction)
    local yellow = palette.Takaba
    sphere(origin + direction * 3, 2.4, yellow, 0.23)
    for i = 1, 10 do
        local angle = i / 10 * math.pi * 2
        local offset = Vector3.new(math.cos(angle), math.sin(angle), math.sin(angle * 2)) * 3
        beam(origin + offset * 0.4, origin + offset * 1.8, white, 0.18, 0.22)
    end
    cameraKick(2.2, 0.13)
end

local function uraume(origin, direction)
    local ice = palette.Uraume
    shards(origin + direction * 3, direction, ice, 18, 10, 0.23, 0.36)
    disc(origin, 4, 0.13, Color3.fromRGB(201, 246, 255), 0.3, 15)
end

local function yorozu(origin, direction, move)
    local metal = palette.Yorozu
    sphere(origin + direction * 3, 2.6, metal, 0.25)
    orbit(origin + direction * 3, 3.8, Color3.fromRGB(255, 211, 246), 10, 0.3)
    if move == "Construction Armor" then
        disc(origin, 5.2, 0.16, metal, 0.3, 18)
        cameraKick(3.2, 0.17)
    end
end

local function ryu(origin, direction, move)
    local orange = palette.Ryu
    line(origin + direction * 2, direction, move == "Granite Shot" and 28 or 16, 0.65, orange, 0.3)
    sphere(origin + direction * 4, 2.8, Color3.fromRGB(255, 170, 110), 0.2)
    shards(origin + direction * 9, direction, white, 12, 12, 0.2, 0.34)
    cameraKick(4.6, 0.21)
end

local function uro(origin, direction)
    local sky = palette.Uro
    slash(origin + Vector3.new(0, 2, 0), direction, 16, 0.25, sky, -38, 0.22)
    slash(origin + Vector3.new(0, 2.5, 0), direction, 13, 0.18, white, 38, 0.22)
    beam(origin + Vector3.new(-4, 2, 0), origin + direction * 12 + Vector3.new(4, 4, 0), sky, 0.35, 0.23)
end

local function kusakabe(origin, direction)
    disc(origin, 5, 0.13, Color3.fromRGB(157, 171, 194), 0.24, 16)
    slash(origin, direction, 11, 0.22, Color3.fromRGB(232, 239, 248), -26, 0.18)
    slash(origin, direction, 10, 0.17, palette.Kusakabe, 26, 0.18)
    cameraKick(2.8, 0.15)
end

function VFX.CharacterMove(origin, data)
    if typeof(origin) ~= "Vector3" or type(data) ~= "table" then
        return
    end

    local character = data.character
    local move = data.move or "Technique"
    local power = tonumber(data.power) or 1
    local color = palette[character] or white
    local direction = targetDirection(origin, data)

    common(origin, color, power)

    if character == "Gojo" then
        gojo(origin, direction, move)
    elseif character == "Sukuna" then
        sukuna(origin, direction, move)
    elseif character == "Megumi" then
        megumi(origin, direction, move)
    elseif character == "Yuta" then
        yuta(origin, direction, move)
    elseif character == "Maki" or character == "Toji" then
        weaponUser(origin, direction, character)
    elseif character == "Mahito" then
        mahito(origin, direction, move)
    elseif character == "Todo" then
        todo(origin, direction)
    elseif character == "Hakari" then
        hakari(origin, direction, move)
    elseif character == "Choso" then
        choso(origin, direction)
    elseif character == "Kashimo" then
        kashimo(origin, direction)
    elseif character == "Naoya" then
        naoya(origin, direction)
    elseif character == "Kenjaku" then
        kenjaku(origin, direction, move)
    elseif character == "Jogo" then
        jogo(origin, direction, move)
    elseif character == "Dagon" then
        dagon(origin, direction)
    elseif character == "Hanami" then
        hanami(origin, direction)
    elseif character == "Higuruma" then
        higuruma(origin, direction)
    elseif character == "Takaba" then
        takaba(origin, direction)
    elseif character == "Uraume" then
        uraume(origin, direction)
    elseif character == "Yorozu" then
        yorozu(origin, direction, move)
    elseif character == "Ryu" then
        ryu(origin, direction, move)
    elseif character == "Uro" then
        uro(origin, direction)
    elseif character == "Kusakabe" then
        kusakabe(origin, direction)
    else
        slash(origin, direction, 10, 0.2, color, 25, 0.18)
        shards(origin, direction, color, 8, 7, 0.16, 0.22)
    end
end

function VFX.CharacterOneTime(origin, character, move)
    if typeof(origin) ~= "Vector3" then
        return
    end
    local color = palette[character] or white
    sphere(origin, 3.2, color, 0.32)
    disc(origin, 8, 0.18, color, 0.38, 24)
    shards(origin, Vector3.yAxis, white, 24, 14, 0.28, 0.42)
    cameraKick(7, 0.32)

    if character == "Gojo" or character == "Ryu" or character == "Sukuna" then
        line(origin + Vector3.new(0, 1.5, 0), Vector3.zAxis, 28, 0.8, color, 0.38)
    elseif character == "Jogo" then
        for i = 1, 4 do
            sphere(origin + Vector3.new((i - 2.5) * 2.4, i * 1.2, 0), 1.3, Color3.fromRGB(255, 104, 49), 0.32)
        end
    elseif character == "Uraume" then
        shards(origin, Vector3.yAxis, Color3.fromRGB(211, 249, 255), 30, 18, 0.32, 0.5)
    end
end

function VFX.Awakening(origin, character, name)
    if typeof(origin) ~= "Vector3" then
        return
    end

    local color = palette[character] or Color3.fromRGB(170, 140, 220)
    sphere(origin + Vector3.new(0, 1.5, 0), 2.8, color, 0.3)
    disc(origin, 6, 0.15, color, 0.38, 20)
    orbit(origin + Vector3.new(0, 1.5, 0), 4.5, white, 10, 0.42)
    shards(origin + Vector3.new(0, 1.5, 0), Vector3.yAxis, color, 18, 10, 0.24, 0.45)
    cameraKick(5, 0.28)
end

function VFX.Domain(origin, character, clash)
    if typeof(origin) ~= "Vector3" then
        return
    end
    local color = palette[character] or Color3.fromRGB(170, 140, 220)
    disc(origin, clash and 12 or 9, 0.2, color, 0.5, clash and 36 or 28)
    orbit(origin + Vector3.new(0, 1.5, 0), clash and 9 or 6, white, 10, 0.5)
    sphere(origin + Vector3.new(0, 2, 0), clash and 3.8 or 2.6, color, 0.42)
    cameraKick(clash and 6 or 4, clash and 0.3 or 0.24)
end

function VFX.Utility(kind, position, payload)
    if typeof(position) ~= "Vector3" then
        return
    end
    if kind == "Dash" then
        local direction = payload and payload.direction
        direction = typeof(direction) == "Vector3" and direction.Unit or Vector3.zAxis
        for i = 1, 5 do
            local offset = -direction * i * 1.5
            local ghost = part(position + offset, Vector3.new(2.2, 3.2, 1.2), Color3.fromRGB(195, 200, 218), Enum.Material.Neon, 0.76)
            ghost.CFrame = CFrame.lookAt(ghost.Position, ghost.Position + direction)
            local tween = TweenService:Create(ghost, TweenInfo.new(0.24), {Transparency = 1})
            tween:Play()
            cleanup(ghost, 0.24)
        end
    elseif kind == "MeleeSwing" then
        slash(position, payload and payload.direction or Vector3.zAxis, 7, 0.14, palette[payload and payload.character] or white, (payload and payload.combo or 1) % 2 == 0 and -25 or 25, 0.1)
    elseif kind == "Heavy" then
        disc(position, 3.8, 0.14, Color3.fromRGB(220, 220, 230), 0.18, 12)
        cameraKick(2.5, 0.13)
    elseif kind == "Grab" then
        shards(position, payload and payload.direction or Vector3.zAxis, white, 5, 4, 0.2, 0.17)
    elseif kind == "Block" then
        disc(position, 2.5, 0.12, Color3.fromRGB(96, 182, 255), 0.15, 5.5)
    end
end

return VFX
