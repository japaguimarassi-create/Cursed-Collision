--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Service = {}

local Config
local DataService
local State: RemoteEvent
local Action: RemoteEvent
local FX: RemoteEvent

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

local function nearestEnemy(character: Model, center: CFrame, size: Vector3): Model?
    local params = OverlapParams.new()
    params.ExcludeInstances = {character}
    params.MaxParts = 80

    local candidate: Model?
    local distance = math.huge

    for _, part in ipairs(workspace:GetPartBoundsInBox(center, size, params)) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model:GetAttribute("Enemy") == true and model.PrimaryPart then
            local d = (model.PrimaryPart.Position - center.Position).Magnitude
            if d < distance then
                distance = d
                candidate = model
            end
        end
    end

    return candidate
end

local function attack(player: Player)
    local current = os.clock()
    if current - (lastAttack[player] or 0) < Config.Combat.M1.Cooldown then
        return
    end

    local character, _, root = getCharacter(player)
    if not character then
        return
    end

    if player:GetAttribute("DataReady") ~= true then
        return
    end

    lastAttack[player] = current

    local center = root.CFrame * CFrame.new(0, 0, -Config.Combat.M1.Range / 2)
    local enemy = nearestEnemy(character, center, Config.Combat.M1.BoxSize)
    if not enemy then
        FX:FireAllClients("Swing", center.Position)
        return
    end

    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    local stats = DataService:GetCombatStats(player)
    if not stats then
        return
    end

    local damage = Config.Combat.M1.BaseDamage * stats.Damage
    humanoid:SetAttribute("LastAttackerUserId", player.UserId)
    humanoid:SetAttribute("LastAttackerAt", workspace:GetServerTimeNow())
    humanoid:TakeDamage(damage)

    FX:FireAllClients("Hit", enemy:GetPivot().Position, damage)
    State:FireClient(player, "Attack", damage)
end

local function dash(player: Player)
    local current = os.clock()
    if current - (lastDash[player] or 0) < Config.Combat.Dash.Cooldown then
        return
    end

    local character, humanoid, root = getCharacter(player)
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

function Service:Init(config, dataService)
    Config = config
    DataService = dataService

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    Action = remotes:WaitForChild("Action") :: RemoteEvent
    State = remotes:WaitForChild("State") :: RemoteEvent
    FX = remotes:WaitForChild("FX") :: RemoteEvent

    Action.OnServerEvent:Connect(function(player, action: string)
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
