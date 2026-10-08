--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classes = require(ReplicatedStorage.Shared.CompanionDefinitions)
local Rules = require(ReplicatedStorage.Shared.CompanionRules)
local Navigation = require(script.Parent.Parent.Enemies.Navigation)

local EchoBrain = {}
EchoBrain.__index = EchoBrain

local THINK_INTERVAL = 0.25
local FOLLOW_DISTANCE = 7
local LEASH_DISTANCE = 32
local RETREAT_DISTANCE = 44

function EchoBrain.new(owner: Player, model: Model, humanoid: Humanoid, root: BasePart, classId: string, level: number, callbacks)
    return setmetatable({
        owner = owner,
        model = model,
        humanoid = humanoid,
        root = root,
        classId = classId,
        class = Classes[classId] or Classes.Vanguard,
        level = math.max(1, math.floor(level)),
        callbacks = callbacks,
        state = "Follow",
        target = nil,
        running = false,
        nextAttackAt = 0,
        nextHealAt = 0,
        nextThinkAt = 0,
        nextTargetScanAt = 0,
        navigation = Navigation.new(root),
    }, EchoBrain)
end

function EchoBrain:SetState(nextState: string)
    if self.state == nextState then
        return
    end

    if Rules.canTransition(self.state, nextState) then
        self.state = nextState
        self.model:SetAttribute("CBS_EchoState", nextState)
    end
end

function EchoBrain:IsOwnerAlive()
    local character = self.owner.Character
    if not character then
        return false, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 or not root:IsA("BasePart") then
        return false, humanoid, nil
    end

    return true, humanoid, root
end

function EchoBrain:FindTarget(ownerRoot: BasePart)
    local candidates = self.callbacks.getTargets(self.root.Position, 55)
    local best = nil
    local bestScore = -math.huge

    for _, candidate in ipairs(candidates) do
        local targetHumanoid = candidate:FindFirstChildOfClass("Humanoid")
        local targetRoot = candidate:FindFirstChild("HumanoidRootPart")

        if targetHumanoid and targetRoot and targetHumanoid.Health > 0 and targetRoot:IsA("BasePart") then
            local distance = (targetRoot.Position - self.root.Position).Magnitude
            local ownerDistance = (targetRoot.Position - ownerRoot.Position).Magnitude

            local score = Rules.targetScore(self.classId, {
                Distance = distance,
                MaxHealth = targetHumanoid.MaxHealth,
                IsElite = candidate:GetAttribute("CBS_Elite") == true,
                ThreatensOwner = candidate:GetAttribute("CBS_TargetUserId") == self.owner.UserId,
                NearOwner = ownerDistance <= 9,
            })

            if score > bestScore then
                bestScore = score
                best = candidate
            end
        end
    end

    return best
end

function EchoBrain:TrySupport(ownerHumanoid: Humanoid, ownerRoot: BasePart, now: number)
    if self.classId ~= "Support" then
        return false
    end

    if ownerHumanoid.Health >= ownerHumanoid.MaxHealth * 0.72 then
        return false
    end

    if (ownerRoot.Position - self.root.Position).Magnitude > self.class.HealRange then
        self:SetState("Support")
        local destination = ownerRoot.Position - ownerRoot.CFrame.LookVector * self.class.PreferredDistance
        local waypoint = self.navigation:GetNextPosition(destination, now)
        self:MoveToward(waypoint)
        return true
    end

    if now < self.nextHealAt then
        return false
    end

    local levelScale = 1 + (self.level - 1) * 0.04
    local amount = Rules.healAmount(
        ownerHumanoid.Health,
        ownerHumanoid.MaxHealth,
        self.class.HealAmount * levelScale
    )

    if amount <= 0 then
        return false
    end

    ownerHumanoid.Health = math.min(ownerHumanoid.MaxHealth, ownerHumanoid.Health + amount)
    self.nextHealAt = now + self.class.HealCooldown
    self.callbacks.onHeal(self.owner, amount, self.root.Position)
    self:SetState("Support")
    return true
end

function EchoBrain:MoveToward(position: Vector3)
    local offset = position - self.root.Position
    local horizontal = Vector3.new(offset.X, 0, offset.Z)

    if horizontal.Magnitude < 0.15 then
        return
    end

    local direction = horizontal.Unit
    local velocity = direction * self.class.Speed
    local currentY = math.clamp(self.root.AssemblyLinearVelocity.Y, -45, 20)

    self.root.CFrame = CFrame.lookAt(self.root.Position, self.root.Position + direction)
    self.root.AssemblyLinearVelocity = Vector3.new(velocity.X, currentY, velocity.Z)
