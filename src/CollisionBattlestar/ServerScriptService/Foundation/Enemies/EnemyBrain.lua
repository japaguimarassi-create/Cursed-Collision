--!strict

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Navigation = require(script.Parent:WaitForChild("Navigation"))

local Brain = {}

function Brain.new(model: Model, tier: string)
    return {model = model, tier = tier, lastPathAt = 0, waypoint = nil, lastAttackAt = 0}
end

local function findTarget(origin: Vector3): (Player?, Model?, number)
    local bestPlayer = nil
    local bestCharacter = nil
    local bestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("DataReady") == true and player:GetAttribute("Zone") == "PvE" then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
                local distance = (root.Position - origin).Magnitude
                if distance < bestDistance then
                    bestDistance = distance
                    bestPlayer = player
                    bestCharacter = character
                end
            end
        end
    end

    return bestPlayer, bestCharacter, bestDistance
end

function Brain.Update(brain, now: number)
    local model = brain.model
    if not model.Parent then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then
        return
    end

    local targetPlayer, targetCharacter, distance = findTarget(root.Position)
    if not targetPlayer or not targetCharacter then
        humanoid:MoveTo(root.Position)
        return
    end

    local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    local stats = Constants.Enemies[brain.tier]
    if not targetHumanoid or not targetRoot or not stats then
        return
    end

    local stunnedUntil = model:GetAttribute("CBS_StunnedUntil") or 0
    if now < stunnedUntil then
        humanoid:MoveTo(root.Position)
        return
    end

    if distance <= stats.AttackRange then
        humanoid:MoveTo(root.Position)
        if now - brain.lastAttackAt >= stats.AttackCooldown then
            brain.lastAttackAt = now
            targetHumanoid:TakeDamage(stats.Damage)
            targetPlayer:SetAttribute("CombatHealth", targetHumanoid.Health)
        end
        return
    end

    if now - brain.lastPathAt >= Constants.AI.PathRecompute then
        brain.lastPathAt = now
        brain.waypoint = Navigation.NextPoint(root.Position, targetRoot.Position)
    end

    humanoid:MoveTo(brain.waypoint or targetRoot.Position)
end

return Brain