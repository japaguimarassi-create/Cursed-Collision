--!strict

local Players = game:GetService("Players")

local EnemyBrain = {}
EnemyBrain.__index = EnemyBrain

local function getRoot(character: Model)
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function getHumanoid(character: Model)
    return character:FindFirstChildOfClass("Humanoid")
end

function EnemyBrain.new(model: Model, humanoid: Humanoid, root: BasePart, definition, damageCallback)
    return setmetatable({
        model = model,
        humanoid = humanoid,
        root = root,
        definition = definition,
        damageCallback = damageCallback,
        running = false,
        nextAttackAt = 0,
    }, EnemyBrain)
end

function EnemyBrain:FindTarget()
    local closestPlayer = nil
    local closestRoot = nil
    local closestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local playerHumanoid = getHumanoid(character)
            local playerRoot = getRoot(character)

            if playerHumanoid and playerRoot and playerHumanoid.Health > 0 then
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

function EnemyBrain:Start()
    if self.running then
        return
    end

    self.running = true

    task.spawn(function()
        while self.running and self.model.Parent and self.humanoid.Health > 0 do
            local player, targetRoot, distance = self:FindTarget()

            if player and targetRoot then
                self.humanoid:MoveTo(targetRoot.Position)

                local now = os.clock()
                if distance <= self.definition.AttackRange and now >= self.nextAttackAt then
                    self.nextAttackAt = now + self.definition.AttackCooldown
                    self.damageCallback(player, self.definition.Damage, self.model)
                end
            end

            task.wait(0.3)
        end

        self.running = false
    end)
end

function EnemyBrain:Stop()
    self.running = false
end

return EnemyBrain
