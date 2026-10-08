--!strict

local Agent = {}
Agent.__index = Agent

function Agent.new(model: Model, humanoid: Humanoid, root: BasePart, definition, callbacks, memory)
    return setmetatable({
        model = model,
        humanoid = humanoid,
        root = root,
        definition = definition,
        callbacks = callbacks,
        memory = memory,
        target = nil,
        nextAttack = 0,
        alive = true,
    }, Agent)
end

function Agent:SetProfile(profile)
    self.profile = profile
end

function Agent:SetWave(wave: number)
    self.memory.wave = wave
end

function Agent:Reset()
    self.target = nil
    self.nextAttack = 0
    self.alive = true
end

function Agent:IsAlive()
    return self.model.Parent ~= nil
        and self.humanoid.Parent ~= nil
        and self.humanoid.Health > 0
        and self.root.Parent ~= nil
end

function Agent:ChooseTarget(candidates)
    local profile = self.profile
    local best = nil
    local bestScore = -math.huge

    for _, candidate in ipairs(candidates) do
        local player = candidate.player
        local humanoid = candidate.humanoid
        local root = candidate.root

        if player.Parent
            and player:GetAttribute("CBS_PvP") ~= true
            and humanoid.Health > 0
            and root.Parent then

            local predicted = root.Position + root.AssemblyLinearVelocity * profile.Prediction
            local distance = (predicted - self.root.Position).Magnitude

            if distance <= 220 then
                local score = -distance
                if self.memory.lastTarget == player.UserId then
                    score += 8 + profile.Stickiness * 20
                end
                if distance <= self.definition.Range then
                    score += 12 + profile.Skill * 10
                end

                if score > bestScore then
                    bestScore = score
                    best = candidate
                end
            end
        end
    end

    return best
end

function Agent:Step(now: number, candidates)
    if not self:IsAlive() then
        self.alive = false
        return false
    end

    local profile = self.profile
    if now >= (self.nextTargetAt or 0) then
        self.nextTargetAt = now + math.max(0.22, profile.TargetRefresh)
        self.target = self:ChooseTarget(candidates)
    elseif self.target then
        if not self.target.root.Parent
            or self.target.humanoid.Health <= 0
            or self.target.player.Parent == nil
            or self.target.player:GetAttribute("CBS_PvP") == true then
            self.target = nil
        end
    end

    if not self.target then
        self.model:SetAttribute("CBS_AIState", "Idle")
        return true
    end

    local targetRoot = self.target.root
    local delta = targetRoot.Position - self.root.Position
    local distance = delta.Magnitude

    if distance <= self.definition.Range + 0.8 then
        self.model:SetAttribute("CBS_AIState", "Attack")
        if now >= self.nextAttack then
            self.nextAttack = now + self.definition.Cooldown
            local hit = false
            if self.callbacks and self.callbacks.damagePlayer then
                hit = self.callbacks.damagePlayer(
                    self.target.player,
                    self.definition.Damage,
                    self.model
                ) == true
            end

            self.memory.attacks += 1
            if hit then
                self.memory.hits += 1
            else
                self.memory.misses += 1
            end

            self.memory.confidence = math.clamp(
                self.memory.confidence + (hit and 0.01 or -0.004),
                0.2,
                0.95
            )

            self.memory.lastTarget = self.target.player.UserId
        end
        return true
    end

    self.model:SetAttribute("CBS_AIState", "Chase")

    local predicted = targetRoot.Position
        + targetRoot.AssemblyLinearVelocity * profile.Prediction

    local offset = predicted - self.root.Position
    if offset.Magnitude > 0.1 then
        local direction = Vector3.new(offset.X, 0, offset.Z)
        if direction.Magnitude > 0.1 then
            direction = direction.Unit
            self.root.AssemblyLinearVelocity = Vector3.new(
                direction.X * self.definition.Speed,
                math.clamp(self.root.AssemblyLinearVelocity.Y, -30, 20),
                direction.Z * self.definition.Speed
            )
            self.root.CFrame = CFrame.lookAt(
                self.root.Position,
                self.root.Position + direction
            )
        end
    end

    return true
end

function Agent:Stop()
    self.alive = false
    self.target = nil
end

return Agent