end

function EchoBrain:MoveBehindOwner(ownerRoot: BasePart, now: number)
    local destination = ownerRoot.Position - ownerRoot.CFrame.LookVector * FOLLOW_DISTANCE
    local waypoint = self.navigation:GetNextPosition(destination, now)
    self:MoveToward(waypoint)
end

function EchoBrain:TryAttack(target: Model, now: number)
    if now < self.nextAttackAt then
        return false
    end

    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    local humanoid = target:FindFirstChildOfClass("Humanoid")

    if not targetRoot or not humanoid or not targetRoot:IsA("BasePart") or humanoid.Health <= 0 then
        return false
    end

    local distance = (targetRoot.Position - self.root.Position).Magnitude
    if distance > self.class.AttackRange then
        return false
    end

    local levelScale = 1 + (self.level - 1) * 0.04
    local damage = self.class.Damage * levelScale

    local ok = self.callbacks.onAttack(
        self.owner,
        self.model,
        target,
        damage,
        self.class.AttackRange
    )

    if not ok then
        return false
    end

    self.nextAttackAt = now + self.class.AttackCooldown
    self:SetState("Attack")
    return true
end

function EchoBrain:Think()
    local now = os.clock()
    local ownerAlive, ownerHumanoid, ownerRoot = self:IsOwnerAlive()

    if not ownerAlive or not ownerRoot or not ownerHumanoid then
        self:SetState("Retreat")
        self.target = nil
        return
    end

    if self.owner:GetAttribute("CBS_PvP") == true then
        self:SetState("Disabled")
        self.target = nil
        return
    end

    local ownerDistance = (ownerRoot.Position - self.root.Position).Magnitude

    if ownerDistance >= RETREAT_DISTANCE then
        self:SetState("Retreat")
        self:MoveBehindOwner(ownerRoot, now)
        return
    end

    if ownerDistance >= LEASH_DISTANCE then
        self:SetState("Retreat")
        self:MoveBehindOwner(ownerRoot, now)
        return
    end

    if self:TrySupport(ownerHumanoid, ownerRoot, now) then
        return
    end

    if now >= self.nextTargetScanAt then
        self.nextTargetScanAt = now + 0.5
        self.target = self:FindTarget(ownerRoot)
    end

    local target = self.target

    if target then
        local targetRoot = target:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = target:FindFirstChildOfClass("Humanoid")

        if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and targetRoot:IsA("BasePart") then
            local distance = (targetRoot.Position - self.root.Position).Magnitude

            if distance <= self.class.AttackRange then
                self:SetState(self.classId == "Guardian" and "Protect" or "Position")
                self:TryAttack(target, now)
            else
                local positionState = (self.classId == "Guardian" or self.classId == "Vanguard")
                    and "Protect"
                    or "Position"

                self:SetState(positionState)

                local towardTarget = targetRoot.Position - self.root.Position
                if towardTarget.Magnitude > 0.1 then
                    local desired = targetRoot.Position - towardTarget.Unit * self.class.PreferredDistance
                    local waypoint = self.navigation:GetNextPosition(desired, now)
                    self:MoveToward(waypoint)
                end
            end

            return
        end

        self.target = nil
    end

    self:SetState("Follow")
    self:MoveBehindOwner(ownerRoot, now)
end

function EchoBrain:Start()
    if self.running then
        return
    end

    self.running = true
    self.model:SetAttribute("CBS_EchoState", self.state)

    task.spawn(function()
        while self.running and self.model.Parent and self.owner.Parent do
            local now = os.clock()

            if now >= self.nextThinkAt then
                self.nextThinkAt = now + THINK_INTERVAL
                self:Think()
            end

            task.wait(0.1)
        end

        self.running = false
    end)
end

function EchoBrain:Disable(reason: string)
    self.target = nil
    self:SetState("Disabled")
    self.model:SetAttribute("CBS_EchoDisabledReason", reason)
    self.model:SetAttribute("CBS_EchoDisabled", true)
    self.running = false
    self.humanoid.AssemblyLinearVelocity = Vector3.zero
end

function EchoBrain:Stop()
    self.running = false
    self.navigation:Destroy()
end

return EchoBrain
