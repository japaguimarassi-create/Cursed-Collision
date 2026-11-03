local WorldBuilder = {}

function WorldBuilder.new(services)
    local Config = services.Config
    local world = services.World
    local basesFolder = services.BasesFolder
    local decorationFolder = services.DecorationFolder
    local rng = services.Rng
    local treadmillStrips = services.TreadmillStrips
    local Lighting = services.Lighting

    local function createPart(parent, name, size, cf, color, material, shape, canCollide)
        local item = Instance.new("Part")
        item.Name = name
        item.Size = size
        item.CFrame = cf
        item.Color = color
        item.Material = material or Enum.Material.SmoothPlastic
        item.Anchored = true
        item.CanCollide = canCollide == true
        item.CastShadow = true
        item.TopSurface = Enum.SurfaceType.Smooth
        item.BottomSurface = Enum.SurfaceType.Smooth
        if shape then
            item.Shape = shape
        end
        item.Parent = parent
        return item
    end
    
    local function addBall(parent, name, size, position, color, material)
        return createPart(parent, name, size, CFrame.new(position), color, material, Enum.PartType.Ball, false)
    end
    
    local function addCylinder(parent, name, size, cf, color, material, canCollide)
        local cylinderSize = Vector3.new(size.Y, size.X, size.Z)
        return createPart(parent, name, cylinderSize, cf * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder, canCollide)
    end
    
    local function addLabel(part, title, subtitle, color, compact, maxDistance, heightOffset)
        local compactLabel = compact == true
        local gui = Instance.new("BillboardGui")
        gui.Name = "AnimalLabel"
        gui.Size = compactLabel and UDim2.fromOffset(112, 36) or UDim2.fromOffset(152, 44)
        gui.StudsOffset = Vector3.new(0, heightOffset or (compactLabel and 1.25 or 1.85), 0)
        gui.AlwaysOnTop = false
        gui.MaxDistance = maxDistance or (compactLabel and 18 or 32)
        gui.Adornee = part
        gui.Parent = part
    
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Title"
        nameLabel.Position = UDim2.new(0, 4, 0, 0)
        nameLabel.Size = UDim2.new(1, -8, 0.56, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBlack
        nameLabel.Text = title
        nameLabel.TextColor3 = Color3.fromRGB(255, 250, 229)
        nameLabel.TextStrokeTransparency = 0.25
        nameLabel.TextSize = compactLabel and 9 or 11
        nameLabel.TextScaled = false
        nameLabel.TextWrapped = true
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        nameLabel.Parent = gui
    
        local detail = Instance.new("TextLabel")
        detail.Name = "Subtitle"
        detail.Position = UDim2.new(0, 4, 0.56, 0)
        detail.Size = UDim2.new(1, -8, 0.44, 0)
        detail.BackgroundTransparency = 1
        detail.Font = Enum.Font.GothamBold
        detail.Text = subtitle
        detail.TextColor3 = color or Color3.fromRGB(255, 218, 105)
        detail.TextStrokeTransparency = 0.35
        detail.TextSize = compactLabel and 8 or 9
        detail.TextScaled = false
        detail.TextWrapped = true
        detail.TextTruncate = Enum.TextTruncate.AtEnd
        detail.TextXAlignment = Enum.TextXAlignment.Center
        detail.Parent = gui
        return gui
    end

    local function createTreadmill(base, center)
        local treadmill = Instance.new("Model")
        treadmill.Name = "Treadmill"
        treadmill:SetAttribute("TreadmillLevel", 1)
        treadmill.Parent = base
        local frontSide = center.Z < 0 and 1 or -1
        local origin = center + Vector3.new(0, 0, frontSide * 9.5)
    
        createPart(treadmill, "TreadmillHousing", Vector3.new(7.4, 0.62, 9.2), CFrame.new(origin + Vector3.new(0, 0.38, 0)), Color3.fromRGB(38, 52, 60), Enum.Material.Metal, nil, true)
        createPart(treadmill, "TreadmillBelt", Vector3.new(5.9, 0.14, 7.8), CFrame.new(origin + Vector3.new(0, 0.76, 0)), Color3.fromRGB(32, 43, 49), Enum.Material.DiamondPlate, nil, true)
    
        for _, side in ipairs({ -1, 1 }) do
            createPart(treadmill, "TreadmillRail", Vector3.new(0.34, 0.95, 8.8), CFrame.new(origin + Vector3.new(side * 3.15, 1.14, 0)), Color3.fromRGB(60, 192, 198), Enum.Material.Metal, nil, true)
            createPart(treadmill, "TreadmillRailLight", Vector3.new(0.08, 0.08, 8.1), CFrame.new(origin + Vector3.new(side * 3.15, 1.65, 0)), Color3.fromRGB(91, 236, 244), Enum.Material.Neon, nil, false)
        end
    
        for index = 1, 7 do
            local phase = (index - 1) * (Config.TreadmillBeltLength / 7)
            local stripe = createPart(treadmill, "MovingBeltStripe", Vector3.new(5.45, 0.035, 0.11), CFrame.new(origin + Vector3.new(0, 0.86, phase - Config.TreadmillBeltLength / 2)), index % 2 == 0 and Color3.fromRGB(87, 220, 225) or Color3.fromRGB(56, 145, 161), Enum.Material.Neon, nil, false)
            stripe.CastShadow = false
            table.insert(treadmillStrips, {
                Part = stripe,
                Kind = "Stripe",
                Origin = origin,
                Phase = phase,
                Length = Config.TreadmillBeltLength,
                Speed = Config.TreadmillBeltSpeed,
            })
        end
    
        for _, side in ipairs({ -1, 1 }) do
            local roller = createPart(treadmill, "BeltRoller", Vector3.new(0.28, 5.75, 0.28), CFrame.new(origin + Vector3.new(0, 0.88, side * 3.82)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(126, 147, 154), Enum.Material.Metal, Enum.PartType.Cylinder, false)
            roller.CastShadow = false
            table.insert(treadmillStrips, {
                Part = roller,
                Kind = "Roller",
                BaseCFrame = roller.CFrame,
                Speed = Config.TreadmillBeltSpeed * 1.4,
            })
        end
    
        local console = createPart(treadmill, "TreadmillConsole", Vector3.new(2.6, 1.15, 0.38), CFrame.new(origin + Vector3.new(0, 2.05, -3.45)), Color3.fromRGB(35, 67, 72), Enum.Material.Metal, nil, true)
        createPart(treadmill, "ConsoleScreen", Vector3.new(1.95, 0.48, 0.06), CFrame.new(origin + Vector3.new(0, 2.22, -3.68)), Color3.fromRGB(62, 242, 204), Enum.Material.Neon, nil, false)
        addLabel(console, "ESTEIRA DE VELOCIDADE", "CORRA SOBRE A FAIXA PARA TREINAR", Color3.fromRGB(95, 239, 226), false, 22, 1.4)
    
        local upgradePrompt = Instance.new("ProximityPrompt")
        upgradePrompt.Style = Enum.ProximityPromptStyle.Custom
        upgradePrompt.Name = "UpgradeTreadmillPrompt"
        upgradePrompt.ActionText = "MELHORAR ESTEIRA"
        upgradePrompt.ObjectText = "Equipamento da sua fazenda"
        upgradePrompt.HoldDuration = 0.35
        upgradePrompt.MaxActivationDistance = 10
        upgradePrompt.RequiresLineOfSight = false
        upgradePrompt:SetAttribute("InteractionType", "UpgradeTreadmill")
        upgradePrompt.Parent = console
    
        local zone = createPart(treadmill, "TrainingZone", Vector3.new(5.45, 1.3, 6.35), CFrame.new(origin + Vector3.new(0, 4.05, 0)), Color3.fromRGB(0, 0, 0), Enum.Material.SmoothPlastic, nil, false)
        zone.Transparency = 1
        zone.CastShadow = false
        zone.CanTouch = false
        zone.CanQuery = false
    
        treadmill.PrimaryPart = treadmill:FindFirstChild("TreadmillHousing")
        return treadmill
    end
    
    local function createBase(index)
        local basePositions = {
            Vector3.new(-69, 0, -53), Vector3.new(-23, 0, -53), Vector3.new(23, 0, -53), Vector3.new(69, 0, -53),
            Vector3.new(-69, 0, 53), Vector3.new(-23, 0, 53), Vector3.new(23, 0, 53), Vector3.new(69, 0, 53),
        }
        local center = basePositions[index]
        local base = Instance.new("Model")
        base.Name = "Farm_" .. tostring(index)
        base:SetAttribute("BaseIndex", index)
        base:SetAttribute("OwnerUserId", 0)
        base.Parent = basesFolder
    
        createPart(base, "Floor", Vector3.new(34, 1, 31), CFrame.new(center + Vector3.new(0, -0.3, 0)), Color3.fromRGB(111, 171, 83), Enum.Material.Grass, nil, true)
        local frontSign = center.Z < 0 and 1 or -1
        local frontSide = frontSign
        local fenceColor = Color3.fromRGB(151, 91, 52)
        local function fence(name, size, offset, color)
            local rail = createPart(base, name, size, CFrame.new(center + offset), color or fenceColor, Enum.Material.WoodPlanks, nil, false)
            rail.CastShadow = true
            return rail
        end
        for _, zSide in ipairs({ -1, 1 }) do
            local z = zSide * 14.8
            if zSide == -frontSign then
                fence("PenFenceBackLower", Vector3.new(34, 0.35, 0.45), Vector3.new(0, 0.95, z))
                fence("PenFenceBackUpper", Vector3.new(34, 0.35, 0.45), Vector3.new(0, 2.05, z), Color3.fromRGB(183, 119, 65))
            else
                fence("PenFenceGateLeftLower", Vector3.new(12, 0.35, 0.45), Vector3.new(-11, 0.95, z))
                fence("PenFenceGateRightLower", Vector3.new(12, 0.35, 0.45), Vector3.new(11, 0.95, z))
                fence("PenFenceGateLeftUpper", Vector3.new(12, 0.35, 0.45), Vector3.new(-11, 2.05, z), Color3.fromRGB(183, 119, 65))
                fence("PenFenceGateRightUpper", Vector3.new(12, 0.35, 0.45), Vector3.new(11, 2.05, z), Color3.fromRGB(183, 119, 65))
            end
        end
        for _, xSide in ipairs({ -1, 1 }) do
            local x = xSide * 16.5
            fence("PenFenceSideLower", Vector3.new(0.45, 0.35, 31), Vector3.new(x, 0.95, 0))
            fence("PenFenceSideUpper", Vector3.new(0.45, 0.35, 31), Vector3.new(x, 2.05, 0), Color3.fromRGB(183, 119, 65))
        end
        for _, xSide in ipairs({ -1, 1 }) do
            for _, zSide in ipairs({ -1, 1 }) do
                createPart(base, "PenFencePost", Vector3.new(0.8, 3.2, 0.8), CFrame.new(center + Vector3.new(xSide * 16.4, 1.35, zSide * 14.8)), Color3.fromRGB(124, 73, 42), Enum.Material.Wood, nil, false)
            end
        end
        for _, side in ipairs({ -1, 1 }) do
            createPart(base, "PenSignPost", Vector3.new(0.55, 3.8, 0.55), CFrame.new(center + Vector3.new(side * 5.7, 1.9, -frontSide * 10.8)), Color3.fromRGB(124, 73, 42), Enum.Material.Wood, nil, false)
        end
        local sign = createPart(base, "PenSign", Vector3.new(12.5, 1.8, 0.45), CFrame.new(center + Vector3.new(0, 3.75, -frontSide * 10.8)), Color3.fromRGB(58, 55, 43), Enum.Material.Wood, nil, false)
        addLabel(sign, "SEU CERCADO", "OVOS • ANIMAIS • RENDA", Color3.fromRGB(255, 218, 105), false, 28, 1.35)

        local display = Instance.new("Folder")
        display.Name = "StoredAnimals"
        display.Parent = base
        local offsets = {
            Vector3.new(-5.5, 0.35, -1), Vector3.new(0, 0.35, -1), Vector3.new(5.5, 0.35, -1),
            Vector3.new(-5.5, 0.35, 5), Vector3.new(0, 0.35, 5), Vector3.new(5.5, 0.35, 5),
        }
        for slotIndex, offset in ipairs(offsets) do
            local pad = createPart(display, "Slot_" .. tostring(slotIndex), Vector3.new(5.1, 0.25, 5.1), CFrame.new(center + offset), Color3.fromRGB(235, 222, 183), Enum.Material.Sand, nil, false)
            pad:SetAttribute("SlotIndex", slotIndex)
        end
    
        createTreadmill(base, center)
    
        local deposit = createPart(base, "DepositPad", Vector3.new(7, 0.45, 4), CFrame.new(center + Vector3.new(-12, 0.35, frontSide * 10)), Color3.fromRGB(78, 235, 128), Enum.Material.Neon, nil, false)
        addLabel(deposit, "GUARDAR ANIMAL", "Leve o bebê para casa", Color3.fromRGB(255, 255, 230), false, 18, 1.2)
        local depositPrompt = Instance.new("ProximityPrompt")
        depositPrompt.Style = Enum.ProximityPromptStyle.Custom
        depositPrompt.Name = "DepositPrompt"
        depositPrompt.ActionText = "GUARDAR"
        depositPrompt.ObjectText = "Sua fazenda"
        depositPrompt.HoldDuration = Config.DepositHoldDuration
        depositPrompt.MaxActivationDistance = 12
        depositPrompt.RequiresLineOfSight = false
        depositPrompt:SetAttribute("InteractionType", "DepositAnimal")
        depositPrompt.Parent = deposit
    
        local collect = createPart(base, "CollectPad", Vector3.new(7, 0.45, 4), CFrame.new(center + Vector3.new(12, 0.35, frontSide * 10)), Color3.fromRGB(255, 203, 65), Enum.Material.Neon, nil, false)
        addLabel(collect, "COLETAR MOEDAS", "Renda dos animais", Color3.fromRGB(255, 255, 230), false, 18, 1.2)
        local collectPrompt = Instance.new("ProximityPrompt")
        collectPrompt.Style = Enum.ProximityPromptStyle.Custom
        collectPrompt.Name = "CollectPrompt"
        collectPrompt.ActionText = "COLETAR"
        collectPrompt.ObjectText = "Moedas da fazenda"
        collectPrompt.HoldDuration = Config.CollectHoldDuration
        collectPrompt.MaxActivationDistance = 12
        collectPrompt.RequiresLineOfSight = false
        collectPrompt:SetAttribute("InteractionType", "CollectIncome")
        collectPrompt.Parent = collect
    
        local entryGate = createPart(base, "FarmEntryArchRight", Vector3.new(0.65, 4.2, 0.65), CFrame.new(center + Vector3.new(6.5, 2.15, frontSide * 15.2)), Color3.fromRGB(255, 216, 104), Enum.Material.Neon, nil, false)
        createPart(base, "FarmEntryArchLeft", Vector3.new(0.65, 4.2, 0.65), CFrame.new(center + Vector3.new(-6.5, 2.15, frontSide * 15.2)), Color3.fromRGB(255, 216, 104), Enum.Material.Neon, nil, false)
        createPart(base, "FarmEntryArchTop", Vector3.new(13.5, 0.65, 0.65), CFrame.new(center + Vector3.new(0, 4.1, frontSide * 15.2)), Color3.fromRGB(255, 216, 104), Enum.Material.Neon, nil, false)
        entryGate.CanCollide = false
        local farmBeacon = createPart(base, "FarmBeacon", Vector3.new(0.7, 5, 0.7), CFrame.new(center + Vector3.new(14, 2.5, -frontSide * 10)), Color3.fromRGB(122, 245, 136), Enum.Material.Neon, nil, false)
        addBall(base, "FarmBeaconOrb", Vector3.new(2, 2, 2), center + Vector3.new(14, 5.7, -frontSide * 10), Color3.fromRGB(255, 222, 105), Enum.Material.Neon)
        base.PrimaryPart = base.Floor
        return base
    end
    
    local function buildTree(parent, position, biome, index)
        local trunkHeight = rng:NextNumber(5, 10)
        addCylinder(parent, "TreeTrunk", Vector3.new(rng:NextNumber(1.2, 2), trunkHeight, rng:NextNumber(1.2, 2)), CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)), Color3.fromRGB(113, 76, 49), Enum.Material.Wood, true)
        if biome.Id == "Frost" then
            for layer = 1, 3 do
                createPart(parent, "SnowPine", Vector3.new(1, 4.2, 1), CFrame.new(position + Vector3.new(0, trunkHeight + layer * 1.4, 0)) * CFrame.Angles(0, 0, 0), Color3.fromRGB(206, 235, 250), Enum.Material.Ice, Enum.PartType.Ball, false)
            end
        elseif biome.Id == "Volcano" then
            for layer = 1, 3 do
                addBall(parent, "EmberCanopy", Vector3.new(3.5, 2.8, 3.5), position + Vector3.new(0, trunkHeight + layer * 1.1, 0), layer == 2 and biome.Accent or Color3.fromRGB(111, 67, 63), Enum.Material.Slate)
            end
        elseif biome.Id == "Wetlands" then
            addBall(parent, "MossCanopy", Vector3.new(7, 3.5, 7), position + Vector3.new(0, trunkHeight, 0), Color3.fromRGB(34, 103, 52), Enum.Material.Grass)
            addBall(parent, "MossCanopy", Vector3.new(5, 3, 5), position + Vector3.new(2.5, trunkHeight + 1, 0), biome.Accent, Enum.Material.Grass)
        elseif biome.Name == "Deserto" then
            addCylinder(parent, "DesertCactus", Vector3.new(1.15, 7.2, 1.15), CFrame.new(position + Vector3.new(0, 3.6, 0)), Color3.fromRGB(68, 137, 72), Enum.Material.Grass, false)
            addCylinder(parent, "DesertCactusArm", Vector3.new(0.8, 3.1, 0.8), CFrame.new(position + Vector3.new(-1.2, 4.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(68, 137, 72), Enum.Material.Grass, false)
            addCylinder(parent, "DesertCactusArm", Vector3.new(0.8, 2.6, 0.8), CFrame.new(position + Vector3.new(1.3, 5.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(68, 137, 72), Enum.Material.Grass, false)
        else
            addBall(parent, "TreeCanopy", Vector3.new(7, 5.5, 7), position + Vector3.new(0, trunkHeight, 0), biome.Id == "Savanna" and Color3.fromRGB(194, 165, 75) or Color3.fromRGB(68, 151, 82), Enum.Material.Grass)
            addBall(parent, "TreeCanopy", Vector3.new(5, 4.2, 5), position + Vector3.new(2.5, trunkHeight + 1, 0), biome.Accent, Enum.Material.Grass)
        end
    end
    
    local function buildScenery()
        Lighting.ClockTime = 14
        Lighting.Brightness = 2.2
        Lighting.GlobalShadows = true
        Lighting.EnvironmentDiffuseScale = 0.45
        Lighting.EnvironmentSpecularScale = 0.35
        Lighting.Ambient = Color3.fromRGB(132, 147, 135)
        Lighting.OutdoorAmbient = Color3.fromRGB(176, 192, 170)
        Lighting.FogColor = Color3.fromRGB(192, 220, 199)
        Lighting.FogStart = 500
        Lighting.FogEnd = 1550
        local atmosphere = Lighting:FindFirstChild("StealAnimalAtmosphere") or Instance.new("Atmosphere")
        atmosphere.Name = "StealAnimalAtmosphere"
        atmosphere.Density = 0.18
        atmosphere.Offset = 0.12
        atmosphere.Color = Color3.fromRGB(199, 235, 196)
        atmosphere.Decay = Color3.fromRGB(105, 147, 159)
        atmosphere.Glare = 0.12
        atmosphere.Haze = 1.2
        atmosphere.Parent = Lighting
    
        createPart(world, "HubGround", Vector3.new(210, 1, 210), CFrame.new(0, -1, 0), Color3.fromRGB(101, 193, 68), Enum.Material.Grass, nil, true)
        createPart(world, "HubGrassBorder", Vector3.new(198, 0.25, 198), CFrame.new(0, -0.32, 0), Color3.fromRGB(141, 213, 89), Enum.Material.Grass, nil, false)
        createPart(world, "CorridorFloor", Vector3.new(1500, 0.28, 56), CFrame.new(850, -0.38, 0), Color3.fromRGB(106, 190, 75), Enum.Material.Grass, nil, true)
        createPart(world, "MainPath", Vector3.new(1500, 0.35, 16), CFrame.new(850, -0.15, 0), Color3.fromRGB(211, 190, 145), Enum.Material.Ground, nil, true)
        for index = 1, 72 do
            local markerX = 105 + index * 20
            if markerX < 1590 then
                local marker = createPart(world, "MainPathTile", Vector3.new(1.4, 0.055, 1.2), CFrame.new(markerX, 0.055, 0), index % 2 == 0 and Color3.fromRGB(245, 222, 167) or Color3.fromRGB(188, 163, 121), Enum.Material.SmoothPlastic, nil, false)
                marker.CastShadow = false
            end
        end
        for _, side in ipairs({ -1, 1 }) do
            createPart(world, "TrackInnerRail", Vector3.new(1500, 0.45, 0.5), CFrame.new(850, 0.22, side * 8.5), Color3.fromRGB(155, 104, 65), Enum.Material.Wood, nil, false)
            createPart(world, "CorridorEdge", Vector3.new(1500, 0.2, 0.8), CFrame.new(850, 0.04, side * 28), Color3.fromRGB(244, 191, 110), Enum.Material.SmoothPlastic, nil, false)
            createPart(world, "CorridorBoundaryWall", Vector3.new(1500, 20, 2), CFrame.new(850, 9.5, side * 86), Color3.fromRGB(184, 119, 72), Enum.Material.Brick, nil, true)
            createPart(world, "CorridorWallCap", Vector3.new(1500, 0.8, 2.4), CFrame.new(850, 19.9, side * 86), Color3.fromRGB(232, 173, 112), Enum.Material.WoodPlanks, nil, false)
        end

        local hubGrid = Instance.new("Folder")
        hubGrid.Name = "CentralHubGrid"
        hubGrid.Parent = decorationFolder
        for tileX = -5, 5 do
            for tileZ = -5, 5 do
                local tile = createPart(hubGrid, "CentralHubTile", Vector3.new(17.8, 0.08, 17.8), CFrame.new(tileX * 18, -0.08, tileZ * 18), (tileX + tileZ) % 2 == 0 and Color3.fromRGB(119, 220, 76) or Color3.fromRGB(91, 197, 66), Enum.Material.SmoothPlastic, nil, false)
                tile.CastShadow = false
            end
        end

        for _, edge in ipairs({ -1, 1 }) do
            createPart(world, "HubPerimeterGlow", Vector3.new(190, 0.16, 0.5), CFrame.new(0, 0.02, edge * 96), Color3.fromRGB(176, 226, 112), Enum.Material.SmoothPlastic, nil, false)
            createPart(world, "HubPerimeterGlow", Vector3.new(0.5, 0.16, 190), CFrame.new(edge * 96, 0.02, 0), Color3.fromRGB(176, 226, 112), Enum.Material.SmoothPlastic, nil, false)
        end

        createPart(world, "HubSpawnPadBase", Vector3.new(16, 0.8, 16), CFrame.new(0, -0.05, 0), Color3.fromRGB(231, 221, 190), Enum.Material.SmoothPlastic, nil, false)
        addCylinder(world, "HubSpawnPad", Vector3.new(9, 0.8, 9), CFrame.new(0, 0.55, 0), Color3.fromRGB(99, 198, 123), Enum.Material.SmoothPlastic, false)
        addBall(world, "HubSpawnMarker", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 1.25, 0), Color3.fromRGB(255, 218, 105), Enum.Material.Neon)

        local safeZoneLine = createPart(world, "SafeZoneLine", Vector3.new(0.9, 0.16, 56), CFrame.new(100, 0.08, 0), Color3.fromRGB(255, 204, 88), Enum.Material.Neon, nil, false)
        safeZoneLine.CastShadow = false
        local safeSign = createPart(world, "SafeZoneSign", Vector3.new(0.7, 3.2, 18), CFrame.new(34, 7.4, -37), Color3.fromRGB(52, 68, 48), Enum.Material.Wood, nil, false)
        addLabel(safeSign, "SAFE ZONE", "FAZENDAS • TREINO • MELHORIAS", Color3.fromRGB(255, 226, 135), false, 80, 1.8)
        local routeSign = createPart(world, "RouteStartSign", Vector3.new(0.7, 3.2, 18), CFrame.new(68, 7.4, 0), Color3.fromRGB(52, 68, 48), Enum.Material.Wood, nil, false)
        addLabel(routeSign, "ROTA DOS OVOS", "PEGUE • FUJA • VOLTE PARA A FAZENDA", Color3.fromRGB(255, 226, 135), false, 100, 1.8)

        for biomeIndex, biome in ipairs(Config.Biomes) do
            createPart(world, biome.Id .. "Ground", Vector3.new(180, 1, 170), CFrame.new(biome.CenterX, -0.5, 0), biome.Ground, biome.Material, nil, true)
            createPart(world, biome.Id .. "Path", Vector3.new(180, 0.32, 18), CFrame.new(biome.CenterX, -0.15, 0), Color3.fromRGB(211, 190, 145), Enum.Material.Ground, nil, true)
            local entryStrip = createPart(world, biome.Id .. "EntryStrip", Vector3.new(1.2, 0.12, 44), CFrame.new(biome.CenterX - 76, 0.12, 0), biome.Accent, Enum.Material.Neon, nil, false)
            entryStrip.CastShadow = false
            for _, side in ipairs({ -1, 1 }) do
                local post = createPart(world, biome.Id .. "RouteMarker", Vector3.new(0.85, 4.8, 0.85), CFrame.new(biome.CenterX - 76, 2.4, side * 24), biome.Accent, Enum.Material.Wood, nil, false)
                post.CastShadow = false
                addBall(world, biome.Id .. "RouteMarkerCap", Vector3.new(1.2, 1.2, 1.2), post.Position + Vector3.new(0, 2.7, 0), biome.Accent, Enum.Material.Neon)
            end
            local gateX = biome.CenterX - 76
            for _, side in ipairs({ -1, 1 }) do
                createPart(world, biome.Id .. "SpeedGatePost", Vector3.new(1.2, 8, 1.2), CFrame.new(gateX, 4, side * 10), biome.Accent, Enum.Material.Metal, nil, false)
                addBall(world, biome.Id .. "SpeedGateCap", Vector3.new(1.8, 1.8, 1.8), Vector3.new(gateX, 8.6, side * 10), biome.Accent, Enum.Material.Neon)
            end
            createPart(world, biome.Id .. "SpeedGateTop", Vector3.new(1.2, 1, 22), CFrame.new(gateX, 8.1, 0), biome.Accent, Enum.Material.Metal, nil, false)
            local gateBarrier = createPart(world, biome.Id .. "SpeedGateBarrier", Vector3.new(0.35, 5.5, 18), CFrame.new(gateX, 2.75, 0), biome.Accent, Enum.Material.Neon, nil, false)
            gateBarrier.Transparency = 0.48
            gateBarrier.CanTouch = false
            gateBarrier.CanQuery = false
            gateBarrier:SetAttribute("BiomeId", biome.Id)
            gateBarrier:SetAttribute("MinimumSpeed", biome.MinSpeed)
            local gateSign = createPart(world, biome.Id .. "SpeedGateSign", Vector3.new(12, 1.6, 0.4), CFrame.new(gateX, 10, -15), Color3.fromRGB(39, 57, 53), Enum.Material.Wood, nil, false)
            addLabel(gateSign, "VELOCIDADE MÍNIMA", tostring(biome.MinSpeed) .. " SPEED", biome.Accent, false, 90, 1.4)

            local sign = createPart(world, biome.Id .. "Sign", Vector3.new(18, 3, 0.5), CFrame.new(biome.CenterX - 76, 8, -31), Color3.fromRGB(55, 65, 48), Enum.Material.Wood, nil, false)
            addLabel(sign, "FASE " .. tostring(biomeIndex) .. " • " .. biome.Name, "SPEED MÍNIMA: " .. tostring(biome.MinSpeed), biome.Accent, false, 70, 1.8)

            local transitionX = biome.CenterX + 88
            local transition = createPart(world, biome.Id .. "TransitionLine", Vector3.new(0.65, 0.12, 44), CFrame.new(transitionX, 0.12, 0), biome.Accent, Enum.Material.Neon, nil, false)
            transition.CastShadow = false

            local landmarkX = biome.CenterX + 18
            local landmarkZ = biomeIndex % 2 == 0 and 66 or -66
            local landmarkPosition = Vector3.new(landmarkX, 0, landmarkZ)
            if biome.Id == "Meadow" then
                addCylinder(decorationFolder, "MeadowMonumentStem", Vector3.new(4.5, 22, 4.5), CFrame.new(landmarkPosition + Vector3.new(0, 11, 0)), Color3.fromRGB(105, 73, 48), Enum.Material.Wood, false)
                addBall(decorationFolder, "MeadowMonumentCanopy", Vector3.new(19, 13, 19), landmarkPosition + Vector3.new(0, 22, 0), Color3.fromRGB(54, 137, 63), Enum.Material.Grass)
                addBall(decorationFolder, "MeadowMonumentPetal", Vector3.new(13, 9, 13), landmarkPosition + Vector3.new(1, 29, 0), Color3.fromRGB(107, 183, 83), Enum.Material.Grass)
                for rootIndex = 1, 4 do
                    local rootAngle = math.rad((rootIndex - 1) * 90)
                    createPart(decorationFolder, "MeadowMonumentRoot", Vector3.new(8, 1.5, 2), CFrame.new(landmarkPosition + Vector3.new(math.cos(rootAngle) * 4, 0.8, math.sin(rootAngle) * 4)) * CFrame.Angles(0, -rootAngle, 0), Color3.fromRGB(105, 73, 48), Enum.Material.Wood, nil, false)
                end
            elseif biome.Id == "Lake" then
                createPart(decorationFolder, "LakeMonumentCliff", Vector3.new(21, 13, 7), CFrame.new(landmarkPosition + Vector3.new(0, 6.5, 3)), Color3.fromRGB(102, 139, 145), Enum.Material.Rock, nil, false)
                local waterfall = createPart(decorationFolder, "LakeMonumentWaterfall", Vector3.new(12, 12, 0.5), CFrame.new(landmarkPosition + Vector3.new(0, 5.8, -1)), Color3.fromRGB(97, 222, 238), Enum.Material.Glass, nil, false)
                waterfall.Transparency = 0.28
                addBall(decorationFolder, "LakeMonumentPool", Vector3.new(23, 0.55, 16), landmarkPosition + Vector3.new(0, 0.2, -2), Color3.fromRGB(88, 203, 225), Enum.Material.Glass)
                addBall(decorationFolder, "LakeMonumentTop", Vector3.new(4, 4, 4), landmarkPosition + Vector3.new(0, 14, 3), Color3.fromRGB(127, 239, 246), Enum.Material.Neon)
            elseif biome.Id == "Forest" then
                addBall(decorationFolder, "ForestMonumentDune", Vector3.new(24, 7, 19), landmarkPosition + Vector3.new(0, 2.7, 0), Color3.fromRGB(219, 180, 106), Enum.Material.Sand)
                addCylinder(decorationFolder, "ForestMonumentStoneArchLeft", Vector3.new(2.4, 13, 2.4), CFrame.new(landmarkPosition + Vector3.new(-7, 6.5, 0)), Color3.fromRGB(160, 124, 77), Enum.Material.Rock, false)
                addCylinder(decorationFolder, "ForestMonumentStoneArchRight", Vector3.new(2.4, 13, 2.4), CFrame.new(landmarkPosition + Vector3.new(7, 6.5, 0)), Color3.fromRGB(160, 124, 77), Enum.Material.Rock, false)
                createPart(decorationFolder, "ForestMonumentStoneArchTop", Vector3.new(16, 2.4, 3), CFrame.new(landmarkPosition + Vector3.new(0, 13, 0)), Color3.fromRGB(180, 143, 91), Enum.Material.Rock, nil, false)
            elseif biome.Id == "Wetlands" then
                createPart(decorationFolder, "WetlandsMonumentDeck", Vector3.new(18, 0.8, 14), CFrame.new(landmarkPosition + Vector3.new(0, 0.4, 0)), Color3.fromRGB(119, 88, 60), Enum.Material.WoodPlanks, nil, false)
                for postSide = -1, 1, 2 do
                    for postDepth = -1, 1, 2 do
                        createPart(decorationFolder, "WetlandsMonumentPost", Vector3.new(0.8, 7, 0.8), CFrame.new(landmarkPosition + Vector3.new(postSide * 7, 3.5, postDepth * 5)), Color3.fromRGB(102, 78, 55), Enum.Material.Wood, nil, false)
                    end
                end
                createPart(decorationFolder, "WetlandsMonumentRoof", Vector3.new(22, 1.1, 17), CFrame.new(landmarkPosition + Vector3.new(0, 7.4, 0)), Color3.fromRGB(56, 93, 85), Enum.Material.Slate, nil, false)
                createPart(decorationFolder, "WetlandsMonumentLamp", Vector3.new(3, 2.8, 3), CFrame.new(landmarkPosition + Vector3.new(0, 5.2, -6)), Color3.fromRGB(115, 255, 214), Enum.Material.Neon, nil, false)
            elseif biome.Id == "Frost" then
                for shard = 1, 5 do
                    local angle = math.rad((shard - 1) * 72)
                    local height = shard % 2 == 0 and 17 or 12
                    local crystal = addCylinder(decorationFolder, "FrostMonumentShard", Vector3.new(2.7, height, 2.7), CFrame.new(landmarkPosition + Vector3.new(math.cos(angle) * 5, height / 2, math.sin(angle) * 5)) * CFrame.Angles(0, 0, math.rad(shard % 2 == 0 and 8 or -8)), Color3.fromRGB(126, 215, 255), Enum.Material.Ice, false)
                    crystal.Transparency = 0.12
                end
                addBall(decorationFolder, "FrostMonumentCore", Vector3.new(4.5, 4.5, 4.5), landmarkPosition + Vector3.new(0, 8, 0), Color3.fromRGB(207, 248, 255), Enum.Material.Neon)
            elseif biome.Id == "Savanna" then
                addBall(decorationFolder, "SavannaMonumentFossilBase", Vector3.new(24, 4, 15), landmarkPosition + Vector3.new(0, 1.8, 0), Color3.fromRGB(165, 145, 107), Enum.Material.Rock)
                for rib = -2, 2 do
                    local ribPart = addCylinder(decorationFolder, "SavannaMonumentFossilRib", Vector3.new(1.15, 13, 1.15), CFrame.new(landmarkPosition + Vector3.new(rib * 4, 7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(223, 207, 161), Enum.Material.Rock, false)
                    ribPart.CastShadow = false
                end
                addBall(decorationFolder, "SavannaMonumentSkull", Vector3.new(6, 4, 5), landmarkPosition + Vector3.new(13, 3, 0), Color3.fromRGB(223, 207, 161), Enum.Material.Rock)
            elseif biome.Id == "Volcano" then
                addBall(decorationFolder, "VolcanoMonumentBase", Vector3.new(25, 15, 23), landmarkPosition + Vector3.new(0, 5.5, 0), Color3.fromRGB(67, 60, 63), Enum.Material.Slate)
                addBall(decorationFolder, "VolcanoMonumentLava", Vector3.new(10, 3.2, 10), landmarkPosition + Vector3.new(0, 12.5, 0), Color3.fromRGB(255, 100, 40), Enum.Material.Neon)
                for flow = 1, 3 do
                    local flowX = (flow - 2) * 5
                    createPart(decorationFolder, "VolcanoMonumentFlow", Vector3.new(1.2, 5.5, 1.2), CFrame.new(landmarkPosition + Vector3.new(flowX, 5, -8)), Color3.fromRGB(255, 125, 49), Enum.Material.Neon, nil, false)
                end
                addBall(decorationFolder, "VolcanoMonumentSmoke", Vector3.new(5.5, 5.5, 5.5), landmarkPosition + Vector3.new(0, 19, 0), Color3.fromRGB(100, 88, 89), Enum.Material.Slate)
            elseif biome.Id == "Ocean" then
                addCylinder(decorationFolder, "OceanMonumentTower", Vector3.new(5.5, 17, 5.5), CFrame.new(landmarkPosition + Vector3.new(0, 8.5, 0)), Color3.fromRGB(75, 123, 146), Enum.Material.Slate, false)
                addCylinder(decorationFolder, "OceanMonumentRoof", Vector3.new(7.5, 2.8, 7.5), CFrame.new(landmarkPosition + Vector3.new(0, 18, 0)), Color3.fromRGB(46, 77, 104), Enum.Material.Metal, false)
                addBall(decorationFolder, "OceanMonumentBeacon", Vector3.new(3.5, 3.5, 3.5), landmarkPosition + Vector3.new(0, 20, 0), Color3.fromRGB(105, 235, 255), Enum.Material.Neon)
                for fin = 1, 2 do
                    createPart(decorationFolder, "OceanMonumentFin", Vector3.new(1.2, 7, 3.5), CFrame.new(landmarkPosition + Vector3.new(fin == 1 and -5 or 5, 4.5, 0)) * CFrame.Angles(0, 0, math.rad(fin == 1 and 18 or -18)), Color3.fromRGB(77, 159, 184), Enum.Material.Slate, nil, false)
                end
            end

            local plaque = createPart(decorationFolder, biome.Id .. "LandmarkPlaque", Vector3.new(10, 2.2, 0.5), CFrame.new(landmarkPosition + Vector3.new(0, 4.5, landmarkZ > 0 and -11 or 11)), Color3.fromRGB(39, 57, 53), Enum.Material.Wood, nil, false)
            addLabel(plaque, biome.Name, "MARCO DO BIOMA " .. tostring(biomeIndex), biome.Accent, true, 48, 1.2)
            local nestZ = biomeIndex % 2 == 0 and -49 or 49
            local nestX = biome.CenterX + 40
            createPart(decorationFolder, biome.Id .. "EggNestBase", Vector3.new(16, 0.5, 12), CFrame.new(nestX, 0.08, nestZ), Color3.fromRGB(112, 75, 49), Enum.Material.WoodPlanks, nil, false)
            for eggIndex = 1, 3 do
                local eggX = nestX + (eggIndex - 2) * 4.2
                local eggColor = eggIndex == 1 and Color3.fromRGB(250, 245, 222) or eggIndex == 2 and biome.Accent or Color3.fromRGB(255, 190, 83)
                createPart(decorationFolder, biome.Id .. "EggPedestal", Vector3.new(3.5, 0.7, 3.5), CFrame.new(eggX, 0.52, nestZ), Color3.fromRGB(72, 57, 47), Enum.Material.Slate, nil, false)
                addBall(decorationFolder, biome.Id .. "WildEgg", Vector3.new(2.6, 3.6, 2.6), Vector3.new(eggX, 2.15, nestZ), eggColor, Enum.Material.SmoothPlastic)
                addBall(decorationFolder, biome.Id .. "EggBand", Vector3.new(2.7, 0.48, 2.7), Vector3.new(eggX, 1.65, nestZ), biome.Accent, Enum.Material.Neon)
                addBall(decorationFolder, biome.Id .. "EggTopGem", Vector3.new(0.75, 0.9, 0.75), Vector3.new(eggX, 3.7, nestZ), Color3.fromRGB(255, 250, 221), Enum.Material.Neon)
                for shard = 1, 3 do
                    local angle = math.rad(shard * 120)
                    addBall(decorationFolder, biome.Id .. "EggOrbit", Vector3.new(0.26, 0.26, 0.26), Vector3.new(eggX + math.cos(angle) * 2.1, 2.2 + math.sin(angle) * 0.4, nestZ + math.sin(angle) * 2.1), biome.Accent, Enum.Material.Neon)
                end
            end
            local nestSign = createPart(decorationFolder, biome.Id .. "NestSign", Vector3.new(13, 2.4, 0.45), CFrame.new(nestX, 4.4, nestZ - 6.5), Color3.fromRGB(45, 52, 47), Enum.Material.Wood, nil, false)
            addLabel(nestSign, "NINHO " .. tostring(biomeIndex), "OVOS SELVAGENS", biome.Accent)
    
            if biome.Id == "Meadow" then
                for flower = 1, 9 do
                    local x = biome.CenterX + rng:NextNumber(-28, 28)
                    local z = (flower % 2 == 0 and 1 or -1) * rng:NextNumber(34, 52)
                    addBall(decorationFolder, "MeadowBloom", Vector3.new(1.8, 0.45, 1.8), Vector3.new(x, 0.18, z), flower % 2 == 0 and Color3.fromRGB(255, 194, 92) or Color3.fromRGB(255, 155, 199), Enum.Material.Neon)
                end
            elseif biome.Id == "Lake" then
                for reed = 1, 6 do
                    local x = biome.CenterX + rng:NextNumber(-64, 64)
                    local z = (reed % 2 == 0 and 1 or -1) * rng:NextNumber(38, 66)
                    addCylinder(decorationFolder, "LakeReed", Vector3.new(0.28, 3.2, 0.28), CFrame.new(x, 1.6, z), Color3.fromRGB(89, 152, 82), Enum.Material.Grass, false)
                    addBall(decorationFolder, "LakeWater", Vector3.new(8, 0.16, 6), Vector3.new(x + 3, 0.04, z), Color3.fromRGB(85, 187, 215), Enum.Material.Glass)
                end
            elseif biome.Id == "Forest" then
                for cactus = 1, 6 do
                    local x = biome.CenterX + rng:NextNumber(-54, 54)
                    local z = (cactus % 2 == 0 and 1 or -1) * rng:NextNumber(34, 62)
                    addCylinder(decorationFolder, "DesertCactus", Vector3.new(1.1, rng:NextNumber(4, 7), 1.1), CFrame.new(x, 2.5, z), Color3.fromRGB(72, 139, 76), Enum.Material.Grass, false)
                    addBall(decorationFolder, "DesertRock", Vector3.new(4, 2.2, 3.6), Vector3.new(x + 4, 0.7, z + 2), Color3.fromRGB(176, 139, 89), Enum.Material.Rock)
                end
            elseif biome.Id == "Wetlands" then
                for pool = 1, 4 do
                    local side = pool % 2 == 0 and 1 or -1
                    addBall(decorationFolder, "WetlandPool", Vector3.new(20, 0.18, 14), Vector3.new(biome.CenterX + rng:NextNumber(-46, 46), 0.03, side * rng:NextNumber(38, 58)), Color3.fromRGB(70, 180, 184), Enum.Material.Glass)
                end
            elseif biome.Id == "Frost" then
                for pillar = 1, 4 do
                    local x = biome.CenterX + rng:NextNumber(-48, 48)
                    local z = (pillar % 2 == 0 and 1 or -1) * rng:NextNumber(34, 60)
                    addCylinder(decorationFolder, "IcePillar", Vector3.new(2.2, rng:NextNumber(5, 10), 2.2), CFrame.new(x, 2.8, z), Color3.fromRGB(142, 220, 255), Enum.Material.Ice, false)
                end
            elseif biome.Id == "Savanna" then
                for stone = 1, 5 do
                    local x = biome.CenterX + rng:NextNumber(-48, 48)
                    local z = (stone % 2 == 0 and 1 or -1) * rng:NextNumber(34, 58)
                    addBall(decorationFolder, "SavannaBoulder", Vector3.new(rng:NextNumber(4, 8), rng:NextNumber(3, 6), rng:NextNumber(4, 8)), Vector3.new(x, 1.2, z), Color3.fromRGB(140, 124, 93), Enum.Material.Rock)
                end
                for fossil = 1, 3 do
                    createPart(decorationFolder, "PrehistoricFossilRib", Vector3.new(0.8, 5.5, 0.8), CFrame.new(biome.CenterX + (fossil - 2) * 10, 2.75, (fossil % 2 == 0 and 1 or -1) * 42), Color3.fromRGB(220, 203, 157), Enum.Material.Rock, nil, false)
                end
            elseif biome.Id == "Ocean" then
                for bubble = 1, 9 do
                    local x = biome.CenterX + rng:NextNumber(-68, 68)
                    local z = (bubble % 2 == 0 and 1 or -1) * rng:NextNumber(36, 70)
                    addBall(decorationFolder, "OceanBubble", Vector3.new(1.2, 1.2, 1.2), Vector3.new(x, rng:NextNumber(0.7, 4.2), z), Color3.fromRGB(90, 218, 246), Enum.Material.Glass)
                    if bubble % 3 == 0 then
                        addBall(decorationFolder, "OceanCoral", Vector3.new(3.5, 2.8, 3.5), Vector3.new(x + 3, 1.1, z), Color3.fromRGB(80, 149, 155), Enum.Material.Slate)
                    end
                end
            elseif biome.Id == "Volcano" then
                for rift = 1, 5 do
                    local x = biome.CenterX + rng:NextNumber(-48, 48)
                    local z = (rift % 2 == 0 and 1 or -1) * rng:NextNumber(36, 62)
                    local lava = createPart(decorationFolder, "LavaRift", Vector3.new(rng:NextNumber(7, 16), 0.18, rng:NextNumber(1.2, 2.6)), CFrame.new(x, 0.06, z) * CFrame.Angles(0, math.rad(rng:NextInteger(-35, 35)), 0), Color3.fromRGB(255, 91, 40), Enum.Material.Neon, nil, false)
                    lava.Transparency = 0.08
                end
            end
    
            for index = 1, 12 do
                local x = biome.CenterX + rng:NextNumber(-62, 62)
                local z = rng:NextNumber(-76, 76)
                if math.abs(z) > 32 and math.abs(x - biome.CenterX) > 15 then
                    if index % 3 == 0 then
                        local rockSize = rng:NextNumber(2.2, 5.2)
                        addBall(decorationFolder, biome.Id .. "Rock", Vector3.new(rockSize * 1.4, rockSize, rockSize), Vector3.new(x, rockSize * 0.35, z), biome.Id == "Frost" and Color3.fromRGB(185, 215, 236) or Color3.fromRGB(101, 111, 98), biome.Id == "Frost" and Enum.Material.Ice or Enum.Material.Rock)
                    elseif index % 3 == 1 then
                        buildTree(decorationFolder, Vector3.new(x, 0, z), biome, index)
                    else
                        local flowerColor = index % 2 == 0 and biome.Accent or Color3.fromRGB(255, 154, 186)
                        addBall(decorationFolder, biome.Id .. "Flower", Vector3.new(1.2, 1.2, 1.2), Vector3.new(x, 0.8, z), flowerColor, Enum.Material.Neon)
                        addCylinder(decorationFolder, biome.Id .. "FlowerStem", Vector3.new(0.25, 1.4, 0.25), CFrame.new(x, 0.25, z), Color3.fromRGB(64, 137, 73), Enum.Material.Grass, false)
                    end
                end
            end
            for index = 1, 4 do
                local crystal = addCylinder(decorationFolder, biome.Id .. "Crystal", Vector3.new(2, rng:NextNumber(4, 8), 2), CFrame.new(biome.CenterX + rng:NextNumber(-42, 42), 2.4, (index % 2 == 0 and 1 or -1) * rng:NextNumber(34, 60)) * CFrame.Angles(0, 0, math.rad(rng:NextInteger(-12, 12))), biome.Accent, Enum.Material.Neon, false)
                crystal.Transparency = 0.12
            end
        end
    end

    return {
        CreatePart = createPart,
        AddBall = addBall,
        AddCylinder = addCylinder,
        AddLabel = addLabel,
        CreateTreadmill = createTreadmill,
        CreateBase = createBase,
        BuildScenery = buildScenery,
    }
end

return WorldBuilder
