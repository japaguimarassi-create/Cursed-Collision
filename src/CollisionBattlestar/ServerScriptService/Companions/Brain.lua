--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classes = require(ReplicatedStorage.Shared.CompanionDefinitions)
local Rules = require(ReplicatedStorage.Shared.CompanionRules)
local Navigation = require(script.Parent.Parent.Enemies.Navigation)

local EchoBrain = {}
EchoBrain.__index = EchoBrain

local THINK_INTERVAL = 0.25
local FOLLOW_DISTANCE = 7
local LEASH_DISTANCE = 32
local RETREAT_DISTANCE = 38

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

function EchoBrain:FindTarget()
    local ownerAlive, _, ownerRoot = self:IsOwnerAlive()
    if not ownerAlive or not ownerRoot then
        return nil
    end

    local best = nil
    local bestScore = -math.huge

    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("Model") and descendant:GetAttribute("CBS_Enemy") == true then
            local humanoid = descendant:FindFirstChildOfClass("Humanoid")
            local root = descendant:FindFirstChild("HumanoidRootPart")

            if humanoid and root and humanoid.Health > 0 and root:IsA("BasePart") then
                local distance = (root.Position - self.root.Position).Magnitude
                if distance <= 55 then
                    local score = Rules.targetScore(self.classId, {
                        Distance = distance,
                        MaxHealth = humanoid.MaxHealth,
                        IsElite = descendant:GetAttribute("CBS_Elite") == true,
                        ThreatensOwner = descendant:GetAttribute("CBS_TargetUserId") == self.owner.UserId,
                        NearOwner = (root.Position - ownerRoot.Position).Magnitude <= 9,
                    })

                    if score > bestScore then
                        bestScore = score
                        best = descendant
                    end
                end
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

    if now < self.nextHealAt then
        return false
    end

    if (ownerRoot.Position - self.root.Position).Magnitude > self.class.HealRange then
        self:SetState("Support")
        local destination = ownerRoot.Position - ownerRoot.CFrame.LookVector * self.class.PreferredDistance
        local waypoint = self.navigation:GetNextPosition(destination, now)
        self:MoveToward(waypoint)
        return true
    end

    local levelScale = 1 + (self.level - 1) * 0.04
    local configuredAmount = self.class.HealAmount * levelScale
    local amount = Rules.healAmount(ownerHumanoid.Health, ownerHumanoid.MaxHealth, configuredAmount)

    if amount > 0 then
        ownerHumanoid.Health = math.min(ownerHumanoid.MaxHealth, ownerHumanoid.Health + amount)
        self.nextHealAt = now + self.class.HealCooldown
        self.callbacks.onHeal(self.owner, amount, self.root.Position)
        self:SetState("Support")
        return true
    end

    return false
end

function EchoBrain:MoveToward(position: Vector3)
    local offset = position - self.root.Position
    local horizontal = Vector3.new(offset.X, 0, offset.Z)

    if horizontal.Magnitude < 0.15 then
        return
    end

    local direction = horizontal.Unit
    local speed = self.class.Speed
    local targetVelocity = direction * speed
    local currentY = math.clamp(self.root.AssemblyLinearVelocity.Y, -45, 20)

    self.root.CFrame = CFrame.lookAt(self.root.Position, self.root.Position + direction)
    self.root.AssemblyLinearVelocity = Vector3.new(targetVelocity.X, currentY, targetVelocity.Z)
end

function EchoBrain:MoveAroundOwner(ownerRoot: BasePart)
    local desired = ownerRoot.Position - ownerRoot.CFrame.LookVector * self.class.PreferredDistance
    local waypoint = self.navigation:GetNextPosition(desired, os.clock())
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

    if ok then
        self.nextAttackAt = now + self.class.AttackCooldown
        self:SetState("Attack")
        return true
    end

    return false
end

function EchoBrain:Think()
    local now = os.clock()
    local ownerAlive, ownerHumanoid, ownerRoot = self:IsOwnerAlive()

    if not ownerAlive or not ownerRoot or not ownerHumanoid then
        self:SetState("Retreat")
        return
    end

    local ownerDistance = (ownerRoot.Position - self.root.Position).Magnitude

    if ownerDistance >= RETREAT_DISTANCE then
        self:SetState("Recover")
        self.root.CFrame = ownerRoot.CFrame + ownerRoot.CFrame.LookVector * -FOLLOW_DISTANCE + Vector3.new(0, 1, 0)
        self.navigation:Destroy()
        self.navigation = Navigation.new(self.root)
        return
    end

    if ownerDistance >= LEASH_DISTANCE then
        self:SetState("Retreat")
        self:MoveAroundOwner(ownerRoot)
        return
    end

    if self:TrySupport(ownerHumanoid, ownerRoot, now) then
        return
    end

    local target = self.target

    if not target or not target.Parent or target:GetAttribute("CBS_Enemy") ~= true then
        self:SetState("Acquire")
        target = self:FindTarget()
        self.target = target
    end

    if target then
        local targetRoot = target:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = target:FindFirstChildOfClass("Humanoid")

        if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and targetRoot:IsA("BasePart") then
            local distance = (targetRoot.Position - self.root.Position).Magnitude

            if distance <= self.class.AttackRange then
                self:SetState(self.classId == "Guardian" and "Protect" or "Position")
                self:TryAttack(target, now)
            else
                self:SetState(self.classId == "Guardian" or self.classId == "Vanguard" and "Protect" or "Position")
                local desired = targetRoot.Position - (targetRoot.Position - self.root.Position).Unit * self.class.PreferredDistance
                local waypoint = self.navigation:GetNextPosition(desired, now)
                self:MoveToward(waypoint)
            end

            return
        end

        self.target = nil
    end

    self:SetState("Follow")
    self:MoveAroundOwner(ownerRoot)
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
    self:SetState("Disabled")
    self.model:SetAttribute("CBS_EchoDisabledReason", reason)
    self.running = false
    self.humanoid.Health = math.max(self.humanoid.Health, 1)
    self.humanoid.PlatformStand = true
end

function EchoBrain:Stop()
    self.running = false
    self.navigation:Destroy()
end

return EchoBrain
