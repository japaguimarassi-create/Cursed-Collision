--!strict

local Players = game:GetService("Players")
local Navigation = require(script.Parent.Navigation)

local EnemyBrain = {}
EnemyBrain.__index = EnemyBrain

function EnemyBrain.new(model: Model, humanoid: Humanoid, root: BasePart, definition, damageCallback)
    return setmetatable({
        model = model,
        humanoid = humanoid,
        root = root,
        definition = definition,
        damageCallback = damageCallback,
        running = false,
        nextAttackAt = 0,
        navigation = Navigation.new(root),
    }, EnemyBrain)
end

function EnemyBrain:FindTarget()
    local closestPlayer = nil
    local closestRoot = nil
    local closestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local playerHumanoid = character:FindFirstChildOfClass("Humanoid")
            local playerRoot = character:FindFirstChild("HumanoidRootPart")

            if playerHumanoid and playerRoot and playerHumanoid.Health > 0 and playerRoot:IsA("BasePart") then
                local distance = (playerRoot.Position - self.root.Position).Magnitude
                if distance < closestDistance then
                    closestPlayer = player
                    closestRoot = playerRoot
                    closestDistance = distance
                end
            end
        end
    end

    return closestPlayer, closestRoot, closestDistance
end

function EnemyBrain:MoveToward(targetRoot: BasePart, distance: number)
    if distance <= self.definition.AttackRange then
        local current = self.root.AssemblyLinearVelocity
        self.root.AssemblyLinearVelocity = Vector3.new(current.X * 0.35, current.Y, current.Z * 0.35)
        return
    end

    local destination = self.navigation:GetNextPosition(targetRoot.Position, os.clock())
    local offset = destination - self.root.Position
    local horizontal = Vector3.new(offset.X, 0, offset.Z)

    if horizontal.Magnitude < 0.1 then
        return
    end

    local direction = horizontal.Unit
    local desiredVelocity = direction * self.definition.Speed
    local currentVertical = math.clamp(self.root.AssemblyLinearVelocity.Y, -45, 20)

    self.root.CFrame = CFrame.lookAt(
        self.root.Position,
        self.root.Position + direction
    )

    self.root.AssemblyLinearVelocity = Vector3.new(
        desiredVelocity.X,
        currentVertical,
        desiredVelocity.Z
    )
end

function EnemyBrain:Start()
    if self.running then
        return
    end

    self.running = true

    task.spawn(function()
        while self.running and self.model.Parent and self.humanoid.Health > 0 do
            local player, targetRoot, distance = self:FindTarget()

            if player and targetRoot then
                self:MoveToward(targetRoot, distance)

                local now = os.clock()
                if distance <= self.definition.AttackRange and now >= self.nextAttackAt then
                    self.nextAttackAt = now + self.definition.AttackCooldown
                    self.damageCallback(player, self.definition.Damage, self.model)
                end
            else
                local current = self.root.AssemblyLinearVelocity
                self.root.AssemblyLinearVelocity = Vector3.new(current.X * 0.35, current.Y, current.Z * 0.35)
            end

            task.wait(0.2)
        end

        self.running = false
    end)
end

function EnemyBrain:Stop()
    self.running = false
    self.navigation:Destroy()
end

return EnemyBrain
