--!strict

local Navigation = require(script.Parent.Navigation)

local EnemyBrain = {}
EnemyBrain.__index = EnemyBrain

function EnemyBrain.new(model: Model, humanoid: Humanoid, root: BasePart, definition, callbacks)
    return setmetatable({
        model = model,
        humanoid = humanoid,
        root = root,
        definition = definition,
        callbacks = callbacks or {},
        running = false,
        state = "Idle",
        target = nil,
        nextAttackAt = 0,
        nextTargetScanAt = 0,
        memory = nil,
        profile = nil,
        navigation = Navigation.new(root),
    }, EnemyBrain)
end

function EnemyBrain:SetMemory(memory)
    self.memory = memory
end

function EnemyBrain:SetWaveProfile(profile)
    self.profile = profile
end

function EnemyBrain:IsAlive()
    return self.running
        and self.model.Parent ~= nil
        and self.humanoid.Parent ~= nil
        and self.humanoid.Health > 0
        and self.root.Parent ~= nil
end

function EnemyBrain:SetState(nextState: string)
    if self.state == nextState then
        return
    end

    self.state = nextState
    self.model:SetAttribute("CBS_AIState", nextState)
end

function EnemyBrain:FindTarget(candidates)
    local profile = self.profile or {
        Skill = 0.25,
        PredictionTime = 0.05,
        TargetStickiness = 0.08,
    }

    local memory = self.memory
    local best = nil
    local bestScore = -math.huge

    for _, candidate in ipairs(candidates or {}) do
        local player = candidate.player
        local humanoid = candidate.humanoid
        local root = candidate.root

        if player and humanoid and root
            and root:IsA("BasePart")
            and humanoid.Health > 0
            and player.Parent then

            local offset = root.Position - self.root.Position
            local distance = offset.Magnitude

            if distance <= 220 then
                local predictedPosition = root.Position
                    + root.AssemblyLinearVelocity * profile.PredictionTime

                local predictedDistance = (predictedPosition - self.root.Position).Magnitude
                local score = -predictedDistance

                if memory and memory.lastTargetUserId == player.UserId then
                    score += 8 + profile.TargetStickiness * 18
                end

                if distance <= self.definition.AttackRange then
                    score += 12 + profile.Skill * 14
                end

                if distance <= 16 then
                    score += profile.Skill * 8
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

function EnemyBrain:MoveToward(position: Vector3)
    local offset = position - self.root.Position
    local horizontal = Vector3.new(offset.X, 0, offset.Z)

    if horizontal.Magnitude < 0.1 then
        local current = self.root.AssemblyLinearVelocity
        self.root.AssemblyLinearVelocity = Vector3.new(
            current.X * 0.35,
            current.Y,
            current.Z * 0.35
        )
        return
    end

    local direction = horizontal.Unit
    local velocity = direction * self.definition.Speed
    local vertical = math.clamp(self.root.AssemblyLinearVelocity.Y, -45, 20)

    self.root.CFrame = CFrame.lookAt(
        self.root.Position,
        self.root.Position + direction
    )

    self.root.AssemblyLinearVelocity = Vector3.new(
        velocity.X,
        vertical,
        velocity.Z
    )
end

function EnemyBrain:MoveToTarget(targetRoot: BasePart, now: number)
    local profile = self.profile or {
        PredictionTime = 0.05,
    }

    local predicted = targetRoot.Position
        + targetRoot.AssemblyLinearVelocity * profile.PredictionTime

    local offset = predicted - self.root.Position
    if offset.Magnitude <= self.definition.AttackRange then
        local current = self.root.AssemblyLinearVelocity
        self.root.AssemblyLinearVelocity = Vector3.new(
            current.X * 0.35,
            current.Y,
            current.Z * 0.35
        )
        return
    end

    local destination = self.navigation:GetNextPosition(predicted, now)
    self:MoveToward(destination)
end

function EnemyBrain:TryAttack(candidate, now: number)
    if now < self.nextAttackAt then
        return {
            attack = false,
            hit = false,
        }
    end

    local player = candidate and candidate.player
    local targetRoot = candidate and candidate.root

    if not player or not targetRoot or not targetRoot:IsA("BasePart") then
        return {
            attack = false,
            hit = false,
        }
    end

    local distance = (targetRoot.Position - self.root.Position).Magnitude
    if distance > self.definition.AttackRange + 0.75 then
        return {
            attack = false,
            hit = false,
        }
    end

    self.nextAttackAt = now + self.definition.AttackCooldown

    local hit = false
    if type(self.callbacks.damagePlayer) == "function" then
        hit = self.callbacks.damagePlayer(
            player,
            self.definition.Damage,
            self.model
        ) == true
    end

    self:SetState(hit and "Attack" or "AttackMiss")

    return {
        attack = true,
        hit = hit,
        targetUserId = player.UserId,
    }
end

function EnemyBrain:Step(now: number, candidates, profile)
    if profile then
        self.profile = profile
    end

    if not self:IsAlive() then
        return nil
    end

    profile = self.profile or {
        Skill = 0.25,
        ReactionInterval = 0.28,
    }

    if now >= self.nextTargetScanAt then
        self.nextTargetScanAt = now + math.max(
            0.22,
            profile.TargetRefreshInterval or 0.35
        )
        self.target = self:FindTarget(candidates)
    elseif self.target then
        local root = self.target.root
        local humanoid = self.target.humanoid

        if not root
            or not root.Parent
            or not humanoid
            or humanoid.Health <= 0 then
            self.target = nil
        end
    end

    local target = self.target
    if not target or not target.root then
        self:SetState("Idle")
        local current = self.root.AssemblyLinearVelocity
        self.root.AssemblyLinearVelocity = Vector3.new(
            current.X * 0.35,
            current.Y,
            current.Z * 0.35
        )
        return nil
    end

    local targetRoot = target.root
    local distance = (targetRoot.Position - self.root.Position).Magnitude

    if distance <= self.definition.AttackRange + 0.75 then
        self:SetState("Engage")
        return self:TryAttack(target, now)
    end

    self:SetState("Chase")

    if profile.Skill >= 0.48 and distance <= 32 then
        local lead = targetRoot.AssemblyLinearVelocity
        local prediction = math.min(
            0.35,
            profile.PredictionTime or 0.05
        )

        local destination = targetRoot.Position + lead * prediction
        local waypoint = self.navigation:GetNextPosition(destination, now)
        self:MoveToward(waypoint)
    else
        self:MoveToTarget(targetRoot, now)
    end

    return {
        attack = false,
        hit = false,
        targetUserId = target.player and target.player.UserId or nil,
    }
end

function EnemyBrain:Start()
    self.running = true
    self:SetState("Idle")
end

function EnemyBrain:Reset()
    self.target = nil
    self.nextAttackAt = 0
    self.nextTargetScanAt = 0
    self:SetState("Idle")

    if self.navigation then
        self.navigation:Destroy()
    end

    self.navigation = Navigation.new(self.root)
end

function EnemyBrain:Stop()
    self.running = false

    if self.navigation then
        self.navigation:Destroy()
    end
end

return EnemyBrain
