local GuardianController = {}

function GuardianController.new(services)
    local Config = services.Config
    local Players = services.Players
    local Folder = services.Folder
    local GuardianCatalog = services.GuardianCatalog
    local GuardianAIFactory = services.GuardianAI
    local CreateAnimalModel = services.CreateAnimalModel
    local AddLabel = services.AddLabel
    local AddBall = services.AddBall

    local self = { Guardians = {}, Spawned = false }

    function self:SpawnAll()
        if self.Spawned then return #self.Guardians end
        for _, biome in ipairs(Config.Biomes) do
            local spec = GuardianCatalog.Get(biome.Id)
            if spec then
                local side = biome.Phase % 2 == 0 and 1 or -1
                local position = Vector3.new(biome.CenterX - 50, -0.12, side * 23)
                local home = CFrame.new(position)
                local model = CreateAnimalModel(spec, "Adult", position, true)
                if model and model.PrimaryPart then
                    model.Name = "GuardianParent_" .. biome.Id
                    model:SetAttribute("GuardianBiome", biome.Id)
                    model:SetAttribute("GuardianType", spec.GuardianType)
                    model:SetAttribute("ThreatLevel", biome.Phase)
                    model:SetAttribute("GuardianAIActive", false)
                    model:SetAttribute("GuardianBrainState", "Dormant")
                    model:SetAttribute("AnimationState", "Rest")
                    model.Parent = Folder

                    local labelPart = model:FindFirstChild("Head") or model:FindFirstChild("SwanHead") or model.PrimaryPart
                    AddLabel(labelPart, "GUARDIÃO: " .. string.upper(spec.Name), "IA DORMENTE • ATIVA APÓS ROUBO • FASE " .. tostring(biome.Phase), biome.Accent, false, 64, 1.5)

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

                    local brain = GuardianAIFactory.new({
                        Model = model,
                        Home = home,
                        Biome = biome,
                        Config = Config,
                        Players = Players,
                        Speed = math.min(Config.GuardianSpeed + (biome.Phase - 1) * 1.5, Config.GuardianSpeed * 1.8),
                        ClearCarry = services.ClearCarry,
                        Notify = services.Notify,
                    })
                    table.insert(self.Guardians, { Model = model, Home = home, Biome = biome, Spec = spec, Brain = brain })
                end
            end
        end
        self.Spawned = true
        return #self.Guardians
    end

    function self:OnAnimalStolen(player, biomeId)
        if not player or player.Parent ~= Players or not biomeId then return 0 end
        local activated = 0
        for _, guardian in ipairs(self.Guardians) do
            if guardian.Biome.Id == biomeId and guardian.Brain:Activate(player) then activated += 1 end
        end
        return activated
    end

    function self:OnCarryEnded(player)
        if not player then return end
        for _, guardian in ipairs(self.Guardians) do guardian.Brain:Deactivate(player) end
    end

    function self:HasActiveGuardians()
        for _, guardian in ipairs(self.Guardians) do
            if guardian.Brain:IsActive() then return true end
        end
        return false
    end

    function self:Step(deltaTime, carried)
        for _, guardian in ipairs(self.Guardians) do
            if guardian.Brain:IsActive() then guardian.Brain:Step(deltaTime, carried) end
        end
    end

    function self:GetCount()
        return #self.Guardians
    end

    function self:Destroy()
        for _, guardian in ipairs(self.Guardians) do
            guardian.Brain:Destroy()
            if guardian.Model then guardian.Model:Destroy() end
        end
        table.clear(self.Guardians)
        self.Spawned = false
    end

    return self
end

return GuardianController
