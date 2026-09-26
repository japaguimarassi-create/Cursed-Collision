--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Service = {}

local Config
local DataService
local State: RemoteEvent
local Action: RemoteEvent
local FX: RemoteEvent
local AntiCheat

local lastAttack: {[Player]: number} = {}
local lastDash: {[Player]: number} = {}

local function getCharacter(player: Player)
    local character = player.Character
    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
        return character, humanoid, root
    end

    return nil
end

local function nearestModel(character: Model, center: CFrame, size: Vector3, predicate): Model?
    local params = OverlapParams.new()
    params.ExcludeInstances = {character}
    params.MaxParts = 80

    local candidate
    local distance = math.huge

    for _, part in ipairs(workspace:GetPartBoundsInBox(center, size, params)) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= character and model.PrimaryPart and predicate(model) then
            local currentDistance = (model.PrimaryPart.Position - center.Position).Magnitude
            if currentDistance < distance then
                distance = currentDistance
                candidate = model
            end
        end
    end

    return candidate
end

local function enemyTarget(character: Model, center: CFrame, size: Vector3)
    return nearestModel(character, center, size, function(model)
        return model:GetAttribute("Enemy") == true
    end)
end

local function playerTarget(attacker: Player, character: Model, center: CFrame, size: Vector3)
    return nearestModel(character, center, size, function(model)
        local targetPlayer = Players:GetPlayerFromCharacter(model)
        return targetPlayer ~= nil
            and targetPlayer ~= attacker
            and targetPlayer:GetAttribute("Zone") == "PvP"
    end)
end

local function attack(player: Player)
    local current = os.clock()
    if current - (lastAttack[player] or 0) < Config.Combat.M1.Cooldown then
        return
    end

    local character, _, root = getCharacter(player)
    if not character or player:GetAttribute("DataReady") ~= true then
        return
    end

    lastAttack[player] = current

    local center = root.CFrame * CFrame.new(0, 0, -Config.Combat.M1.Range / 2)
    local target

    if player:GetAttribute("Zone") == "PvP" then
        target = playerTarget(player, character, center, Config.Combat.M1.BoxSize)
    else
        target = enemyTarget(character, center, Config.Combat.M1.BoxSize)
    end

    if not target then
        FX:FireAllClients("Swing", center.Position, 1)
        return
    end

    local humanoid = target:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    local stats = DataService:GetCombatStats(player)
    if not stats then
        return
    end

    local damage = Config.Combat.M1.BaseDamage * stats.Damage

    if player:GetAttribute("Zone") == "PvP" then
        local targetPlayer = Players:GetPlayerFromCharacter(target)
        if targetPlayer and targetPlayer:GetAttribute("Zone") == "PvP" then
            humanoid:SetAttribute("LastAttackerUserId", player.UserId)
            humanoid:SetAttribute("LastAttackerAt", workspace:GetServerTimeNow())
            humanoid:TakeDamage(damage)

            State:FireClient(player, "PvpHit", damage)
            FX:FireAllClients("Hit", target:GetPivot().Position, damage)
        end
    else
        humanoid:SetAttribute("LastAttackerUserId", player.UserId)
        humanoid:SetAttribute("LastAttackerAt", workspace:GetServerTimeNow())
        humanoid:TakeDamage(damage)

        FX:FireAllClients("Hit", target:GetPivot().Position, damage)
        State:FireClient(player, "Attack", damage)
    end
end

local function dash(player: Player)
    local current = os.clock()
    if current - (lastDash[player] or 0) < Config.Combat.Dash.Cooldown then
        return
    end

    local character, _, root = getCharacter(player)
    if not character then
        return
    end

    local stats = DataService:GetCombatStats(player)
    if not stats then
        return
    end

    lastDash[player] = current

    local distance = Config.Combat.Dash.Distance + stats.SpeedLevel
    local direction = root.CFrame.LookVector * distance

    local params = RaycastParams.new()
    params.ExcludeInstances = {character}
    params.RespectCanCollide = true

    local hit = workspace:Raycast(root.Position, direction, params)
    local destination = root.Position + direction

    if hit then
        destination = hit.Position - root.CFrame.LookVector * 2.5
    end

    root.AssemblyLinearVelocity = Vector3.zero
    character:PivotTo(CFrame.new(destination, destination + root.CFrame.LookVector))
    State:FireClient(player, "Dash", Config.Combat.Dash.Cooldown)
end

function Service:Init(config, dataService, antiCheat)
    Config = config
    DataService = dataService
    AntiCheat = antiCheat

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    Action = remotes:WaitForChild("Action") :: RemoteEvent
    State = remotes:WaitForChild("State") :: RemoteEvent
    FX = remotes:WaitForChild("FX") :: RemoteEvent

    Action.OnServerEvent:Connect(function(player, action: string)
        if not AntiCheat:ValidateAction(player, action) then return end
        if action == "M1" then
            attack(player)
        elseif action == "Dash" then
            dash(player)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        lastAttack[player] = nil
        lastDash[player] = nil
    end)
end

return Service
