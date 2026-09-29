--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Rules = require(Shared:WaitForChild("CombatRules"))
local SecurityRules = require(Shared:WaitForChild("SecurityRules"))

local Service = {}
Service.__index = Service

function Service.new()
    return setmetatable({playerState = nil, security = nil, stateRemote = nil, fxRemote = nil, lastDash = {}}, Service)
end

local function getParts(player: Player)
    local character = player.Character
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
        return character, humanoid, root
    end
end

local function hasLineOfSight(origin: Vector3, target: BasePart, character: Model, enemy: Model): boolean
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.IgnoreWater = true

    local result = workspace:Raycast(origin, target.Position - origin, params)
    if not result then
        return true
    end

    return result.Instance:IsDescendantOf(enemy)
end

local function findEnemy(center: CFrame, size: Vector3, character: Model, origin: Vector3): Model?
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.MaxParts = 100
    params.RespectCanCollide = false

    local best = nil
    local bestDistance = math.huge

    for _, part in ipairs(workspace:GetPartBoundsInBox(center, size, params)) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model:GetAttribute("Enemy") == true then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
                local distance = (root.Position - center.Position).Magnitude
                local visible = hasLineOfSight(origin, root, character, model)
                if SecurityRules.validTarget("Enemy", false)
                    and SecurityRules.validRange(distance, Constants.Combat.M1.Range + 2)
                    and SecurityRules.validLineOfSight(not visible)
                    and distance < bestDistance then
                    best = model
                    bestDistance = distance
                end
            end
        end
    end

    return best
end
function Service:M1(player: Player)
    if not self.security:ValidateAction(player, "M1") then
        return
    end

    local state = self.playerState:Get(player)
    local now = os.clock()
    if not state or not Rules.canAttack(now, state.LastAttackAt, Constants.Combat.M1.MinInterval) then
        return
    end

    local character, _, root = getParts(player)
    if not character or not root then
        return
    end

    state.ComboIndex = Rules.nextCombo(state.ComboIndex, now - state.LastComboAt, Constants.Combat.M1.ComboWindow)
    state.LastComboAt = now
    state.LastAttackAt = now

    local center = root.CFrame * CFrame.new(0, 0, -4)
    local target = findEnemy(center, Constants.Combat.M1.BoxSize, character, root.Position)
    local damage = Constants.Combat.M1.Damages[state.ComboIndex] + self.playerState:GetDamage(player)

    self.fxRemote:FireAllClients("M1", center.Position, state.ComboIndex)

    if not target then
        self.stateRemote:FireClient(player, "Attack", state.ComboIndex, false)
        return
    end

    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if not humanoid or not targetRoot or humanoid.Health <= 0 then
        return
    end

    humanoid:SetAttribute("LastAttackerUserId", player.UserId)
    humanoid:SetAttribute("LastAttackerAt", workspace:GetServerTimeNow())
    humanoid:TakeDamage(damage)

    local delta = targetRoot.Position - root.Position
    local flat = Vector3.new(delta.X, 0, delta.Z)
    local direction = if flat.Magnitude > 0.05
        then flat.Unit
        else Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit

    local knockback = if state.ComboIndex == 3
        then Constants.Combat.M1.FinisherKnockback
        else Constants.Combat.M1.Knockback

    targetRoot.AssemblyLinearVelocity = direction * knockback + Vector3.new(0, if state.ComboIndex == 3 then 14 else 4, 0)
    target:SetAttribute("CBS_StunnedUntil", os.clock() + (if state.ComboIndex == 3 then 0.3 else 0.16))

    self.fxRemote:FireAllClients("Hit", targetRoot.Position, damage)
    self.stateRemote:FireClient(player, "Attack", state.ComboIndex, true)
end

function Service:Dash(player: Player, requestedDirection)
    if not self.security:ValidateAction(player, "Dash") then
        return
    end

    local now = os.clock()
    if not Rules.canDash(now, self.lastDash[player] or 0, Constants.Combat.Dash.Cooldown) then
        return
    end

    local character, humanoid, root = getParts(player)
    if not character or not humanoid or not root then
        return
    end

    local x = 0
    local z = 1
    if typeof(requestedDirection) == "Vector3" then
        x = requestedDirection.X
        z = requestedDirection.Z
    else
        local move = humanoid.MoveDirection
        x = move.X
        z = move.Z
        if math.abs(x) + math.abs(z) < 0.1 then
            x = root.CFrame.LookVector.X
            z = root.CFrame.LookVector.Z
        end
    end

    local direction = Rules.normalizeDirection(x, z)
    self.lastDash[player] = now

    local attachment = root:FindFirstChild("CBS_DashAttachment")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "CBS_DashAttachment"
        attachment.Parent = root
    end

    local previous = root:FindFirstChild("CBS_DashVelocity")
    if previous then
        previous:Destroy()
    end

    local velocity = Instance.new("LinearVelocity")
    velocity.Name = "CBS_DashVelocity"
    velocity.Attachment0 = attachment :: Attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.MaxForce = math.huge
    velocity.VectorVelocity = Vector3.new(direction.x, 0, direction.z) * Constants.Combat.Dash.Speed
    velocity.Parent = root
    Debris:AddItem(velocity, Constants.Combat.Dash.Duration)

    self.fxRemote:FireAllClients("Dash", root.Position, Vector3.new(direction.x, 0, direction.z))
    self.stateRemote:FireClient(player, "Dash", Constants.Combat.Dash.Cooldown)
end

function Service:Init(registry, remotes)
    self.playerState = registry:Get("PlayerState")
    self.security = registry:Get("Security")
    self.stateRemote = remotes.State
    self.fxRemote = remotes.FX

    remotes.Combat.OnServerEvent:Connect(function(player, action, direction)
        if action == "M1" then
            self:M1(player)
        elseif action == "Dash" then
            self:Dash(player, direction)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.lastDash[player] = nil
    end)
end

return Service