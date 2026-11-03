local GuardianAI = {}

function GuardianAI.new(options)
    local Model = options.Model
    local Home = options.Home
    local Biome = options.Biome
    local Config = options.Config
    local Players = options.Players
    local ClearCarry = options.ClearCarry
    local Notify = options.Notify

    local self = { TargetPlayers = {}, Active = false, Accumulator = 0 }

    local function setDormant()
        self.Active = false
        self.Accumulator = 0
        table.clear(self.TargetPlayers)
        if Model and Model.Parent then
            Model:PivotTo(Home)
            Model:SetAttribute("GuardianAIActive", false)
            Model:SetAttribute("GuardianBrainState", "Dormant")
            Model:SetAttribute("AnimationState", "Rest")
        end
    end

    function self:Activate(player)
        if not player or player.Parent ~= Players or not Model or not Model.Parent then return false end
        self.TargetPlayers[player] = true
        self.Active = true
        Model:SetAttribute("GuardianAIActive", true)
        Model:SetAttribute("GuardianBrainState", "Pursuit")
        Model:SetAttribute("AnimationState", "Run")
        return true
    end

    function self:Deactivate(player)
        if player then
            self.TargetPlayers[player] = nil
        else
            table.clear(self.TargetPlayers)
        end
        if next(self.TargetPlayers) == nil then setDormant() end
    end

    function self:IsActive()
        return self.Active
    end

    function self:Step(deltaTime, carried)
        if not self.Active then return end
        if not Model or not Model.Parent or not Model.PrimaryPart then
            setDormant()
            return
        end

        self.Accumulator += math.clamp(tonumber(deltaTime) or 0, 0, 0.1)
        if self.Accumulator < Config.GuardianThinkSeconds then return end
        local stepTime = self.Accumulator
        self.Accumulator = 0

        local targetRoot
        local targetPlayer
        local nearest = Config.GuardianNoticeDistance
        for player in pairs(self.TargetPlayers) do
            local carry = carried[player]
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if player.Parent ~= Players or not carry or not carry.Spec or carry.Spec.Biome ~= Biome.Id
                or not root or not humanoid or humanoid.Health <= 0 then
                self.TargetPlayers[player] = nil
            else
                local distance = (root.Position - Model.PrimaryPart.Position).Magnitude
                if distance < nearest then
                    nearest = distance
                    targetRoot = root
                    targetPlayer = player
                end
            end
        end

        if not targetRoot or not targetPlayer then
            if next(self.TargetPlayers) == nil then setDormant() end
            return
        end

        if nearest <= Config.GuardianCatchDistance then
            self.TargetPlayers[targetPlayer] = nil
            ClearCarry(targetPlayer)
            Notify(targetPlayer, "O guardião alcançou você! O animal escapou.", "Error")
            if next(self.TargetPlayers) == nil then setDormant() end
            return
        end

        local current = Model:GetPivot()
        local destination = Vector3.new(targetRoot.Position.X, current.Position.Y, targetRoot.Position.Z)
        local direction = destination - current.Position
        if direction.Magnitude > 0.1 then
            local movement = math.min(direction.Magnitude, (options.Speed or Config.GuardianSpeed) * stepTime)
            Model:PivotTo(CFrame.lookAt(current.Position + direction.Unit * movement, destination))
        end
        Model:SetAttribute("GuardianBrainState", "Pursuit")
        Model:SetAttribute("AnimationState", "Run")
    end

    function self:Destroy()
        setDormant()
    end

    setDormant()
    return self
end

return GuardianAI
