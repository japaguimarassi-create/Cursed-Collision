--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Service = {}

local Config
local DataService
local AntiCheat
local State: RemoteEvent
local Action: RemoteEvent
local FX: RemoteEvent

local attackAt: {[Player]: number} = {}
local dashAt: {[Player]: number} = {}
local combo: {[Player]: {Count: number, LastAt: number}} = {}

local function characterParts(player: Player)
    local character = player.Character
    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
        return nil
    end

    return character, humanoid, root
end

local function combatAllowed(player: Player): boolean
    return player:GetAttribute("DataReady") == true
        and player:GetAttribute("AdminFrozen") ~= true
        and player.Character ~= nil
end

local function targetAllowed(attacker: Player, model: Model): boolean
    local targetPlayer = Players:GetPlayerFromCharacter(model)
    if targetPlayer then
        return targetPlayer ~= attacker
            and attacker:GetAttribute("Zone") == "PvP"
            and targetPlayer:GetAttribute("Zone") == "PvP"
    end
    return model:GetAttribute("Enemy") == true
        and attacker:GetAttribute("Zone") ~= "PvP"
end

local function findTarget(attacker: Player, character: Model, center: CFrame, size: Vector3): Model?
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.MaxParts = 120
    params.RespectCanCollide = false

    local best: Model?
    local bestDistance = math.huge
    local forward = center.LookVector

    for _, part in ipairs(workspace:GetPartBoundsInBox(center, size, params)) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= character and targetAllowed(attacker, model) then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
                local offset = root.Position - center.Position
                local distance = offset.Magnitude
                local facing = distance > 0.05 and forward:Dot(offset.Unit) or 1
                if facing >= 0.1 and distance < bestDistance then
                    best = model
                    bestDistance = distance
                end
            end
        end
    end

    return best
end

local function applyHit(attacker: Player, target: Model, comboIndex: number): boolean
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    local attackerRoot = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0
        or not targetRoot or not targetRoot:IsA("BasePart")
        or not attackerRoot or not attackerRoot:IsA("BasePart") then
        return false
    end

    local stats = DataService:GetCombatStats(attacker)
    if not stats then
        return false
    end

    local base = Config.Combat.M1.BaseDamage * (1 + (comboIndex - 1) * 0.08)
    if comboIndex == 4 then
        base *= 1.32
    end

    local damage = base * stats.Damage
    humanoid:SetAttribute("LastAttackerUserId", attacker.UserId)
    humanoid:SetAttribute("LastAttackerAt", workspace:GetServerTimeNow())
    humanoid:TakeDamage(damage)

    local delta = targetRoot.Position - attackerRoot.Position
    local horizontal = if delta.Magnitude > 0.05
        then Vector3.new(delta.X, 0, delta.Z).Unit
        else Vector3.new(attackerRoot.CFrame.LookVector.X, 0, attackerRoot.CFrame.LookVector.Z).Unit

    local knockback = if comboIndex == 4
        then Config.Combat.M1.FinisherKnockback
        else Config.Combat.M1.Knockback

    targetRoot.AssemblyLinearVelocity = horizontal * knockback + Vector3.new(0, if comboIndex == 4 then 18 else 5, 0)
    target:SetAttribute("CBS_StunnedUntil", os.clock() + if comboIndex == 4 then 0.34 else 0.18)

    local oldSpeed = humanoid.WalkSpeed
    if oldSpeed > 0 then
        humanoid.WalkSpeed = math.min(oldSpeed, 7)
        task.delay(if comboIndex == 4 then 0.34 else 0.18, function()
            if humanoid.Parent and humanoid.Health > 0 and (target:GetAttribute("CBS_StunnedUntil") or 0) <= os.clock() then
                humanoid.WalkSpeed = oldSpeed
            end
        end)
    end

    FX:FireAllClients("Hit", targetRoot.Position, damage)
    return true
end

