local AnimalFactory = {}

function AnimalFactory.new(services)
    local Config = services.Config
    local createPart = services.CreatePart
    local addBall = services.AddBall

    local function createAnimalModel(spec, stageName, position, giant)
        local model = Instance.new("Model")
        model.Name = (giant and "Guardian_" or "Animal_") .. spec.Id
        model:SetAttribute("AnimalId", spec.Id)
        model:SetAttribute("Stage", stageName or "Baby")
        model:SetAttribute("GuardianType", spec.GuardianType or "")
        model:SetAttribute("IsGuardian", giant == true)
        local rarityRanks = {
            Comum = 1,
            Incomum = 2,
            Raro = 3,
            ["Épico"] = 4,
            ["Lendário"] = 5,
            ["Mítico"] = 6,
            ["Cósmico"] = 7,
            ["Secreto"] = 8,
            ["Eterno"] = 9,
            ["Divino"] = 10,
        }
        local rarityTier = rarityRanks[spec.Rarity] or 1
        model:SetAttribute("RarityTier", rarityTier)
        local stageIndex = 1
        for index, stage in ipairs(Config.EvolutionStages) do
            if stage.Name == (stageName or "Baby") then
                stageIndex = index
            end
        end
        local scale = giant and 5 or Config.EvolutionStages[stageIndex].Scale
        local base = position
        local function point(x, y, z)
            return base + Vector3.new(x * scale, y * scale, z * scale)
        end
        local function ball(name, sx, sy, sz, x, y, z, color, material)
            return addBall(model, name, Vector3.new(sx * scale, sy * scale, sz * scale), point(x, y, z), color or spec.Color, material)
        end
        local function block(name, sx, sy, sz, x, y, z, color, rotation, material)
            return createPart(model, name, Vector3.new(sx * scale, sy * scale, sz * scale), CFrame.new(point(x, y, z)) * (rotation or CFrame.new()), color or spec.Color, material or Enum.Material.SmoothPlastic, nil, false)
        end
        local function crystal(name, sx, sy, sz, x, y, z, color, rotation)
            local part = block(name, sx, sy, sz, x, y, z, color or spec.Accent, rotation, Enum.Material.Glass)
            part.Reflectance = 0.12
            part.CastShadow = false
            return part
        end
        local function glow(name, sx, sy, sz, x, y, z, color)
            local part = ball(name, sx, sy, sz, x, y, z, color or spec.Accent, Enum.Material.Neon)
            part.CastShadow = false
            part.Transparency = 0.08
            return part
        end
    
        local core = createPart(model, "ModelRoot", Vector3.new(0.25, 0.25, 0.25), CFrame.new(base), spec.Color, Enum.Material.SmoothPlastic, nil, false)
        core.Transparency = 1
        core.CastShadow = false
        model.PrimaryPart = core
    
        if spec.Shape == "Whale" or spec.Shape == "Dolphin" then
            ball("Body", 2.05, 1.28, 4.1, 0, 1.35, 0)
            ball("Chest", 1.62, 1.05, 1.5, 0, 1.25, -0.78, spec.Accent)
            ball("Head", 1.42, 1.12, 1.45, 0, 1.7, -1.45)
            ball("Muzzle", 1.02, 0.48, 1.18, 0, 1.38, -2.12, spec.Accent)
        elseif spec.Shape == "SkyWhale" then
            ball("Body", 2.25, 1.55, 4.35, 0, 1.55, 0)
            ball("Underbelly", 1.82, 0.62, 3.35, 0, 0.92, -0.12, spec.Accent)
            ball("Head", 1.58, 1.18, 1.42, 0, 1.72, -1.45)
            ball("Muzzle", 1.02, 0.46, 0.84, 0, 1.40, -2.12, spec.Accent)
        elseif spec.Shape == "Ray" then
            ball("Body", 1.55, 0.48, 2.5, 0, 1.08, 0)
            ball("Chest", 0.9, 0.32, 1.0, 0, 1.0, -0.72, spec.Accent)
            ball("Head", 0.95, 0.62, 0.9, 0, 1.25, -1.0)
            ball("Muzzle", 0.48, 0.22, 0.5, 0, 1.08, -1.46, spec.Accent)
        elseif spec.Shape == "Gecko" then
            ball("Body", 1.72, 0.88, 2.55, 0, 1.12, 0)
            ball("Chest", 1.25, 0.66, 1.02, 0, 1.05, -0.96, spec.Accent)
            ball("Head", 1.55, 0.86, 1.32, 0, 1.35, -1.52)
            ball("Muzzle", 1.03, 0.36, 0.68, 0, 1.08, -2.07, spec.Accent)
        elseif spec.Shape == "Beetle" then
            ball("Body", 1.72, 1.05, 2.25, 0, 1.05, 0)
            ball("Shell", 1.84, 0.92, 2.20, 0, 1.55, 0.12, spec.Accent)
            ball("Head", 0.92, 0.82, 0.90, 0, 1.25, -1.25)
            ball("Muzzle", 0.58, 0.34, 0.42, 0, 1.02, -1.70, spec.Color)
        elseif spec.Shape == "Bluejay" then
            ball("Body", 1.28, 1.58, 1.50, 0, 1.42, 0)
            ball("Chest", 1.02, 1.12, 0.65, 0, 1.30, -0.66, spec.Accent)
            ball("Head", 1.00, 1.00, 1.00, 0, 2.48, -0.90)
            ball("Muzzle", 0.46, 0.36, 0.68, 0, 2.25, -1.45, spec.Accent)
        else
            ball("Body", 1.65, 1.25, 2.0, 0, 1.25, 0)
            local chestColor = spec.Id == "Swan" and spec.Color or spec.Accent
            ball("Chest", 1.18, 1.15, 1.05, 0, 1.35, -0.62, chestColor)
            if spec.Id ~= "Swan" then
                ball("Head", 1.12, 1.08, 1.05, 0, 2.18, -1.05)
                ball("Muzzle", 0.68, 0.48, 0.52, 0, 1.96, -1.62, spec.Accent)
            end
        end
        local eyeX, eyeY, eyeZ = 0.29, 2.34, -1.57
        if spec.Shape == "Whale" or spec.Shape == "Dolphin" or spec.Shape == "SkyWhale" then
            eyeX, eyeY, eyeZ = 0.43, 1.85, -2.12
        elseif spec.Shape == "Ray" then
            eyeX, eyeY, eyeZ = 0.3, 1.28, -1.48
        elseif spec.Shape == "Gecko" then
            eyeX, eyeY, eyeZ = 0.58, 1.70, -1.78
        elseif spec.Shape == "Beetle" then
            eyeX, eyeY, eyeZ = 0.38, 1.57, -1.72
        elseif spec.Shape == "Bluejay" then
            eyeX, eyeY, eyeZ = 0.30, 2.62, -1.44
        elseif spec.Shape == "SkyWhale" then
            eyeX, eyeY, eyeZ = 0.50, 1.82, -2.18
        elseif spec.Id == "Swan" then
            eyeX, eyeY, eyeZ = 0.1, 3.48, -1.0
        elseif spec.Shape == "Frog" then
            eyeX, eyeY, eyeZ = 0.35, 2.67, -1.44
        end
        local eyeWidth = (spec.Shape == "Ray" or spec.Id == "Swan") and 0.2 or 0.27
        for _, side in ipairs({ -1, 1 }) do
            ball("EyeWhite", eyeWidth, 0.31, 0.13, side * eyeX, eyeY, eyeZ, Color3.fromRGB(255, 250, 231))
            ball("EyeIris", eyeWidth * 0.6, 0.2, 0.08, side * eyeX, eyeY - 0.01, eyeZ - 0.09, spec.Accent)
            ball("EyePupil", eyeWidth * 0.32, 0.13, 0.045, side * eyeX, eyeY - 0.01, eyeZ - 0.143, Color3.fromRGB(24, 27, 33))
            if giant then
                ball("EyeGlint", 0.045, 0.055, 0.025, side * eyeX - 0.03, eyeY + 0.05, eyeZ - 0.165, Color3.fromRGB(255, 255, 255))
                ball("Eyebrow", eyeWidth * 1.34, 0.11, 0.11, side * eyeX, eyeY + 0.24, eyeZ + 0.05, spec.Accent)
            end
            if stageName == "Baby" or giant then
                ball("CheekBlush", 0.25, 0.15, 0.06, side * math.max(eyeX + 0.24, 0.48), eyeY - 0.42, eyeZ + 0.01, Color3.fromRGB(255, 162, 174))
            end
        end
        local noseY, noseZ, mouthY, mouthZ = 2.02, -1.9, 1.85, -1.74
        if spec.Shape == "Whale" or spec.Shape == "Dolphin" or spec.Shape == "SkyWhale" then
            noseY, noseZ, mouthY, mouthZ = 1.42, -2.14, 1.16, -2.08
        elseif spec.Shape == "Ray" then
            noseY, noseZ, mouthY, mouthZ = 1.08, -1.46, 0.98, -1.43
        end
        if spec.Id ~= "Hen" and spec.Id ~= "Swan" and spec.Id ~= "Duckling" then
            ball("Nose", 0.19, 0.15, 0.13, 0, noseY, noseZ, spec.Shape == "Bird" and Color3.fromRGB(255, 145, 47) or Color3.fromRGB(57, 45, 43))
        end
        if spec.Shape ~= "Bird" then
            ball("Mouth", 0.2, 0.07, 0.06, 0, mouthY, mouthZ, Color3.fromRGB(83, 45, 48))
        end
        if giant then
            ball("ChestBadge", 0.34, 0.34, 0.16, 0, 1.24, -1.12, spec.Accent)
            ball("ChestBadgeCore", 0.14, 0.14, 0.08, 0, 1.25, -1.22, Color3.fromRGB(255, 241, 180))
        end
    
        if spec.Id == "Swan" then
            for _, side in ipairs({ -1, 1 }) do
                ball("SwanFoot", 0.4, 0.14, 0.55, side * 0.32, 0.16, -0.1, Color3.fromRGB(255, 141, 42))
            end
        else
            for _, side in ipairs({ -1, 1 }) do
                if spec.Shape ~= "Whale" and spec.Shape ~= "Dolphin" and spec.Shape ~= "Ray" and spec.Shape ~= "SkyWhale" and spec.Shape ~= "Gecko" and spec.Shape ~= "Beetle" and spec.Shape ~= "Bird" then
                    ball("Ear", 0.32, (spec.Shape == "Fox" or spec.Shape == "Wolf") and 0.75 or 0.55, 0.24, side * 0.38, 2.8, -0.88, spec.Color)
                    ball("LegFront", 0.35, 0.72, 0.38, side * 0.48, 0.48, -0.55, spec.Color)
                    ball("LegBack", 0.38, 0.68, 0.4, side * 0.48, 0.45, 0.62, spec.Color)
                end
            end
        end
    
        if spec.Shape == "Bird" or spec.Shape == "Bluejay" then
            for _, side in ipairs({ -1, 1 }) do
                ball("Wing", 0.42, 0.78, 1.0, side * 0.82, 1.52, 0.05, spec.Accent)
                if spec.Id ~= "Swan" and spec.Id ~= "Duckling" then
                    block("BirdLowerLeg", 0.14, 0.48, 0.14, side * 0.27, 0.32, -0.04, Color3.fromRGB(190, 123, 54))
                    block("BirdFoot", 0.24, 0.13, 0.40, side * 0.27, 0.12, -0.18, Color3.fromRGB(232, 145, 52))
                    for toe = 1, 3 do
                        block("BirdToe", 0.09, 0.09, 0.33, side * (0.27 + (toe - 2) * 0.12), 0.09, -0.43, Color3.fromRGB(231, 157, 62))
                    end
                end
            end
            ball("Crest", 0.18, 0.42, 0.18, 0, 2.9, -0.8, spec.Accent)
            if spec.Id == "Hen" then
                ball("HenComb", 0.3, 0.42, 0.23, 0, 2.96, -0.79, Color3.fromRGB(205, 54, 58))
                ball("HenCombPoint", 0.2, 0.29, 0.2, -0.18, 2.91, -0.79, Color3.fromRGB(205, 54, 58))
                ball("HenCombPoint", 0.2, 0.29, 0.2, 0.18, 2.91, -0.79, Color3.fromRGB(205, 54, 58))
                ball("HenWattle", 0.2, 0.32, 0.18, 0, 1.74, -1.55, Color3.fromRGB(205, 54, 58))
                ball("HenBeak", 0.35, 0.21, 0.4, 0, 2.03, -1.77, Color3.fromRGB(255, 157, 45))
            elseif spec.Id == "Swan" then
                ball("SwanNeck", 0.34, 1.15, 0.38, 0, 2.65, -0.98, Color3.fromRGB(250, 248, 238))
                ball("SwanNeckUpper", 0.29, 0.76, 0.3, 0, 3.15, -0.76, Color3.fromRGB(250, 248, 238))
                ball("SwanHead", 0.48, 0.42, 0.48, 0, 3.48, -0.75, Color3.fromRGB(250, 248, 238))
                ball("SwanBeak", 0.44, 0.18, 0.42, 0, 3.42, -1.1, Color3.fromRGB(255, 141, 42))
                ball("SwanMask", 0.16, 0.18, 0.1, 0, 3.48, -1.02, Color3.fromRGB(44, 49, 55))
                for _, side in ipairs({ -1, 1 }) do
                    ball("SwanWingFeather", 0.3, 0.65, 0.72, side * 1.0, 1.78, 0.22, Color3.fromRGB(255, 255, 250))
                    ball("SwanWingFeather", 0.28, 0.58, 0.68, side * 0.82, 1.6, 0.68, Color3.fromRGB(241, 239, 228))
                end
            elseif spec.Id == "Duckling" then
                ball("DucklingBill", 0.55, 0.24, 0.46, 0, 2.0, -1.72, Color3.fromRGB(255, 151, 36))
                ball("DucklingFoot", 0.38, 0.14, 0.45, -0.26, 0.15, -0.62, Color3.fromRGB(255, 151, 36))
                ball("DucklingFoot", 0.38, 0.14, 0.45, 0.26, 0.15, -0.62, Color3.fromRGB(255, 151, 36))
            end
        elseif spec.Shape == "Fox" or spec.Shape == "Wolf" or spec.Shape == "Lion" then
            ball("Tail", spec.Shape == "Fox" and 0.62 or 0.48, spec.Shape == "Fox" and 0.62 or 0.48, spec.Shape == "Fox" and 1.75 or 1.2, 0, 1.65, 1.2, spec.Accent)
            ball("TailTip", 0.42, 0.42, 0.48, 0, 1.68, 2.0, spec.Shape == "Fox" and Color3.fromRGB(255, 244, 220) or spec.Accent)
            ball("ShoulderPatch", 0.34, 0.35, 0.14, -0.62, 1.62, -0.46, spec.Accent)
            ball("ShoulderPatch", 0.34, 0.35, 0.14, 0.62, 1.62, -0.46, spec.Accent)
            if spec.Shape == "Lion" then
                ball("Mane", 1.42, 1.42, 1.2, 0, 2.12, -0.86, spec.Accent)
                ball("Head", 0.88, 0.85, 0.86, 0, 2.22, -1.24, spec.Color)
            end
        elseif spec.Shape == "Deer" or spec.Shape == "Mammoth" or spec.Shape == "Dragon" then
            for _, side in ipairs({ -1, 1 }) do
                local horn = block("Horn", 0.16, spec.Shape == "Mammoth" and 1.1 or 0.8, 0.16, side * 0.32, 3.0, -0.8, spec.Accent, CFrame.Angles(0, 0, math.rad(side * 12)))
                if spec.Shape == "Mammoth" then
                    ball("Tusks", 0.2, 0.9, 0.2, side * 0.36, 1.85, -1.62, spec.Accent)
                end
            end
            if spec.Shape == "Dragon" then
                for _, side in ipairs({ -1, 1 }) do
                    block("Wing", 0.15, 1.4, 1.4, side * 0.95, 1.9, 0.15, spec.Accent, CFrame.Angles(0, 0, math.rad(side * 35)))
                end
                ball("TailTip", 0.3, 0.3, 0.65, 0, 1.5, 1.85, spec.Accent)
            end
        elseif spec.Shape == "Turtle" then
            ball("Shell", 1.45, 0.82, 1.55, 0, 1.8, 0.1, spec.Accent)
        elseif spec.Shape == "Elephant" then
            block("Trunk", 0.32, 0.82, 0.34, 0, 1.58, -1.85, spec.Accent, CFrame.Angles(math.rad(18), 0, 0))
            for _, side in ipairs({ -1, 1 }) do
                ball("ElephantEar", 0.62, 0.8, 0.18, side * 0.67, 2.15, -0.92, spec.Accent)
            end
        elseif spec.Shape == "Bear" then
            for _, side in ipairs({ -1, 1 }) do
                ball("BearEarRound", 0.38, 0.38, 0.28, side * 0.42, 2.7, -0.84, spec.Color)
                ball("BearEarInner", 0.2, 0.2, 0.1, side * 0.42, 2.72, -0.99, spec.Accent)
                ball("BearPaw", 0.43, 0.3, 0.48, side * 0.52, 0.22, -0.58, spec.Accent)
            end
            ball("BearMuzzle", 0.65, 0.42, 0.52, 0, 1.99, -1.67, Color3.fromRGB(235, 223, 202))
            ball("BearNose", 0.22, 0.16, 0.16, 0, 2.05, -1.98, Color3.fromRGB(35, 35, 38))
        elseif spec.Shape == "Whale" then
            ball("WhaleDorsalFin", 0.18, 0.65, 0.75, 0, 2.05, 0.12, spec.Accent)
            ball("WhaleTailStock", 0.44, 0.42, 1.12, 0, 1.2, 2.18, spec.Accent)
            ball("WhaleTailFluke", 1.7, 0.2, 1.05, 0, 1.28, 2.93, spec.Accent)
            ball("WhaleFlipper", 0.32, 0.23, 1.4, -1.13, 0.91, -0.22, spec.Accent)
            ball("WhaleFlipper", 0.32, 0.23, 1.4, 1.13, 0.91, -0.22, spec.Accent)
            ball("WhaleBlowhole", 0.2, 0.08, 0.22, 0, 2.26, -1.05, Color3.fromRGB(61, 79, 93))
            ball("WhaleBelly", 1.45, 0.24, 2.15, 0, 0.82, -0.3, Color3.fromRGB(235, 238, 225))
        elseif spec.Shape == "Dolphin" then
            ball("DolphinDorsalFin", 0.16, 0.52, 0.72, 0, 2.04, 0.12, spec.Accent)
            ball("DolphinTailStock", 0.35, 0.3, 0.95, 0, 1.18, 2.22, spec.Accent)
            ball("DolphinTailFluke", 1.0, 0.18, 0.8, 0, 1.25, 2.88, spec.Accent)
            ball("DolphinFlipper", 0.23, 0.18, 1.05, -0.95, 0.9, -0.15, spec.Accent)
            ball("DolphinFlipper", 0.23, 0.18, 1.05, 0.95, 0.9, -0.15, spec.Accent)
        elseif spec.Shape == "Ray" then
            ball("MantaWing", 1.6, 0.18, 1.85, -1.6, 0.98, 0.18, spec.Accent)
            ball("MantaWing", 1.6, 0.18, 1.85, 1.6, 0.98, 0.18, spec.Accent)
            ball("MantaCephalicLobe", 0.42, 0.18, 0.62, -0.34, 1.08, -1.35, spec.Accent)
            ball("MantaCephalicLobe", 0.42, 0.18, 0.62, 0.34, 1.08, -1.35, spec.Accent)
        elseif spec.Shape == "Frog" then
            for _, side in ipairs({ -1, 1 }) do
                ball("EyeBulge", 0.32, 0.35, 0.32, side * 0.35, 2.65, -1.22, spec.Accent)
                ball("EyePupil", 0.12, 0.14, 0.1, side * 0.35, 2.67, -1.43, Color3.fromRGB(35, 45, 36))
            end
        elseif spec.Shape == "Hedgehog" then
            for index = 1, 7 do
                ball("Quill", 0.16, 0.55, 0.16, math.cos(index) * 0.48, 2.0, math.sin(index) * 0.48, spec.Accent)
            end
        elseif spec.Shape == "Reptile" then
            ball("Tail", 0.42, 0.4, 1.25, 0, 1.05, 1.25, spec.Accent)
            for index = 1, 3 do
                ball("BackSpine", 0.18, 0.24, 0.18, 0, 2.0, -0.1 + index * 0.36, spec.Accent)
            end
        end
    
        if spec.Id == "Bunny" then
            for _, side in ipairs({ -1, 1 }) do
                ball("BunnyEar", 0.24, 1.02, 0.2, side * 0.28, 3.12, -0.88, spec.Color)
                ball("BunnyEarInner", 0.11, 0.72, 0.08, side * 0.28, 3.14, -0.995, spec.Accent)
            end
            ball("BunnyCheek", 0.28, 0.22, 0.18, -0.22, 1.92, -1.7, Color3.fromRGB(255, 190, 195))
            ball("BunnyCheek", 0.28, 0.22, 0.18, 0.22, 1.92, -1.7, Color3.fromRGB(255, 190, 195))
        elseif spec.Id == "Lamb" then
            for row = 1, 3 do
                for column = -1, 1 do
                    ball("WoolCurl", 0.48, 0.45, 0.48, column * 0.42, 2.0 + (row % 2) * 0.16, 0.25 + row * 0.34, Color3.fromRGB(255, 250, 235))
                end
            end
            ball("WoolForelock", 0.56, 0.4, 0.38, 0, 2.85, -0.9, Color3.fromRGB(255, 250, 235))
        elseif spec.Id == "Meerkat" then
            ball("MeerkatChest", 0.78, 1.25, 0.4, 0, 1.35, -0.82, spec.Accent)
            for _, side in ipairs({ -1, 1 }) do
                ball("MeerkatEyePatch", 0.25, 0.28, 0.12, side * 0.29, 2.33, -1.58, Color3.fromRGB(83, 58, 42))
                ball("MeerkatStripe", 0.12, 0.65, 0.14, side * 0.3, 1.65, 0.55, Color3.fromRGB(117, 77, 46))
            end
        elseif spec.Id == "Otter" then
            ball("OtterTail", 0.42, 0.42, 1.7, 0, 1.0, 1.42, Color3.fromRGB(103, 70, 52))
            for _, side in ipairs({ -1, 1 }) do
                ball("OtterWhisker", 0.42, 0.045, 0.045, side * 0.42, 1.97, -1.83, spec.Accent)
                ball("OtterPaw", 0.38, 0.22, 0.38, side * 0.55, 0.36, -0.8, spec.Accent)
            end
        elseif spec.Id == "Penguin" then
            ball("PenguinBelly", 1.0, 1.15, 0.3, 0, 1.42, -0.88, Color3.fromRGB(250, 247, 233))
            for _, side in ipairs({ -1, 1 }) do
                ball("PenguinFlipper", 0.28, 0.78, 0.85, side * 0.95, 1.45, 0.02, spec.Color)
            end
        elseif spec.Id == "Owl" then
            for _, side in ipairs({ -1, 1 }) do
                ball("OwlBrow", 0.46, 0.16, 0.18, side * 0.3, 2.5, -1.48, spec.Accent)
                ball("OwlFaceDisk", 0.42, 0.46, 0.12, side * 0.28, 2.25, -1.48, Color3.fromRGB(239, 220, 184))
            end
        elseif spec.Id == "Fawn" then
            for row = 1, 2 do
                for column = -1, 1 do
                    ball("FawnSpot", 0.14, 0.14, 0.08, column * 0.35, 1.78, 0.25 + row * 0.38, Color3.fromRGB(255, 237, 196))
                end
            end
        elseif spec.Id == "Phoenix" then
            for feather = 1, 5 do
                ball("PhoenixTailFeather", 0.22, 0.26, 1.15, (feather - 3) * 0.2, 1.55, 1.45 + math.abs(feather - 3) * 0.12, feather % 2 == 0 and Color3.fromRGB(255, 209, 72) or Color3.fromRGB(255, 91, 42))
            end
            ball("PhoenixCrest", 0.2, 0.58, 0.22, 0, 3.05, -0.78, Color3.fromRGB(255, 219, 84))
        elseif spec.Id == "Crocodile" then
            for spine = 1, 5 do
                ball("CrocodileScute", 0.24, 0.3, 0.24, 0, 2.0, -0.25 + spine * 0.35, spec.Accent)
            end
            ball("CrocodileJaw", 0.78, 0.24, 0.64, 0, 1.78, -1.55, Color3.fromRGB(174, 193, 111))
        elseif spec.Id == "MantaRay" then
            for gill = 1, 3 do
                ball("MantaGill", 0.1, 0.16, 0.12, -0.28 + gill * 0.14, 0.98, -0.86, Color3.fromRGB(49, 70, 80))
                ball("MantaGill", 0.1, 0.16, 0.12, 0.28 - gill * 0.14, 0.98, -0.86, Color3.fromRGB(49, 70, 80))
            end
        end
    

        if spec.Id == "ShibaInu" then
            for _, side in ipairs({ -1, 1 }) do
                ball("ShibaEarTip", 0.28, 0.40, 0.23, side * 0.40, 3.03, -0.91, spec.Color)
                ball("ShibaEarInner", 0.12, 0.25, 0.08, side * 0.40, 2.98, -1.05, spec.Accent)
            end
            ball("ShibaCurledTail", 0.42, 0.48, 0.42, 0, 1.70, 1.32, spec.Color)
            ball("ShibaTailTip", 0.25, 0.27, 0.23, 0, 1.88, 1.56, spec.Accent)
            ball("ShibaCreamChest", 0.92, 0.78, 0.20, 0, 1.35, -0.91, spec.Accent)
        elseif spec.Id == "RedPanda" then
            for _, side in ipairs({ -1, 1 }) do
                ball("RedPandaEar", 0.42, 0.48, 0.25, side * 0.55, 2.83, -0.78, spec.Accent)
                ball("RedPandaEyeMask", 0.48, 0.38, 0.15, side * 0.34, 2.27, -1.64, Color3.fromRGB(54, 39, 34))
            end
            ball("RedPandaTail", 0.55, 0.55, 1.85, 0, 1.42, 1.42, spec.Color)
            for band = 1, 4 do
                ball("RedPandaTailRing", 0.56, 0.56, 0.17, 0, 1.42, 0.68 + band * 0.34, band % 2 == 0 and spec.Accent or Color3.fromRGB(64, 43, 35))
            end
        elseif spec.Id == "HouseCat" then
            for _, side in ipairs({ -1, 1 }) do
                block("CatEar", 0.48, 0.65, 0.24, side * 0.43, 2.91, -0.88, spec.Color, CFrame.Angles(0, 0, math.rad(side * 12)))
                ball("CatEarInner", 0.20, 0.36, 0.07, side * 0.43, 2.91, -1.03, spec.Accent)
                for whisker = 1, 3 do
                    ball("CatWhisker", 0.68, 0.035, 0.035, side * 0.70, 1.93 - whisker * 0.09, -1.93, spec.Accent)
                end
            end
            ball("CatTail", 0.22, 0.22, 1.55, 0, 1.33, 1.48, spec.Color)
            ball("CatTailTip", 0.23, 0.23, 0.25, 0, 1.33, 2.21, spec.Accent)
        elseif spec.Id == "Axolotl" then
            for _, side in ipairs({ -1, 1 }) do
                for gill = 1, 3 do
                    ball("AxolotlGillStem", 0.14, 0.16, 0.58, side * (0.57 + gill * 0.07), 2.16, -0.88 + gill * 0.12, spec.Accent)
                    ball("AxolotlGillTip", 0.19, 0.19, 0.20, side * (0.68 + gill * 0.07), 2.36 - gill * 0.15, -0.88 + gill * 0.12, spec.Color)
                end
            end
            ball("AxolotlTailFin", 0.52, 0.22, 1.15, 0, 1.34, 1.55, spec.Accent)
            ball("AxolotlBelly", 0.90, 0.75, 0.18, 0, 1.20, -0.88, Color3.fromRGB(255, 223, 222))
        elseif spec.Id == "Unicorn" then
            block("UnicornHorn", 0.20, 0.95, 0.20, 0, 3.03, -1.08, spec.Accent, CFrame.Angles(math.rad(18), 0, 0))
            for _, side in ipairs({ -1, 1 }) do
                ball("UnicornMane", 0.26, 0.48, 0.42, side * 0.43, 2.65, -0.70, Color3.fromRGB(183, 143, 237))
                ball("UnicornHoof", 0.40, 0.25, 0.42, side * 0.49, 0.22, -0.58, spec.Accent)
            end
            ball("UnicornTail", 0.34, 0.42, 1.18, 0, 1.56, 1.45, Color3.fromRGB(183, 143, 237))
            ball("UnicornStar", 0.24, 0.24, 0.12, 0, 1.36, -1.18, Color3.fromRGB(255, 235, 141))
        elseif spec.Id == "Koala" then
            for _, side in ipairs({ -1, 1 }) do
                ball("KoalaRoundEar", 0.76, 0.72, 0.34, side * 0.78, 2.55, -0.82, spec.Color)
                ball("KoalaInnerEar", 0.42, 0.40, 0.12, side * 0.78, 2.55, -1.03, spec.Accent)
            end
            ball("KoalaNose", 0.27, 0.39, 0.22, 0, 2.04, -1.90, Color3.fromRGB(36, 34, 35))
            ball("KoalaBelly", 0.90, 0.80, 0.18, 0, 1.19, -0.88, spec.Accent)
        elseif spec.Id == "Peacock" then
            for feather = 1, 7 do
                local offset = feather - 4
                ball("PeacockTailFeather", 0.20, 0.28, 1.42, offset * 0.28, 1.74, 1.52 + math.abs(offset) * 0.08, spec.Accent)
                ball("PeacockEyeSpot", 0.24, 0.24, 0.13, offset * 0.28, 2.02, 2.12 + math.abs(offset) * 0.08, feather % 2 == 0 and Color3.fromRGB(255, 205, 74) or Color3.fromRGB(81, 191, 174))
            end
            for _, side in ipairs({ -1, 1 }) do
                ball("PeacockWing", 0.32, 0.80, 0.95, side * 0.91, 1.50, 0.08, spec.Accent)
            end
        elseif spec.Id == "Capybara" then
            ball("CapybaraLongMuzzle", 0.86, 0.48, 0.75, 0, 1.75, -1.76, spec.Accent)
            for _, side in ipairs({ -1, 1 }) do
                ball("CapybaraSmallEar", 0.30, 0.25, 0.22, side * 0.53, 2.66, -0.83, spec.Color)
                ball("CapybaraNostril", 0.07, 0.07, 0.06, side * 0.20, 1.84, -2.13, Color3.fromRGB(49, 39, 33))
            end
        elseif spec.Id == "Panda" then
            for _, side in ipairs({ -1, 1 }) do
                ball("PandaRoundEar", 0.52, 0.52, 0.30, side * 0.58, 2.87, -0.84, spec.Accent)
                ball("PandaEyePatch", 0.48, 0.54, 0.15, side * 0.34, 2.27, -1.68, Color3.fromRGB(43, 40, 38))
                ball("PandaEye", 0.18, 0.18, 0.08, side * 0.34, 2.29, -1.79, Color3.fromRGB(250, 239, 219))
            end
            ball("PandaBelly", 0.92, 0.92, 0.17, 0, 1.26, -0.90, Color3.fromRGB(250, 246, 232))
        elseif spec.Id == "Raccoon" then
            for _, side in ipairs({ -1, 1 }) do
                ball("RaccoonEyeMask", 0.54, 0.36, 0.14, side * 0.34, 2.27, -1.68, spec.Accent)
                ball("RaccoonEar", 0.34, 0.35, 0.22, side * 0.52, 2.83, -0.84, spec.Color)
            end
            ball("RaccoonTail", 0.42, 0.42, 1.75, 0, 1.30, 1.48, spec.Color)
            for ring = 1, 4 do
                ball("RaccoonTailRing", 0.44, 0.44, 0.18, 0, 1.30, 0.68 + ring * 0.34, ring % 2 == 0 and spec.Accent or Color3.fromRGB(47, 45, 43))
            end
        elseif spec.Id == "Sloth" then
            for _, side in ipairs({ -1, 1 }) do
                ball("SlothLongArm", 0.28, 1.10, 0.32, side * 0.80, 1.38, -0.20, spec.Color)
                for claw = 1, 2 do
                    ball("SlothClaw", 0.09, 0.22, 0.10, side * (0.80 + claw * 0.10), 0.66, -0.30, spec.Accent)
                end
                ball("SlothEyeMask", 0.45, 0.32, 0.13, side * 0.28, 2.28, -1.67, spec.Accent)
            end
            ball("SlothCreamFace", 0.80, 0.56, 0.12, 0, 2.18, -1.69, Color3.fromRGB(224, 206, 171))
        elseif spec.Id == "Cheetah" then
            for spot = 1, 12 do
                local side = spot % 2 == 0 and 1 or -1
                local row = math.floor((spot - 1) / 2)
                ball("CheetahCoatSpot", 0.13, 0.13, 0.08, side * (0.36 + (row % 2) * 0.13), 1.15 + row * 0.22, 0.55 - row * 0.13, spec.Accent)
            end
            ball("CheetahTail", 0.20, 0.20, 1.45, 0, 1.20, 1.55, spec.Color)
            for ring = 1, 3 do
                ball("CheetahTailRing", 0.22, 0.22, 0.18, 0, 1.20, 1.05 + ring * 0.30, spec.Accent)
            end
        elseif spec.Id == "CrystalbackGecko" then
            ball("Gecko lower jaw", 1.05, 0.27, 0.62, 0, 0.94, -2.00, spec.Accent)
            ball("Gecko throat plate", 1.25, 0.42, 0.24, 0, 0.91, -1.42, Color3.fromRGB(168, 255, 204))
            for scaleRow = 1, 4 do
                for scaleCol = -2, 2 do
                    ball("Gecko raised scale", 0.18, 0.12, 0.13, scaleCol * 0.30, 1.48 + (scaleRow % 2) * 0.08, -0.30 + scaleRow * 0.38, scaleRow % 2 == 0 and spec.Accent or Color3.fromRGB(30, 126, 93))
                end
            end
            for spike = 1, 8 do
                block("Gecko crystal dorsal shard", 0.22, 0.48, 0.22, (spike % 2 == 0 and 0.08 or -0.08), 1.95, -0.85 + spike * 0.34, spec.Accent, CFrame.Angles(math.rad(-10), 0, math.rad((spike % 2 == 0 and 1 or -1) * 12)))
            end
            for _, side in ipairs({ -1, 1 }) do
                for toe = 1, 4 do
                    ball("Gecko toe", 0.17, 0.11, 0.26, side * (0.82 + toe * 0.035), 0.20, -0.80 + toe * 0.17, spec.Accent)
                    block("Gecko claw", 0.075, 0.07, 0.18, side * (0.85 + toe * 0.035), 0.16, -0.96 + toe * 0.17, Color3.fromRGB(232, 255, 234), CFrame.Angles(math.rad(-12), 0, 0))
                end
            end
            ball("Gecko tail base", 0.62, 0.52, 0.76, 0, 1.08, 1.30, spec.Color)
            ball("Gecko tail middle", 0.42, 0.35, 1.04, 0, 0.98, 2.05, spec.Color)
            ball("Gecko tail tip", 0.20, 0.20, 0.80, 0, 0.93, 2.82, spec.Accent)
        elseif spec.Id == "BloomforgedBeetle" then
            ball("Beetle armored elytra left", 0.92, 0.56, 1.60, -0.49, 1.76, 0.16, spec.Color)
            ball("Beetle armored elytra right", 0.92, 0.56, 1.60, 0.49, 1.76, 0.16, spec.Color)
            block("Beetle shell seam", 0.065, 0.10, 1.82, 0, 1.94, 0.15, spec.Accent)
            for _, side in ipairs({ -1, 1 }) do
                block("Beetle horn", 0.19, 0.85, 0.18, side * 0.28, 2.08, -1.56, spec.Accent, CFrame.Angles(math.rad(-18), 0, math.rad(side * 18)))
                for leg = 1, 3 do
                    block("Beetle segmented leg upper", 0.20, 0.56, 0.20, side * 0.82, 0.93, -0.72 + leg * 0.56, spec.Color, CFrame.Angles(0, 0, math.rad(side * 28)))
                    block("Beetle segmented leg lower", 0.14, 0.48, 0.14, side * 1.10, 0.52, -0.86 + leg * 0.56, spec.Accent, CFrame.Angles(0, 0, math.rad(-side * 24)))
                    ball("Beetle foot", 0.20, 0.12, 0.22, side * 1.15, 0.18, -0.92 + leg * 0.56, spec.Accent)
                end
                for petal = 1, 4 do
                    ball("Beetle petal", 0.16, 0.11, 0.35, side * (0.36 + petal * 0.11), 2.02, -0.14 + petal * 0.30, petal % 2 == 0 and Color3.fromRGB(85, 205, 255) or Color3.fromRGB(74, 231, 169))
                end
            end
            for gem = 1, 7 do
                ball("Beetle shell gem", 0.12, 0.10, 0.11, (gem % 2 == 0 and 1 or -1) * 0.54, 1.87, -0.64 + gem * 0.22, spec.Accent)
            end
        elseif spec.Id == "RunebillBluejay" then
            ball("Bluejay white throat bib", 0.76, 0.90, 0.24, 0, 1.52, -0.93, Color3.fromRGB(242, 249, 255))
            ball("Bluejay black cheek mask", 0.78, 0.38, 0.16, 0, 2.40, -1.22, Color3.fromRGB(21, 30, 54))
            block("Bluejay beak", 0.36, 0.28, 0.75, 0, 2.20, -1.78, Color3.fromRGB(24, 31, 48), CFrame.Angles(math.rad(8), 0, 0))
            for _, side in ipairs({ -1, 1 }) do
                for feather = 1, 5 do
                    ball("Bluejay layered wing feather", 0.19, 0.17, 0.78, side * (0.63 + feather * 0.085), 1.58 - feather * 0.12, -0.08 + feather * 0.12, feather % 2 == 0 and spec.Accent or Color3.fromRGB(26, 67, 195))
                end
                block("Bluejay leg", 0.12, 0.48, 0.12, side * 0.25, 0.38, 0.05, Color3.fromRGB(27, 31, 46))
                for claw = 1, 3 do
                    block("Bluejay talon", 0.07, 0.10, 0.25, side * (0.25 + (claw - 2) * 0.11), 0.14, -0.15, Color3.fromRGB(29, 34, 49), CFrame.Angles(math.rad(-12), 0, 0))
                end
            end
            for plume = 1, 5 do
                ball("Bluejay crystal crest plume", 0.14, 0.62, 0.22, (plume - 3) * 0.14, 3.00, -0.76, plume % 2 == 0 and spec.Accent or Color3.fromRGB(22, 53, 178))
            end
            for feather = 1, 6 do
                ball("Bluejay layered tail feather", 0.13, 0.16, 1.08, (feather - 3.5) * 0.15, 1.35, 1.13 + math.abs(feather - 3.5) * 0.08, feather % 2 == 0 and spec.Accent or Color3.fromRGB(17, 51, 166))
            end
        elseif spec.Id == "AstralJackalope" then
            ball("Jackalope broad chest ruff", 1.10, 0.85, 0.46, 0, 1.90, -1.13, spec.Accent)
            for _, side in ipairs({ -1, 1 }) do
                block("Jackalope upright ear", 0.28, 1.35, 0.20, side * 0.30, 3.30, -0.94, spec.Color, CFrame.Angles(math.rad(5), 0, math.rad(side * 9)))
                block("Jackalope inner ear", 0.12, 0.95, 0.07, side * 0.30, 3.32, -1.08, Color3.fromRGB(198, 142, 255))
                block("Jackalope antler stem", 0.13, 0.85, 0.13, side * 0.27, 3.14, -0.70, spec.Accent, CFrame.Angles(math.rad(15), 0, math.rad(-side * 12)))
                block("Jackalope antler branch", 0.11, 0.66, 0.11, side * 0.56, 3.45, -0.72, spec.Accent, CFrame.Angles(0, 0, math.rad(side * 52)))
                block("Jackalope antler tine", 0.10, 0.50, 0.10, side * 0.72, 3.70, -0.72, Color3.fromRGB(246, 210, 255), CFrame.Angles(0, 0, math.rad(-side * 12)))
                for starMark = 1, 3 do
                    ball("Jackalope constellation mark", 0.12, 0.12, 0.05, side * (0.35 + starMark * 0.16), 1.72 + starMark * 0.17, -0.85, Color3.fromRGB(232, 215, 255))
                end
            end
            for tail = 1, 7 do
                block("Jackalope astral tail plume", 0.22, 0.22, 1.05, (tail - 4) * 0.17, 1.72, 1.55 + math.abs(tail - 4) * 0.08, tail % 2 == 0 and spec.Accent or Color3.fromRGB(104, 75, 203), CFrame.Angles(math.rad((tail - 4) * 8), 0, math.rad((tail - 4) * 9)))
            end
            for _, side in ipairs({ -1, 1 }) do
                ball("Jackalope luminous hoof", 0.25, 0.19, 0.30, side * 0.48, 0.19, -0.55, spec.Accent)
            end
        elseif spec.Id == "SpiritwoodPanda" then
            for _, side in ipairs({ -1, 1 }) do
                ball("Spirit panda ear", 0.55, 0.55, 0.28, side * 0.58, 2.75, -0.86, Color3.fromRGB(26, 31, 38))
                ball("Spirit panda eye patch", 0.45, 0.48, 0.15, side * 0.35, 2.25, -1.64, Color3.fromRGB(23, 28, 35))
                ball("Spirit panda glowing eye", 0.14, 0.18, 0.08, side * 0.35, 2.28, -1.75, spec.Accent)
                ball("Spirit panda forepaw", 0.48, 0.30, 0.40, side * 0.62, 0.24, -0.60, Color3.fromRGB(45, 48, 48))
                block("Spirit panda lantern post", 0.11, 0.84, 0.11, side * 0.46, 2.33, 0.40, Color3.fromRGB(112, 74, 42))
                ball("Spirit panda lantern", 0.30, 0.38, 0.26, side * 0.46, 2.66, 0.40, Color3.fromRGB(247, 185, 61))
                ball("Spirit panda lantern light", 0.20, 0.24, 0.12, side * 0.46, 2.66, 0.24, Color3.fromRGB(182, 255, 102))
            end
            block("Spirit panda tree trunk", 0.23, 1.30, 0.23, 0, 2.20, 0.72, Color3.fromRGB(93, 58, 34), CFrame.Angles(math.rad(12), 0, 0))
            for branch = 1, 5 do
                block("Spirit panda tree branch", 0.12, 0.76, 0.12, (branch - 3) * 0.20, 2.75, 0.69, Color3.fromRGB(116, 74, 39), CFrame.Angles(0, 0, math.rad((branch - 3) * 24)))
                ball("Spirit panda leaf cluster", 0.31, 0.23, 0.27, (branch - 3) * 0.25, 3.15 + (branch % 2) * 0.10, 0.68, spec.Accent)
            end
            for leafMark = 1, 8 do
                ball("Spirit panda back leaf", 0.15, 0.23, 0.07, (leafMark - 4.5) * 0.22, 2.00 + (leafMark % 2) * 0.12, 0.70, Color3.fromRGB(89, 220, 112))
            end
        elseif spec.Id == "Novafox" then
            ball("Novafox chest mane", 1.05, 1.00, 0.42, 0, 1.85, -1.05, Color3.fromRGB(185, 194, 226))
            for _, side in ipairs({ -1, 1 }) do
                block("Novafox pointed ear", 0.30, 0.90, 0.24, side * 0.37, 3.00, -0.95, spec.Color, CFrame.Angles(0, 0, math.rad(side * 10)))
                for tuft = 1, 4 do
                    ball("Novafox cheek fur plate", 0.18, 0.26, 0.22, side * (0.48 + tuft * 0.05), 2.20 - tuft * 0.17, -1.35, tuft % 2 == 0 and spec.Accent or Color3.fromRGB(114, 121, 190))
                end
            end
            for tail = 1, 9 do
                local offset = tail - 5
                block("Novafox giant star tail", 0.36, 0.38, 1.45, offset * 0.15, 1.55, 1.75 + math.abs(offset) * 0.09, tail % 2 == 0 and spec.Accent or Color3.fromRGB(33, 79, 202), CFrame.Angles(math.rad(offset * 5), 0, math.rad(offset * 9)))
                ball("Novafox tail star", 0.13, 0.13, 0.08, offset * 0.15, 1.85, 2.18 + math.abs(offset) * 0.09, Color3.fromRGB(255, 225, 111))
            end
            for spot = 1, 8 do
                ball("Novafox shoulder constellation", 0.08, 0.08, 0.05, (spot % 2 == 0 and 1 or -1) * (0.48 + math.floor(spot / 2) * 0.05), 1.48 + (spot % 3) * 0.22, -0.32 + math.floor(spot / 3) * 0.22, Color3.fromRGB(107, 220, 255))
            end
        elseif spec.Id == "StarforgedSunlion" then
            ball("Sunlion broad muzzle", 0.92, 0.58, 0.54, 0, 2.02, -1.82, Color3.fromRGB(255, 211, 127))
            ball("Sunlion nose", 0.28, 0.19, 0.17, 0, 2.12, -2.10, Color3.fromRGB(32, 26, 39))
            for _, side in ipairs({ -1, 1 }) do
                ball("Sunlion eye glow", 0.19, 0.18, 0.09, side * 0.43, 2.47, -1.75, Color3.fromRGB(255, 210, 71))
                block("Sunlion royal brow", 0.78, 0.18, 0.18, side * 0.37, 2.78, -1.50, spec.Accent, CFrame.Angles(0, 0, math.rad(-side * 9)))
                for maneLayer = 1, 4 do
                    block("Sunlion faceted mane shard", 0.30, 0.62, 0.24, side * (0.62 + maneLayer * 0.08), 2.10 - maneLayer * 0.18, -1.18 + maneLayer * 0.18, maneLayer % 2 == 0 and spec.Color or Color3.fromRGB(167, 87, 255), CFrame.Angles(0, 0, math.rad(side * 28)))
                end
                for paw = 1, 3 do
                    block("Sunlion gold paw claw", 0.12, 0.13, 0.28, side * (0.46 + paw * 0.12), 0.22, -0.87, Color3.fromRGB(255, 220, 121), CFrame.Angles(math.rad(-13), 0, 0))
                end
            end
            for shard = 1, 13 do
                local offset = shard - 7
                block("Sunlion crown mane crystal", 0.25, 0.65, 0.23, offset * 0.13, 2.96 + math.abs(offset) * 0.035, -0.75 + math.abs(offset) * 0.05, shard % 2 == 0 and spec.Color or Color3.fromRGB(91, 48, 198), CFrame.Angles(math.rad(offset * 4), 0, math.rad(offset * 5)))
            end
            for starMark = 1, 10 do
                ball("Sunlion gold star marking", 0.10, 0.10, 0.07, ((starMark % 2 == 0) and 1 or -1) * (0.50 + (starMark % 3) * 0.12), 1.42 + (starMark % 4) * 0.22, 0.18 + math.floor(starMark / 4) * 0.22, Color3.fromRGB(255, 217, 100))
            end
        elseif spec.Id == "VerdantSkyWhale" then
            ball("Sky whale dorsal crown", 1.35, 0.42, 1.55, 0, 2.30, 0.15, Color3.fromRGB(61, 46, 134))
            block("Sky whale ancient tree trunk", 0.40, 1.35, 0.42, 0, 2.85, 0.25, Color3.fromRGB(113, 74, 39), CFrame.Angles(math.rad(8), 0, 0))
            for branch = 1, 6 do
                block("Sky whale tree branch", 0.17, 0.78, 0.16, (branch - 3.5) * 0.19, 3.35 + (branch % 2) * 0.10, 0.22, Color3.fromRGB(126, 82, 43), CFrame.Angles(0, 0, math.rad((branch - 3.5) * 22)))
                ball("Sky whale canopy leaf cluster", 0.36, 0.28, 0.35, (branch - 3.5) * 0.22, 3.84 + (branch % 3) * 0.12, 0.22, Color3.fromRGB(65, 180, 66))
            end
            for canopy = 1, 12 do
                local xOffset = math.cos(canopy * 2.4) * 0.70
                local yOffset = 3.85 + math.sin(canopy * 2.4) * 0.24
                ball("Sky whale bright canopy leaf", 0.20, 0.16, 0.22, xOffset, yOffset, 0.12, Color3.fromRGB(132, 231, 82))
            end
            for _, side in ipairs({ -1, 1 }) do
                block("Sky whale pectoral fin", 0.24, 0.18, 1.65, side * 1.55, 0.98, -0.12, spec.Color, CFrame.Angles(0, math.rad(side * 10), math.rad(side * 15)))
                for rune = 1, 4 do
                    ball("Sky whale golden rune", 0.10, 0.12, 0.05, side * (0.85 + rune * 0.19), 1.34, -0.70 + rune * 0.28, Color3.fromRGB(255, 213, 120))
                end
            end
            ball("Sky whale tail stem", 0.40, 0.38, 1.25, 0, 1.28, 2.15, spec.Color)
            for _, side in ipairs({ -1, 1 }) do
                block("Sky whale tail fluke", 0.78, 0.19, 0.90, side * 0.54, 1.36, 2.85, spec.Color, CFrame.Angles(0, math.rad(side * 18), 0))
                block("Sky whale gold filigree", 0.08, 0.08, 1.55, side * 0.98, 1.43, 0.10, Color3.fromRGB(255, 197, 78), CFrame.Angles(0, math.rad(side * 12), 0))
            end
        end

        if stageIndex >= 2 or giant then
            if spec.Id == "CrystalbackGecko" then
                for _, side in ipairs({ -1, 1 }) do
                    for ridge = 1, 4 do
                    glow("Gecko cheek light scale", 0.10, 0.09, 0.06, side * (0.62 + ridge * 0.07), 1.42 + ridge * 0.09, -1.71, Color3.fromRGB(117, 245, 255))
                end
                crystal("Gecko temple crystal", 0.20, 0.34, 0.16, side * 0.73, 1.88, -1.35, Color3.fromRGB(101, 239, 222), CFrame.Angles(0, 0, math.rad(side * 24)))
                for toe = 1, 4 do
                    glow("Gecko suction pad", 0.13, 0.06, 0.13, side * (0.82 + toe * 0.035), 0.22, -0.80 + toe * 0.17, Color3.fromRGB(120, 255, 189))
                end
            end
            for band = 1, 3 do
                ball("Gecko tail band", 0.47 - band * 0.06, 0.39 - band * 0.05, 0.13, 0, 1.00, 1.36 + band * 0.43, band % 2 == 0 and Color3.fromRGB(85, 227, 197) or Color3.fromRGB(18, 110, 89), Enum.Material.SmoothPlastic)
            end
            for crest = 1, 3 do
                crystal("Gecko crown crystal", 0.18, 0.42, 0.16, (crest - 2) * 0.23, 2.00, -1.48, Color3.fromRGB(135, 255, 244), CFrame.Angles(0, 0, math.rad((crest - 2) * 13)))
            end
        elseif spec.Id == "BloomforgedBeetle" then
            for _, side in ipairs({ -1, 1 }) do
                block("Beetle antenna stem", 0.09, 0.52, 0.09, side * 0.20, 2.42, -1.66, Color3.fromRGB(29, 32, 79), CFrame.Angles(math.rad(-12), 0, math.rad(side * 14)))
                glow("Beetle antenna tip", 0.16, 0.16, 0.16, side * 0.26, 2.68, -1.74, Color3.fromRGB(104, 239, 255))
                ball("Beetle mandible", 0.12, 0.19, 0.34, side * 0.18, 0.96, -1.83, Color3.fromRGB(21, 25, 77))
                for plate = 1, 4 do
                    ball("Beetle abdomen segment", 0.82 - plate * 0.08, 0.13, 0.36, 0, 0.86, 0.30 + plate * 0.34, plate % 2 == 0 and Color3.fromRGB(44, 72, 154) or Color3.fromRGB(34, 47, 119))
                end
                for ridge = 1, 3 do
                    crystal("Beetle elytra vein", 0.07, 0.08, 1.12, side * (0.28 + ridge * 0.12), 1.97, 0.16, Color3.fromRGB(112, 231, 255), CFrame.Angles(0, 0, math.rad(side * (ridge * 3))))
                end
            end
            for flower = 1, 6 do
                local angle = math.pi * 2 * flower / 6
                ball("Beetle dorsal flower petal", 0.22, 0.12, 0.42, math.cos(angle) * 0.42, 2.14, 0.24 + math.sin(angle) * 0.38, flower % 2 == 0 and Color3.fromRGB(104, 235, 255) or Color3.fromRGB(121, 255, 193))
            end
            glow("Beetle flower core", 0.23, 0.18, 0.23, 0, 2.18, 0.24, Color3.fromRGB(255, 226, 111))
        elseif spec.Id == "RunebillBluejay" then
            for _, side in ipairs({ -1, 1 }) do
                for row = 1, 3 do
                    for feather = 1, 4 do
                        ball("Bluejay covert feather", 0.15, 0.13, 0.62, side * (0.61 + feather * 0.12), 1.82 - row * 0.13, -0.02 + feather * 0.18, row % 2 == 0 and Color3.fromRGB(18, 51, 149) or Color3.fromRGB(75, 173, 255))
                    end
                end
                block("Bluejay lower mandible", 0.29, 0.12, 0.48, 0, 2.06, -1.86, Color3.fromRGB(255, 185, 71), CFrame.Angles(math.rad(-5), 0, 0))
                glow("Bluejay rune eye glint", 0.075, 0.075, 0.045, side * 0.34, 2.65, -1.53, Color3.fromRGB(130, 235, 255))
                for band = 1, 3 do
                    block("Bluejay wing rune stripe", 0.06, 0.07, 0.48, side * (0.75 + band * 0.11), 1.61 - band * 0.13, 0.02 + band * 0.17, Color3.fromRGB(153, 226, 255), CFrame.Angles(0, 0, math.rad(side * 12)), Enum.Material.Neon)
                end
            end
            for plume = 1, 3 do
                crystal("Bluejay crown rune", 0.12, 0.34, 0.12, (plume - 2) * 0.16, 3.36, -0.78, Color3.fromRGB(124, 235, 255))
            end
        elseif spec.Id == "AstralJackalope" then
            for _, side in ipairs({ -1, 1 }) do
                for tuft = 1, 4 do
                    ball("Jackalope layered cheek fur", 0.25, 0.22, 0.20, side * (0.48 + tuft * 0.08), 2.03 - tuft * 0.15, -1.23, tuft % 2 == 0 and Color3.fromRGB(213, 199, 255) or spec.Color)
                end
                crystal("Jackalope antler jewel", 0.16, 0.24, 0.14, side * 0.72, 3.78, -0.72, Color3.fromRGB(236, 208, 255))
                glow("Jackalope hoof rune", 0.16, 0.07, 0.20, side * 0.48, 0.28, -0.55, Color3.fromRGB(214, 158, 255))
            end
            for star = 1, 7 do
                local angle = math.pi * 2 * star / 7
                glow("Jackalope forehead star", 0.10, 0.10, 0.06, math.cos(angle) * 0.20, 2.73 + math.sin(angle) * 0.15, -1.45, Color3.fromRGB(238, 219, 255))
            end
            ball("Jackalope moon crest", 0.24, 0.30, 0.10, 0, 2.91, -1.46, Color3.fromRGB(255, 224, 154), Enum.Material.Neon)
        elseif spec.Id == "SpiritwoodPanda" then
            for _, side in ipairs({ -1, 1 }) do
                block("Spirit panda lantern frame", 0.40, 0.05, 0.05, side * 0.46, 2.87, 0.40, Color3.fromRGB(133, 83, 42))
                block("Spirit panda lantern cap", 0.38, 0.08, 0.34, side * 0.46, 2.90, 0.40, Color3.fromRGB(121, 72, 36))
                glow("Spirit panda lantern core", 0.15, 0.19, 0.12, side * 0.46, 2.66, 0.19, Color3.fromRGB(178, 255, 119))
                ball("Spirit panda paw pad", 0.20, 0.08, 0.08, side * 0.62, 0.25, -0.82, Color3.fromRGB(160, 225, 153))
                for leaf = 1, 5 do
                    local angle = math.pi * 2 * leaf / 5
                    ball("Spirit panda canopy leaf", 0.23, 0.15, 0.25, side * 0.46 + math.cos(angle) * 0.25, 3.24 + math.sin(angle) * 0.12, 0.68, Color3.fromRGB(98, 220, 114))
                end
            end
            for ring = 1, 3 do
                block("Spirit panda tree bark ring", 0.32, 0.05, 0.32, 0, 2.03 + ring * 0.28, 0.72, Color3.fromRGB(147, 96, 54))
            end
            for firefly = 1, 5 do
                glow("Spirit panda forest firefly", 0.07, 0.07, 0.07, (firefly - 3) * 0.52, 2.85 + (firefly % 2) * 0.32, 0.92, Color3.fromRGB(194, 255, 119))
            end
        elseif spec.Id == "Novafox" then
            for tail = 1, 9 do
                local offset = tail - 5
                local z = 1.75 + math.abs(offset) * 0.09
                ball("Novafox tail root tuft", 0.32, 0.38, 0.44, offset * 0.15, 1.53, 1.34, Color3.fromRGB(178, 188, 226))
                ball("Novafox tail luminous tip", 0.20, 0.24, 0.32, offset * 0.15, 1.56 + math.abs(offset) * 0.04, z + 0.72, Color3.fromRGB(180, 244, 255), Enum.Material.Neon)
                glow("Novafox tail star", 0.09, 0.09, 0.07, offset * 0.15, 1.88, z + 0.38, Color3.fromRGB(255, 231, 135))
            end
            for _, side in ipairs({ -1, 1 }) do
                ball("Novafox ear inner glow", 0.10, 0.49, 0.07, side * 0.37, 3.01, -1.08, Color3.fromRGB(103, 218, 255), Enum.Material.Neon)
                for whisker = 1, 3 do
                    block("Novafox whisker", 0.42, 0.035, 0.025, side * (0.68 + whisker * 0.08), 1.92 - whisker * 0.10, -1.69, Color3.fromRGB(189, 225, 255))
                end
            end
            for collar = 1, 5 do
                local angle = math.pi * 2 * collar / 5
                glow("Novafox chest constellation", 0.10, 0.10, 0.06, math.cos(angle) * 0.37, 1.93 + math.sin(angle) * 0.28, -1.30, Color3.fromRGB(255, 224, 125))
            end
        elseif spec.Id == "StarforgedSunlion" then
            for mane = 1, 16 do
                local angle = math.pi * 2 * mane / 16
                local x = math.cos(angle) * 1.08
                local y = 2.27 + math.sin(angle) * 0.95
                local z = -0.88 + math.sin(angle) * 0.20
                crystal("Sunlion radial mane plate", 0.28, 0.54, 0.20, x, y, z, mane % 2 == 0 and Color3.fromRGB(191, 130, 255) or Color3.fromRGB(255, 198, 74), CFrame.Angles(0, 0, math.rad(mane * 22)))
            end
            for _, side in ipairs({ -1, 1 }) do
                for whisker = 1, 3 do
                    block("Sunlion whisker", 0.44, 0.035, 0.025, side * (0.64 + whisker * 0.08), 1.97 - whisker * 0.12, -1.86, Color3.fromRGB(255, 235, 187))
                end
                for shoulder = 1, 3 do
                    crystal("Sunlion shoulder armor", 0.22, 0.42, 0.22, side * (0.70 + shoulder * 0.10), 1.55 - shoulder * 0.18, -0.38, Color3.fromRGB(184, 119, 255))
                end
            end
            for gem = 1, 5 do
                glow("Sunlion crown star gem", 0.10, 0.10, 0.08, (gem - 3) * 0.23, 3.34, -0.80, Color3.fromRGB(255, 221, 126))
            end
        elseif spec.Id == "VerdantSkyWhale" then
            for _, side in ipairs({ -1, 1 }) do
                for gill = 1, 5 do
                    block("Sky whale gill engraving", 0.06, 0.20, 0.50, side * 1.05, 1.48 - gill * 0.16, -0.77, Color3.fromRGB(100, 206, 233), CFrame.Angles(0, 0, math.rad(side * 16)), Enum.Material.Neon)
                end
                for finRidge = 1, 4 do
                    block("Sky whale fin ridge", 0.05, 0.06, 0.88, side * (1.55 + finRidge * 0.05), 1.00, -0.12 + finRidge * 0.12, Color3.fromRGB(135, 206, 255))
                end
            end
            for bellyRidge = 1, 5 do
                ball("Sky whale belly plate", 1.28, 0.08, 0.40, 0, 0.70, -0.90 + bellyRidge * 0.48, Color3.fromRGB(168, 148, 226))
            end
            for rune = 1, 9 do
                local angle = math.pi * 2 * rune / 9
                glow("Sky whale orbit rune", 0.10, 0.10, 0.08, math.cos(angle) * 1.22, 2.10, math.sin(angle) * 1.25, Color3.fromRGB(111, 226, 255))
            end
        elseif spec.Id == "Chick" then
            ball("Chick fluffy forehead", 0.48, 0.34, 0.36, 0, 2.98, -0.86, Color3.fromRGB(255, 242, 184))
            ball("Chick belly fluff", 0.88, 0.78, 0.18, 0, 1.35, -0.89, Color3.fromRGB(255, 245, 204))
            for feather = 1, 5 do
                ball("Chick tail down feather", 0.16, 0.20, 0.54, (feather - 3) * 0.17, 1.55, 0.98 + math.abs(feather - 3) * 0.08, Color3.fromRGB(255, 194, 72))
            end
            for _, side in ipairs({ -1, 1 }) do
                ball("Chick wing tip", 0.25, 0.34, 0.40, side * 0.88, 1.40, 0.13, Color3.fromRGB(255, 190, 65))
                ball("Chick toe", 0.10, 0.08, 0.28, side * 0.28, 0.13, -0.40, Color3.fromRGB(238, 142, 41))
            end
        elseif spec.Id == "Fox" then
            ball("Fox cream throat ruff", 0.95, 0.83, 0.34, 0, 1.83, -1.08, Color3.fromRGB(255, 236, 207))
            ball("Fox muzzle bridge", 0.38, 0.34, 0.62, 0, 1.92, -1.74, Color3.fromRGB(255, 224, 190))
            for _, side in ipairs({ -1, 1 }) do
                block("Fox inner ear", 0.12, 0.48, 0.06, side * 0.38, 2.94, -1.02, Color3.fromRGB(255, 181, 158), CFrame.Angles(0, 0, math.rad(side * 10)))
                ball("Fox cheek fur tuft", 0.34, 0.30, 0.22, side * 0.72, 1.92, -1.14, Color3.fromRGB(255, 231, 200))
                block("Fox foreleg sock", 0.23, 0.32, 0.30, side * 0.48, 0.25, -0.70, Color3.fromRGB(255, 232, 201))
                ball("Fox paw pad", 0.25, 0.10, 0.24, side * 0.48, 0.13, -0.70, Color3.fromRGB(75, 54, 49))
            end
            for tuft = 1, 5 do
                ball("Fox tail underside tuft", 0.22, 0.22, 0.44, (tuft - 3) * 0.14, 1.40, 1.55 + math.abs(tuft - 3) * 0.10, Color3.fromRGB(255, 236, 211))
            end
        elseif spec.Id == "Hedgehog" then
            ball("Hedgehog dark nose", 0.16, 0.14, 0.14, 0, 1.90, -1.92, Color3.fromRGB(39, 31, 29))
            ball("Hedgehog cream face mask", 0.80, 0.60, 0.14, 0, 2.12, -1.52, Color3.fromRGB(245, 222, 184))
            for row = 1, 3 do
                for quill = 1, 7 do
                    local offset = quill - 4
                    block("Hedgehog layered quill", 0.12, 0.56, 0.12, offset * 0.20, 1.92 + (row % 2) * 0.18, 0.02 + row * 0.35, row % 2 == 0 and Color3.fromRGB(93, 56, 37) or Color3.fromRGB(224, 191, 147), CFrame.Angles(0, 0, math.rad(offset * 13)))
                end
            end
            for _, side in ipairs({ -1, 1 }) do
                ball("Hedgehog ear inner", 0.16, 0.20, 0.07, side * 0.49, 2.67, -1.02, Color3.fromRGB(231, 155, 149))
            end
        elseif spec.Id == "Wolf" then
            ball("Wolf silver throat ruff", 1.02, 0.90, 0.34, 0, 1.86, -1.04, Color3.fromRGB(220, 228, 236))
            ball("Wolf forehead blaze", 0.28, 0.72, 0.12, 0, 2.45, -1.62, Color3.fromRGB(218, 226, 237))
            for _, side in ipairs({ -1, 1 }) do
                block("Wolf ear inner", 0.12, 0.46, 0.07, side * 0.40, 2.98, -0.98, Color3.fromRGB(94, 105, 120), CFrame.Angles(0, 0, math.rad(side * 9)))
                ball("Wolf cheek mane tuft", 0.30, 0.44, 0.25, side * 0.78, 2.05, -0.90, Color3.fromRGB(163, 177, 190))
                for claw = 1, 3 do
                    block("Wolf paw claw", 0.08, 0.08, 0.20, side * (0.38 + claw * 0.10), 0.20, -0.86, Color3.fromRGB(40, 43, 48), CFrame.Angles(math.rad(-14), 0, 0))
                end
            end
            for stripe = 1, 4 do
                ball("Wolf tail fur band", 0.42, 0.42, 0.13, 0, 1.64, 1.02 + stripe * 0.25, stripe % 2 == 0 and Color3.fromRGB(216, 225, 235) or Color3.fromRGB(91, 103, 119))
            end
        elseif spec.Id == "Frog" then
            ball("Frog throat pouch", 0.72, 0.42, 0.24, 0, 0.91, -0.96, Color3.fromRGB(183, 239, 142))
            for _, side in ipairs({ -1, 1 }) do
                for toe = 1, 4 do
                    ball("Frog toe pad", 0.20, 0.10, 0.20, side * (0.72 + toe * 0.05), 0.16, -0.72 + toe * 0.18, Color3.fromRGB(250, 223, 111))
                end
                for spot = 1, 5 do
                    ball("Frog dorsal spot", 0.12, 0.08, 0.08, side * (0.35 + (spot % 2) * 0.14), 1.78 + (spot % 3) * 0.12, -0.15 + spot * 0.25, Color3.fromRGB(51, 143, 80))
                end
            end
            for ridge = 1, 5 do
                ball("Frog back ridge", 0.10, 0.16, 0.18, 0, 1.94, -0.48 + ridge * 0.30, Color3.fromRGB(124, 220, 128))
            end
        elseif spec.Id == "Turtle" then
            ball("Turtle plastron", 1.34, 0.22, 1.45, 0, 1.18, 0.08, Color3.fromRGB(224, 193, 127))
            for plate = 1, 7 do
                local x = ((plate - 1) % 3 - 1) * 0.42
                local z = math.floor((plate - 1) / 3) * 0.48 - 0.42
                crystal("Turtle shell scute", 0.42, 0.12, 0.48, x, 2.13, z, plate % 2 == 0 and Color3.fromRGB(202, 164, 94) or Color3.fromRGB(127, 105, 66))
            end
            for _, side in ipairs({ -1, 1 }) do
                for claw = 1, 3 do
                    block("Turtle foot claw", 0.10, 0.08, 0.18, side * (0.78 + claw * 0.06), 0.20, -0.48 + claw * 0.18, Color3.fromRGB(226, 211, 163))
                end
            end
            ball("Turtle nose highlight", 0.10, 0.08, 0.07, 0, 1.94, -1.93, Color3.fromRGB(218, 255, 197))
        elseif spec.Id == "ArcticFox" then
            ball("Arctic fox snow ruff", 1.05, 0.92, 0.38, 0, 1.86, -1.03, Color3.fromRGB(255, 255, 255))
            for _, side in ipairs({ -1, 1 }) do
                crystal("Arctic fox ear crystal", 0.13, 0.34, 0.12, side * 0.36, 3.20, -0.88, Color3.fromRGB(152, 220, 255))
                ball("Arctic fox cheek frost", 0.32, 0.28, 0.18, side * 0.66, 2.00, -1.22, Color3.fromRGB(210, 237, 255))
            end
            for band = 1, 4 do
                ball("Arctic fox tail frost band", 0.49, 0.48, 0.13, 0, 1.62, 0.94 + band * 0.23, band % 2 == 0 and Color3.fromRGB(203, 234, 255) or Color3.fromRGB(255, 255, 255))
            end
            for snow = 1, 6 do
                glow("Arctic fox frost mote", 0.07, 0.07, 0.07, (snow - 3.5) * 0.34, 2.25 + (snow % 2) * 0.16, 0.30, Color3.fromRGB(181, 231, 255))
            end
        elseif spec.Id == "Mammoth" then
            ball("Mammoth forehead cap", 0.92, 0.52, 0.34, 0, 2.32, -1.36, Color3.fromRGB(156, 170, 186))
            for _, side in ipairs({ -1, 1 }) do
                ball("Mammoth ear inner", 0.40, 0.40, 0.12, side * 0.78, 2.12, -0.92, Color3.fromRGB(205, 161, 148))
                for ring = 1, 4 do
                    ball("Mammoth tusk ring", 0.19, 0.12, 0.13, side * 0.36, 1.72 + ring * 0.16, -1.75, Color3.fromRGB(255, 238, 203))
                end
                crystal("Mammoth tusk tip", 0.15, 0.26, 0.15, side * 0.36, 2.32, -1.72, Color3.fromRGB(255, 244, 219))
            end
            for tuft = 1, 7 do
                ball("Mammoth wool tuft", 0.30, 0.24, 0.30, (tuft - 4) * 0.30, 2.16, 0.46, Color3.fromRGB(174, 185, 196))
            end
        elseif spec.Id == "PolarBear" then
            ball("Polar bear neck ruff", 1.18, 0.94, 0.38, 0, 1.86, -1.00, Color3.fromRGB(255, 255, 250))
            for _, side in ipairs({ -1, 1 }) do
                ball("Polar bear ear inner", 0.18, 0.18, 0.08, side * 0.42, 2.72, -1.00, Color3.fromRGB(235, 170, 177))
                for claw = 1, 4 do
                    block("Polar bear dark claw", 0.09, 0.08, 0.19, side * (0.34 + claw * 0.11), 0.19, -0.78, Color3.fromRGB(68, 73, 81), CFrame.Angles(math.rad(-10), 0, 0))
                end
            end
            for snow = 1, 6 do
                glow("Polar bear snowflake marking", 0.09, 0.09, 0.06, math.cos(snow * math.pi / 3) * 0.50, 1.50 + math.sin(snow * math.pi / 3) * 0.30, 0.62, Color3.fromRGB(184, 228, 255))
            end
        elseif spec.Id == "LionCub" then
            ball("Lion cub baby mane", 1.34, 1.25, 0.80, 0, 2.08, -0.90, Color3.fromRGB(255, 190, 88))
            for tuft = 1, 10 do
                local angle = math.pi * 2 * tuft / 10
                block("Lion cub mane tuft", 0.22, 0.42, 0.20, math.cos(angle) * 0.74, 2.12 + math.sin(angle) * 0.68, -0.90, Color3.fromRGB(245, 157, 67), CFrame.Angles(0, 0, math.rad(tuft * 18)))
            end
            for _, side in ipairs({ -1, 1 }) do
                ball("Lion cub cheek", 0.30, 0.26, 0.18, side * 0.62, 1.98, -1.58, Color3.fromRGB(255, 225, 178))
                ball("Lion cub paw pad", 0.23, 0.08, 0.12, side * 0.50, 0.18, -0.80, Color3.fromRGB(120, 79, 52))
            end
        elseif spec.Id == "Elephant" then
            ball("Elephant forehead plate", 0.86, 0.60, 0.22, 0, 2.33, -1.45, Color3.fromRGB(168, 177, 187))
            for _, side in ipairs({ -1, 1 }) do
                ball("Elephant inner ear", 0.44, 0.58, 0.09, side * 0.68, 2.15, -1.06, Color3.fromRGB(205, 158, 153))
                for ring = 1, 4 do
                    ball("Elephant trunk ring", 0.28 - ring * 0.025, 0.09, 0.10, 0, 1.58 - ring * 0.15, -1.88 - ring * 0.045, Color3.fromRGB(185, 191, 198))
                end
                crystal("Elephant tusk sheen", 0.12, 0.28, 0.12, side * 0.38, 1.76, -1.74, Color3.fromRGB(255, 241, 210))
                for toe = 1, 3 do
                    ball("Elephant toenail", 0.14, 0.10, 0.12, side * (0.28 + toe * 0.12), 0.18, -0.63, Color3.fromRGB(222, 216, 205))
                end
            end
        elseif spec.Id == "LionGuardian" then
            for mane = 1, 20 do
                local angle = math.pi * 2 * mane / 20
                local x = math.cos(angle) * 1.18
                local y = 2.22 + math.sin(angle) * 1.00
                crystal("Lion guardian mane armor", 0.28, 0.62, 0.24, x, y, -0.91, mane % 2 == 0 and Color3.fromRGB(255, 209, 94) or Color3.fromRGB(151, 82, 45), CFrame.Angles(0, 0, math.rad(mane * 18)))
            end
            for _, side in ipairs({ -1, 1 }) do
                ball("Lion guardian cheek fur", 0.44, 0.48, 0.22, side * 0.75, 1.96, -1.48, Color3.fromRGB(248, 205, 127))
                glow("Lion guardian eye flame", 0.13, 0.13, 0.08, side * 0.42, 2.43, -1.80, Color3.fromRGB(255, 214, 89))
                for claw = 1, 4 do
                    crystal("Lion guardian claw", 0.10, 0.12, 0.26, side * (0.35 + claw * 0.12), 0.21, -0.84, Color3.fromRGB(255, 224, 143))
                end
            end
        elseif spec.Id == "Salamander" then
            ball("Salamander throat plate", 0.92, 0.54, 0.22, 0, 1.08, -1.04, Color3.fromRGB(255, 185, 105))
            for _, side in ipairs({ -1, 1 }) do
                for gill = 1, 4 do
                    block("Salamander external gill", 0.10, 0.12, 0.48, side * (0.66 + gill * 0.08), 1.72 - gill * 0.08, -0.78, gill % 2 == 0 and Color3.fromRGB(255, 194, 89) or spec.Accent, CFrame.Angles(0, 0, math.rad(side * 18)))
                end
                for spot = 1, 5 do
                    glow("Salamander ember spot", 0.09, 0.08, 0.06, side * (0.38 + spot * 0.10), 1.45 + (spot % 2) * 0.18, -0.10 + spot * 0.24, Color3.fromRGB(255, 196, 77))
                end
            end
            for ridge = 1, 6 do
                crystal("Salamander dorsal ember ridge", 0.13, 0.26, 0.13, 0, 1.94, -0.65 + ridge * 0.30, Color3.fromRGB(255, 170, 72))
            end
        elseif spec.Id == "Dragon" then
            for _, side in ipairs({ -1, 1 }) do
                block("Dragon wing spar", 0.12, 1.20, 1.55, side * 1.08, 2.00, 0.20, Color3.fromRGB(75, 46, 112), CFrame.Angles(0, 0, math.rad(side * 22)))
                for rib = 1, 4 do
                    block("Dragon wing rib", 0.06, 0.10, 1.20, side * (0.56 + rib * 0.16), 1.80 + rib * 0.08, 0.22 + rib * 0.08, spec.Accent, CFrame.Angles(0, 0, math.rad(side * 18)))
                end
                for claw = 1, 3 do
                    crystal("Dragon foreclaw", 0.10, 0.12, 0.24, side * (0.68 + claw * 0.12), 0.23, -0.76, Color3.fromRGB(245, 218, 167))
                end
            end
            for plate = 1, 7 do
                ball("Dragon armored belly plate", 0.72 - plate * 0.035, 0.14, 0.26, 0, 1.26, -1.20 + plate * 0.34, Color3.fromRGB(241, 174, 136))
                crystal("Dragon dorsal spine", 0.18, 0.42, 0.16, 0, 2.08, -0.85 + plate * 0.42, Color3.fromRGB(255, 137, 112))
            end
            for horn = 1, 2 do
                crystal("Dragon crown horn", 0.16, 0.52, 0.16, (horn == 1 and -1 or 1) * 0.35, 3.00, -0.88, Color3.fromRGB(255, 196, 143))
            end
        elseif spec.Id == "Dolphin" then
            ball("Dolphin rostrum bridge", 0.70, 0.34, 0.74, 0, 1.47, -2.05, Color3.fromRGB(183, 225, 238))
            for _, side in ipairs({ -1, 1 }) do
                block("Dolphin flank stripe", 0.06, 0.10, 2.00, side * 0.97, 1.38, 0.18, Color3.fromRGB(39, 128, 177), CFrame.Angles(0, 0, math.rad(side * 4)))
                for ridge = 1, 3 do
                    block("Dolphin flipper ridge", 0.05, 0.06, 0.62, side * (0.88 + ridge * 0.08), 0.97, -0.30 + ridge * 0.18, Color3.fromRGB(163, 224, 244))
                end
            end
            ball("Dolphin blowhole", 0.14, 0.06, 0.12, 0, 2.35, -1.03, Color3.fromRGB(43, 86, 110))
            for spot = 1, 8 do
                glow("Dolphin water-speckle", 0.06, 0.06, 0.05, (spot % 2 == 0 and 1 or -1) * (0.44 + (spot % 3) * 0.16), 1.72 + (spot % 4) * 0.12, -0.30 + math.floor(spot / 2) * 0.23, Color3.fromRGB(177, 239, 255))
            end
        elseif spec.Id == "Whale" then
            for _, side in ipairs({ -1, 1 }) do
                for groove = 1, 5 do
                    block("Whale throat groove", 0.06, 0.38, 0.16, side * (0.30 + groove * 0.10), 1.14, -1.64 + groove * 0.18, Color3.fromRGB(213, 235, 240))
                end
                for barnacle = 1, 3 do
                    ball("Whale skin marking", 0.10, 0.08, 0.08, side * (0.82 + barnacle * 0.10), 1.90, -0.20 + barnacle * 0.42, Color3.fromRGB(180, 218, 237))
                end
                block("Whale flipper ridge", 0.07, 0.10, 0.90, side * 1.18, 0.94, -0.10, Color3.fromRGB(134, 187, 217))
            end
            ball("Whale blowhole", 0.18, 0.07, 0.16, 0, 2.34, -1.00, Color3.fromRGB(42, 65, 81))
            for tailLine = 1, 3 do
                ball("Whale tail fluke ridge", 0.08, 0.08, 0.72, (tailLine - 2) * 0.42, 1.37, 2.92, Color3.fromRGB(179, 221, 237))
            end
            end
        end

        if giant and spec.GuardianType == "Chicken" then
            for featherIndex = 1, 7 do
                local featherX = (featherIndex - 4) * 0.29
                ball("GuardianHenTailFeather", 0.34, 0.65, 1.1, featherX, 1.62, 1.55 + math.abs(featherIndex - 4) * 0.08, featherIndex % 2 == 0 and spec.Accent or spec.Color)
                ball("GuardianHenWingPlate", 0.20, 0.42, 0.92, featherX * 2.1, 1.52, 0.72, spec.Accent)
            end
            ball("GuardianHenChestShield", 1.10, 0.72, 0.20, 0, 1.35, -1.23, Color3.fromRGB(255, 231, 174))
            for crestIndex = 1, 3 do
                crystal("GuardianHenCrest", 0.20, 0.54, 0.18, (crestIndex - 2) * 0.24, 3.18, -0.72, Color3.fromRGB(227, 69, 48))
            end
        elseif giant and spec.GuardianType == "Swan" then
            for featherIndex = 1, 9 do
                local side = featherIndex % 2 == 0 and -1 or 1
                local row = math.floor((featherIndex - 1) / 2)
                crystal("GuardianSwanWingFeather", 0.20, 0.42, 0.96, side * (0.72 + row * 0.12), 1.52 + row * 0.10, 0.10 + row * 0.24, row % 2 == 0 and spec.Accent or Color3.fromRGB(242, 250, 255))
            end
            for crownIndex = 1, 5 do
                local crownX = (crownIndex - 3) * 0.22
                crystal("GuardianSwanCrownSpire", 0.16, 0.55 + (crownIndex % 2) * 0.18, 0.16, crownX, 3.92, -0.72, Color3.fromRGB(255, 211, 94))
            end
            ball("GuardianSwanCrownGem", 0.24, 0.24, 0.24, 0, 4.05, -0.86, spec.Accent, Enum.Material.Neon)
        elseif giant and spec.GuardianType == "Scorpion" then
            ball("GuardianScorpionShell", 1.52, 0.52, 1.55, 0, 1.75, 0.20, spec.Accent, Enum.Material.Metal)
            for side = -1, 1, 2 do
                block("GuardianScorpionClawArm", 0.40, 0.38, 1.10, side * 1.05, 1.85, -1.25, spec.Color, CFrame.Angles(math.rad(side * 16), 0, math.rad(side * 26)))
                ball("GuardianScorpionPincer", 0.72, 0.62, 0.78, side * 1.48, 1.62, -1.95, spec.Accent, Enum.Material.Metal)
                crystal("GuardianScorpionClawTip", 0.26, 0.26, 0.82, side * 1.54, 1.45, -2.48, Color3.fromRGB(255, 218, 108), CFrame.Angles(math.rad(30), 0, math.rad(side * 18)))
                for legIndex = 1, 3 do
                    block("GuardianScorpionLeg", 0.18, 0.20, 1.15, side * (0.74 + legIndex * 0.18), 0.78, -0.10 + legIndex * 0.62, spec.Color, CFrame.Angles(math.rad(18), 0, math.rad(side * 34)))
                    ball("GuardianScorpionFoot", 0.22, 0.22, 0.30, side * (1.12 + legIndex * 0.18), 0.50, 0.05 + legIndex * 0.62, spec.Accent)
                end
            end
            local tailOffsets = {
                { 0, 2.15, 1.05 }, { 0.18, 2.75, 1.55 }, { 0.34, 3.35, 1.82 },
                { 0.22, 3.92, 1.52 }, { 0, 4.42, 1.08 },
            }
            for index, offset in ipairs(tailOffsets) do
                ball("GuardianScorpionTailSegment", 0.38 - index * 0.025, 0.42 - index * 0.025, 0.48 - index * 0.02, offset[1], offset[2], offset[3], index % 2 == 0 and spec.Accent or spec.Color, Enum.Material.Metal)
            end
            crystal("GuardianScorpionStinger", 0.28, 0.82, 0.30, 0, 4.92, 0.78, Color3.fromRGB(255, 82, 40), CFrame.Angles(math.rad(-22), 0, 0))
        elseif giant and spec.GuardianType == "Tiger" then
            for side = -1, 1, 2 do
                for stripeIndex = 1, 5 do
                    block("GuardianTigerFlankStripe", 0.14, 0.18, 0.72, side * 0.92, 1.35 + (stripeIndex % 2) * 0.15, -0.82 + stripeIndex * 0.42, Color3.fromRGB(35, 29, 29), CFrame.Angles(math.rad(side * 9), 0, math.rad(side * 12)))
                end
                crystal("GuardianTigerEarInner", 0.25, 0.30, 0.10, side * 0.48, 2.92, -0.96, Color3.fromRGB(255, 190, 144))
                ball("GuardianTigerCheekFur", 0.50, 0.54, 0.26, side * 0.76, 2.08, -1.48, Color3.fromRGB(255, 222, 184))
                for toe = 1, 3 do
                    crystal("GuardianTigerClaw", 0.12, 0.20, 0.42, side * (0.48 + toe * 0.11), 0.25, -0.95, Color3.fromRGB(245, 235, 215))
                end
            end
            for stripeIndex = 1, 4 do
                block("GuardianTigerForeheadStripe", 0.14, 0.11, 0.48, (stripeIndex - 2.5) * 0.27, 2.85, -1.78, Color3.fromRGB(35, 29, 29))
            end
            ball("GuardianTigerTailTip", 0.34, 0.34, 0.68, 0, 1.52, 2.55, Color3.fromRGB(30, 26, 26))
        elseif giant and spec.GuardianType == "Yeti" then
            ball("GuardianYetiChestFur", 1.36, 1.12, 0.54, 0, 1.58, -0.95, Color3.fromRGB(244, 251, 255))
            for side = -1, 1, 2 do
                ball("GuardianYetiShoulder", 0.82, 0.92, 0.88, side * 1.05, 2.02, 0.12, spec.Color)
                ball("GuardianYetiArm", 0.55, 1.10, 0.62, side * 1.22, 1.02, -0.14, spec.Accent)
                for tuftIndex = 1, 5 do
                    local tuftY = 1.00 + tuftIndex * 0.38
                    ball("GuardianYetiFurTuft", 0.28, 0.32, 0.30, side * (1.30 + (tuftIndex % 2) * 0.12), tuftY, -0.58 + tuftIndex * 0.12, Color3.fromRGB(246, 252, 255))
                end
                crystal("GuardianYetiIceSpike", 0.20, 0.66, 0.22, side * (0.52 + 0.22), 3.12, 0.12, spec.Accent)
                ball("GuardianYetiFoot", 0.52, 0.28, 0.72, side * 0.52, 0.18, -0.58, spec.Accent)
            end
            for spikeIndex = 1, 5 do
                crystal("GuardianYetiCrownIce", 0.18, 0.58 + (spikeIndex % 2) * 0.20, 0.18, (spikeIndex - 3) * 0.31, 3.38, -0.70, Color3.fromRGB(156, 226, 255))
            end
        elseif giant and spec.GuardianType == "Hellhound" then
            for headIndex = 1, 3 do
                local headX = (headIndex - 2) * 0.82
                ball("GuardianHellhoundNeck", 0.66, 0.82, 0.86, headX, 1.88, -1.12, spec.Color, Enum.Material.Slate)
                ball("GuardianHellhoundHead", 0.62, 0.58, 0.72, headX, 2.35, -1.72, spec.Color, Enum.Material.Slate)
                ball("GuardianHellhoundMuzzle", 0.46, 0.30, 0.55, headX, 2.13, -2.18, Color3.fromRGB(31, 26, 34), Enum.Material.Slate)
                glow("GuardianHellhoundEye", 0.10, 0.12, 0.10, headX - 0.23, 2.50, -2.25, spec.Accent)
                glow("GuardianHellhoundEye", 0.10, 0.12, 0.10, headX + 0.23, 2.50, -2.25, spec.Accent)
                crystal("GuardianHellhoundFang", 0.13, 0.32, 0.13, headX - 0.17, 1.91, -2.48, Color3.fromRGB(255, 226, 190))
                crystal("GuardianHellhoundFang", 0.13, 0.32, 0.13, headX + 0.17, 1.91, -2.48, Color3.fromRGB(255, 226, 190))
                crystal("GuardianHellhoundHorn", 0.18, 0.62, 0.18, headX, 2.92, -1.48, spec.Accent, CFrame.Angles(math.rad(-18), 0, 0))
            end
            for side = -1, 1, 2 do
                for crackIndex = 1, 4 do
                    glow("GuardianHellhoundLavaCrack", 0.08, 0.10, 0.50, side * 0.94, 1.40 + (crackIndex % 2) * 0.24, -0.82 + crackIndex * 0.40, spec.Accent)
                end
                crystal("GuardianHellhoundSpine", 0.18, 0.52, 0.22, side * 0.58, 2.45, 0.12, spec.Accent)
            end
            glow("GuardianHellhoundTailFlame", 0.42, 0.75, 0.42, 0, 2.25, 2.35, spec.Accent)
        elseif giant and spec.GuardianType == "Whale" then
            ball("GuardianWhaleUnderbelly", 1.65, 0.48, 2.85, 0, 0.92, -0.22, Color3.fromRGB(204, 239, 250))
            for side = -1, 1, 2 do
                ball("GuardianWhaleFin", 0.28, 0.30, 1.75, side * 1.55, 0.92, -0.22, spec.Accent)
                for gillIndex = 1, 5 do
                    block("GuardianWhaleGill", 0.08, 0.28, 0.10, side * 1.44, 1.18, -1.22 + gillIndex * 0.23, Color3.fromRGB(132, 217, 245))
                end
            end
            ball("GuardianWhaleTailStock", 0.38, 0.42, 1.34, 0, 1.18, 2.02, spec.Accent)
            crystal("GuardianWhaleTailFluke", 1.35, 0.20, 1.12, 0, 1.28, 2.92, spec.Accent)
            ball("GuardianWhaleDorsalFin", 0.18, 0.76, 0.88, 0, 2.10, 0.24, spec.Accent)
            for spotIndex = 1, 12 do
                local side = spotIndex % 2 == 0 and 1 or -1
                glow("GuardianWhaleBioluminescentSpot", 0.09, 0.09, 0.09, side * (0.72 + (spotIndex % 3) * 0.18), 1.62 + (spotIndex % 4) * 0.18, -0.70 + math.floor(spotIndex / 2) * 0.25, spec.Accent)
            end
        elseif giant and spec.GuardianType == "Tyrannosaur" then
            ball("GuardianTyrannosaurSkull", 1.05, 0.84, 1.36, 0, 2.18, -1.78, spec.Accent, Enum.Material.Rock)
            ball("GuardianTyrannosaurJaw", 0.98, 0.30, 1.16, 0, 1.72, -2.05, Color3.fromRGB(75, 49, 34), Enum.Material.Rock)
            for toothIndex = 1, 7 do
                local toothX = (toothIndex - 4) * 0.23
                crystal("GuardianTyrannosaurTooth", 0.12, 0.32, 0.16, toothX, 1.86, -2.46, Color3.fromRGB(246, 229, 188))
            end
            for side = -1, 1, 2 do
                block("GuardianTyrannosaurArm", 0.24, 0.58, 0.32, side * 0.82, 1.25, -1.00, spec.Color, CFrame.Angles(math.rad(-18), 0, math.rad(side * 18)))
                for clawIndex = 1, 2 do
                    crystal("GuardianTyrannosaurClaw", 0.10, 0.18, 0.26, side * (0.84 + clawIndex * 0.12), 0.98, -1.18, Color3.fromRGB(243, 222, 176))
                end
                ball("GuardianTyrannosaurFoot", 0.64, 0.28, 0.84, side * 0.58, 0.17, -0.62, spec.Accent)
            end
            for spikeIndex = 1, 7 do
                crystal("GuardianTyrannosaurDorsalPlate", 0.18, 0.42 + (spikeIndex % 2) * 0.12, 0.18, 0, 2.22, -0.68 + spikeIndex * 0.36, spec.Accent)
            end
            ball("GuardianTyrannosaurTail", 0.48, 0.50, 2.05, 0, 1.52, 2.10, spec.Color, Enum.Material.Rock)
        end

        if rarityTier >= 6 and (stageIndex >= 3 or giant) then
            for segment = 1, 10 do
                local angle = math.pi * 2 * segment / 10
                local ring = glow("Rarity ground halo", 0.15, 0.07, 0.15, math.cos(angle) * 1.62, 0.10, math.sin(angle) * 1.62, spec.Accent)
                ring.Transparency = 0.18
            end
            if rarityTier >= 8 then
                local auraAttachment = Instance.new("Attachment")
                auraAttachment.Name = "RarityAuraAttachment"
                auraAttachment.Position = Vector3.new(0, 2.15 * scale, 0)
                auraAttachment.Parent = core
                local sparkles = Instance.new("Sparkles")
                sparkles.Name = "RaritySparkles"
                sparkles.SparkleColor = spec.Accent
                sparkles.TimeScale = 0.8
                sparkles.Parent = auraAttachment
                local light = Instance.new("PointLight")
                light.Name = "RarityCoreLight"
                light.Color = spec.Accent
                light.Brightness = giant and 1.2 or 0.55
                light.Range = giant and 18 or 9
                light.Shadows = false
                light.Parent = auraAttachment
            end
        end

        model.Parent = Workspace
        model:PivotTo(CFrame.new(base))
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Anchored = true
                descendant.CanCollide = false
            end
        end
        return model
    end

    local function stageFor(animal, now)
        local age = math.max(0, now - (tonumber(animal.BornAt) or now))
        local stage, index = Rules.StageForAge(age, Config)
        return stage, index
    end

    return {
        CreateAnimalModel = createAnimalModel,
        StageFor = stageFor,
    }
end

return AnimalFactory
