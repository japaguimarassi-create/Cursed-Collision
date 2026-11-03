local GuardianController = {}

function GuardianController.new(services)
    local Config = services.Config
    local Players = services.Players
    local Folder = services.Folder
    local GuardianCatalog = services.GuardianCatalog
    local CreateAnimalModel = services.CreateAnimalModel
    local AddLabel = services.AddLabel
    local AddBall = services.AddBall
    local Animator = services.Animator
    local Notify = services.Notify
    local ClearCarry = services.ClearCarry

    local self = {
        Guardians = {},
        Accumulator = 0,
        Spawned = false,
    }

    function self:SpawnAll()
        if self.Spawned then
            return #self.Guardians
        end
        for _, biome in ipairs(Config.Biomes) do
            local spec = GuardianCatalog.Get(biome.Id)
            if spec then
                local side = biome.Phase % 2 == 0 and 1 or -1
                local position = Vector3.new(biome.CenterX - 50, -0.12, side * 23)
                local model = CreateAnimalModel(spec, "Adult", position, true)
                if model and model.PrimaryPart then
                    model.Name = "GuardianParent_" .. biome.Id
                    model:SetAttribute("GuardianBiome", biome.Id)
                    model:SetAttribute("GuardianType", spec.GuardianType)
                    model:SetAttribute("ThreatLevel", biome.Phase)
                    model:SetAttribute("AnimationState", "Rest")
                    model.Parent = Folder

                    local labelPart = model:FindFirstChild("Head")
                        or model:FindFirstChild("SwanHead")
                        or model.PrimaryPart
                    AddLabel(
                        labelPart,
                        "GUARDIÃO: " .. string.upper(spec.Name),
                        "PROTEGE OS OVOS • FASE " .. tostring(biome.Phase),
                        biome.Accent,
                        false,
                        64,
                        1.5
                    )

                    local highlight = Instance.new("Highlight")
                    highlight.Name = "GuardianRim"
                    highlight.Adornee = model
                    highlight.FillColor = biome.Accent
                    highlight.FillTransparency = 0.82
                    highlight.OutlineColor = biome.Accent
                    highlight.OutlineTransparency = 0.08
                    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
                    highlight.Parent = model

                    for shard = 1, 8 do
                        local angle = math.rad(shard * 45)
                        local auraPosition = position + Vector3.new(math.cos(angle) * 10.5, 0.45, math.sin(angle) * 10.5)
                        local aura = AddBall(model, "GuardianAuraShard", Vector3.new(1.1, 0.2, 0.2), auraPosition, biome.Accent, Enum.Material.Neon)
                        aura.CFrame = CFrame.new(auraPosition) * CFrame.Angles(0, -angle, math.rad(25))
                        aura.CanTouch = false
                        aura.CanQuery = false
                        aura.CastShadow = false
                    end

                    AddBall(model, "GuardianCrownGem", Vector3.new(1.9, 1.9, 1.9), position + Vector3.new(0, 16.4, 0), biome.Accent, Enum.Material.Neon)
                    Animator:Register(model, "Rest")
                    table.insert(self.Guardians, {
                        Model = model,
                        Home = CFrame.new(position),
                        Biome = biome,
                        Spec = spec,
                        Speed = math.min(Config.GuardianSpeed + (biome.Phase - 1) * 1.5, Config.GuardianSpeed * 1.8),
                    })
                end
            end
        end
        self.Spawned = true
        return #self.Guardians
    end

    function self:Step(deltaTime, carried)
        self.Accumulator += math.clamp(tonumber(deltaTime) or 0, 0, 0.1)
        if self.Accumulator < Config.GuardianThinkSeconds then
            return
        end
        local stepTime = self.Accumulator
        self.Accumulator = 0

        for _, guardian in ipairs(self.Guardians) do
            local model = guardian.Model
            if model and model.Parent and model.PrimaryPart then
                local targetRoot
                local targetPlayer
                local nearest = Config.GuardianNoticeDistance

                for player in pairs(carried) do
                    if player.Parent == Players then
                        local character = player.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        if root and humanoid and humanoid.Health > 0 then
                            local distance = (root.Position - model.PrimaryPart.Position).Magnitude
                            if distance < nearest then
                                nearest = distance
                                targetRoot = root
                                targetPlayer = player
                            end
                        end
                    end
                end

                if targetRoot and targetPlayer then
                    if nearest <= Config.GuardianCatchDistance then
                        ClearCarry(targetPlayer)
                        Notify(targetPlayer, "O guardião alcançou você! O animal escapou.", "Error")
                        Animator:SetState(model, "Rest")
                    else
                        local current = model:GetPivot()
                        local destination = Vector3.new(targetRoot.Position.X, current.Position.Y, targetRoot.Position.Z)
                        local direction = destination - current.Position
                        if direction.Magnitude > 0.1 then
                            local movement = math.min(direction.Magnitude, (guardian.Speed or Config.GuardianSpeed) * stepTime)
                            local nextPosition = current.Position + direction.Unit * movement
                            model:PivotTo(CFrame.lookAt(nextPosition, destination))
                        end
                        Animator:SetState(model, "Run")
                    end
                else
                    local current = model:GetPivot()
                    local home = guardian.Home.Position
                    local direction = home - current.Position
                    if direction.Magnitude > 1 then
                        local movement = math.min(direction.Magnitude, 7 * stepTime)
                        local nextPosition = current.Position + direction.Unit * movement
                        model:PivotTo(CFrame.lookAt(nextPosition, home))
                        Animator:SetState(model, "Walk")
                    else
                        model:PivotTo(guardian.Home)
                        Animator:SetState(model, "Rest")
                    end
                end
            end
        end
    end

    function self:GetCount()
        return #self.Guardians
    end

    function self:Destroy()
        for _, guardian in ipairs(self.Guardians) do
            if guardian.Model then
                Animator:Remove(guardian.Model)
                guardian.Model:Destroy()
            end
        end
        table.clear(self.Guardians)
        self.Spawned = false
    end

    return self
end

return GuardianController