local function attack(player: Player)
    local now = os.clock()
    if not combatAllowed(player) then
        return
    end

    local last = attackAt[player] or 0
    if now - last < Config.Combat.M1.Cooldown then
        return
    end

    local character, _, root = characterParts(player)
    if not character or not root then
        return
    end

    attackAt[player] = now

    local sequence = combo[player] or {Count = 0, LastAt = 0}
    if now - sequence.LastAt > Config.Combat.M1.ComboReset then
        sequence.Count = 0
    end

    sequence.Count = sequence.Count % 4 + 1
    sequence.LastAt = now
    combo[player] = sequence

    local center = root.CFrame * CFrame.new(0, 0, -Config.Combat.M1.Range * 0.52)
    local target = findTarget(player, character, center, Config.Combat.M1.BoxSize)

    FX:FireAllClients("M1", center.Position, sequence.Count)

    if not target then
        State:FireClient(player, "Attack", 0, sequence.Count, false)
        return
    end

    local didHit = applyHit(player, target, sequence.Count)
    State:FireClient(player, "Attack", didHit and 1 or 0, sequence.Count, didHit)
end

local function dash(player: Player, requestedDirection: Vector3?)
    local now = os.clock()
    if not combatAllowed(player) then
        return
    end

    if now - (dashAt[player] or 0) < Config.Combat.Dash.Cooldown then
        return
    end

    local character, humanoid, root = characterParts(player)
    if not character or not humanoid or not root then
        return
    end

    local direction = requestedDirection
    if typeof(direction) ~= "Vector3" then
        direction = humanoid.MoveDirection
    end

    if not direction or typeof(direction) ~= "Vector3" then
        return
    end

    direction = Vector3.new(direction.X, 0, direction.Z)
    if direction.Magnitude < 0.1 then
        direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    end

    if direction.Magnitude < 0.1 then
        return
    end

    direction = direction.Unit

    local distance = Config.Combat.Dash.Distance
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.RespectCanCollide = true
    params.IgnoreWater = true

    local hit = workspace:Raycast(root.Position, direction * distance, params)
    local available = distance

    if hit then
        available = math.max(3, math.min(distance, (hit.Position - root.Position).Magnitude - 2.5))
    end

    dashAt[player] = now
    player:SetAttribute("ServerTeleportAt", now)

    local attachment = root:FindFirstChild("CBS_DashAttachment")
    if not attachment then
        local newAttachment = Instance.new("Attachment")
        newAttachment.Name = "CBS_DashAttachment"
        newAttachment.Parent = root
        attachment = newAttachment
    end

    local mover = root:FindFirstChild("CBS_DashVelocity")
    if mover then
        mover:Destroy()
    end

    local velocity = Instance.new("LinearVelocity")
    velocity.Name = "CBS_DashVelocity"
    velocity.Attachment0 = attachment :: Attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.MaxForce = math.huge
    velocity.VectorVelocity = direction * math.min(
        Config.Combat.Dash.Speed,
        math.max(28, available / math.max(0.05, Config.Combat.Dash.Duration))
    )
    velocity.Parent = root
    Debris:AddItem(velocity, Config.Combat.Dash.Duration)

    root.AssemblyLinearVelocity = Vector3.new(
        velocity.VectorVelocity.X,
        root.AssemblyLinearVelocity.Y,
        velocity.VectorVelocity.Z
    )

    FX:FireAllClients("Dash", root.Position, direction)
    State:FireClient(player, "Dash", Config.Combat.Dash.Cooldown, available)

    task.delay(Config.Combat.Dash.Duration, function()
        if root.Parent and humanoid.Health > 0 then
            local current = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(0, current.Y, 0)
        end
    end)
end

function Service:Init(config, dataService, antiCheat)
    Config = config
    DataService = dataService
    AntiCheat = antiCheat

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    Action = remotes:WaitForChild("Action") :: RemoteEvent
    State = remotes:WaitForChild("State") :: RemoteEvent
    FX = remotes:WaitForChild("FX") :: RemoteEvent

    Action.OnServerEvent:Connect(function(player, action: string, direction)
        if not AntiCheat:ValidateAction(player, action) then
            return
        end

        if action == "M1" then
            attack(player)
        elseif action == "Dash" then
            dash(player, direction)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        attackAt[player] = nil
        dashAt[player] = nil
        combo[player] = nil
    end)
end

return Service
