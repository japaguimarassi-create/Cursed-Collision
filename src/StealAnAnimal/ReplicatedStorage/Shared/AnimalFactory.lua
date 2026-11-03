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
        local function ball(name, sx, sy, sz, x, y, z, color)
            return addBall(model, name, Vector3.new(sx * scale, sy * scale, sz * scale), point(x, y, z), color or spec.Color)
        end
        local function block(name, sx, sy, sz, x, y, z, color, rotation)
            return createPart(model, name, Vector3.new(sx * scale, sy * scale, sz * scale), CFrame.new(point(x, y, z)) * (rotation or CFrame.new()), color or spec.Color, Enum.Material.SmoothPlastic, nil, false)
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
        elseif spec.Shape == "Ray" then
            ball("Body", 1.55, 0.48, 2.5, 0, 1.08, 0)
            ball("Chest", 0.9, 0.32, 1.0, 0, 1.0, -0.72, spec.Accent)
            ball("Head", 0.95, 0.62, 0.9, 0, 1.25, -1.0)
            ball("Muzzle", 0.48, 0.22, 0.5, 0, 1.08, -1.46, spec.Accent)
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
        if spec.Shape == "Whale" or spec.Shape == "Dolphin" then
            eyeX, eyeY, eyeZ = 0.38, 1.78, -2.12
        elseif spec.Shape == "Ray" then
            eyeX, eyeY, eyeZ = 0.3, 1.28, -1.48
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
        if spec.Shape == "Whale" or spec.Shape == "Dolphin" then
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
                if spec.Shape ~= "Whale" and spec.Shape ~= "Dolphin" and spec.Shape ~= "Ray" then
                    ball("Ear", 0.32, (spec.Shape == "Fox" or spec.Shape == "Wolf") and 0.75 or 0.55, 0.24, side * 0.38, 2.8, -0.88, spec.Color)
                    ball("LegFront", 0.35, 0.72, 0.38, side * 0.48, 0.48, -0.55, spec.Color)
                    ball("LegBack", 0.38, 0.68, 0.4, side * 0.48, 0.45, 0.62, spec.Color)
                end
            end
        end
    
        if spec.Shape == "Bird" then
            for _, side in ipairs({ -1, 1 }) do
                ball("Wing", 0.42, 0.78, 1.0, side * 0.82, 1.52, 0.05, spec.Accent)
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
