--!strict

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local Service = {}

local Config
local DataService

type ActiveCompanion = {
    Model: Model,
    Key: string,
}

local active: {[Player]: {ActiveCompanion}} = {}
local nextAttack: {[Model]: number} = {}

local function definitionFor(key: string)
    for _, definition in ipairs(Config.Shop.Companions) do
        if definition.Key == key then
            return definition
        end
    end
    return nil
end

local function ownedDefinitions(player: Player)
    local profile = DataService:Get(player)
    if not profile then
        return {}
    end

    local result = {}
    for index, definition in ipairs(Config.Shop.Companions) do
        local amount = profile.Companions[definition.Key] or 0
        if amount > 0 or (definition.Key == "Scout" and player:GetAttribute("Pass_StarterCompanion") == true) then
            table.insert(result, {index = index, definition = definition})
        end
    end

    return result
end

local friendCache: {[Player]: {UserId: number, Username: string, DisplayName: string}} = {}

local function loadFriend(player: Player)
    if friendCache[player] then
        return friendCache[player]
    end

    local ok, pages = pcall(function()
        return Players:GetFriendsAsync(player.UserId)
    end)

    if not ok or not pages then
        return nil
    end

    local friends = {}
    while true do
        local page = pages:GetCurrentPage()
        for _, friend in ipairs(page) do
            if type(friend) == "table" and type(friend.Id) == "number" then
                table.insert(friends, {
                    UserId = friend.Id,
                    Username = tostring(friend.Username or "Friend"),
                    DisplayName = tostring(friend.DisplayName or friend.Username or "Friend"),
                })
            end
        end

        if pages.IsFinished then
            break
        end

        local advanced = pcall(function()
            pages:AdvanceToNextPageAsync()
        end)

        if not advanced then
            break
        end
    end

    if #friends == 0 then
        return nil
    end

    local selected = friends[Random.new(player.UserId):NextInteger(1, #friends)]
    friendCache[player] = selected
    return selected
end

local function createCompanion(player: Player, definition)
    local character = player.Character
    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not playerRoot or not playerRoot:IsA("BasePart") then
        return nil
    end

    local friend = loadFriend(player)
    if not friend then
        return nil
    end

    local ok, model = pcall(function()
        return Players:CreateHumanoidModelFromUserIdAsync(friend.UserId)
    end)

    if not ok or not model then
        return nil
    end

    model.Name = "Companion_" .. definition.Key .. "_" .. friend.Username
    model.Parent = workspace

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or not root:IsA("BasePart") then
        model:Destroy()
        return nil
    end

    model:PivotTo(playerRoot.CFrame * CFrame.new(5, 0, 5))
    model.PrimaryPart = root

    humanoid.MaxHealth = definition.Health
    humanoid.Health = definition.Health
    humanoid.WalkSpeed = definition.Speed
    humanoid.JumpPower = 44
    humanoid.AutoRotate = true
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

    model:SetAttribute("Companion", true)
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("CompanionKey", definition.Key)
    model:SetAttribute("Damage", definition.Damage)
    model:SetAttribute("FriendUserId", friend.UserId)
    model:SetAttribute("FriendUsername", friend.Username)
    model:SetAttribute("FriendDisplayName", friend.DisplayName)

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant:SetNetworkOwner(nil)
        end
    end

    local head = model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "FriendCompanionLabel"
        billboard.Size = UDim2.fromOffset(190, 38)
        billboard.StudsOffset = Vector3.new(0, 3.2, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 70
        billboard.Adornee = head
        billboard.Parent = model

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 10
        label.TextColor3 = Color3.fromRGB(225, 238, 255)
        label.TextStrokeTransparency = 0.5
        label.Text = ("ALLY • %s"):format(friend.DisplayName)
        label.Parent = billboard
    end

    CollectionService:AddTag(model, "CompanionNPC")

    humanoid.Died:Connect(function()
        nextAttack[model] = nil
        task.delay(1, function()
            if model.Parent then
                model:Destroy()
            end
        end)
    end)

    return model
end

local function refresh(player: Player)
    for _, state in ipairs(active[player] or {}) do
        if state.Model.Parent then
            state.Model:Destroy()
        end
    end

    active[player] = {}

    if player:GetAttribute("Zone") == "PvP" then
        return
    end

    local owned = ownedDefinitions(player)
    local slots = if player:GetAttribute("Pass_SecondCompanion") == true then 2 else 1

    local startIndex = math.max(1, #owned - slots + 1)
    for index = #owned, startIndex, -1 do
        local definition = owned[index].definition
        local model = createCompanion(player, definition)
        if model then
            table.insert(active[player], {
                Model = model,
                Key = definition.Key,
            })
        end
    end
end

local function nearestEnemy(position: Vector3, maxDistance: number): Model?
    local best
    local bestDistance = maxDistance

    for _, enemy in ipairs(CollectionService:GetTagged("EnemyNPC")) do
        if enemy:IsA("Model") and enemy.PrimaryPart then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local distance = (enemy.PrimaryPart.Position - position).Magnitude
                if distance < bestDistance then
                    bestDistance = distance
                    best = enemy
                end
            end
        end
    end

    return best
end

local function think(player: Player, state: ActiveCompanion)
    local model = state.Model
    if not model.Parent or not model.PrimaryPart or player:GetAttribute("Zone") == "PvP" then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not playerRoot or not playerRoot:IsA("BasePart") then
        return
    end

    local definition = definitionFor(state.Key)
    if not definition then
        return
    end

    local enemy = nearestEnemy(model.PrimaryPart.Position, definition.AttackRange + 20)
    if enemy and enemy.PrimaryPart then
        local distance = (enemy.PrimaryPart.Position - model.PrimaryPart.Position).Magnitude

        if distance <= definition.AttackRange then
            local nextTime = nextAttack[model] or 0
            if os.clock() >= nextTime then
                local targetHumanoid = enemy:FindFirstChildOfClass("Humanoid")
                if targetHumanoid and targetHumanoid.Health > 0 then
                    targetHumanoid:SetAttribute("LastAttackerUserId", player.UserId)
                    targetHumanoid:SetAttribute("LastAttackerAt", workspace:GetServerTimeNow())
                    targetHumanoid:TakeDamage(definition.Damage)
                    nextAttack[model] = os.clock() + definition.AttackCooldown
                end
            end
            humanoid:MoveTo(model.PrimaryPart.Position)
            return
        end

        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 4,
        })

        local success = pcall(function()
            path:ComputeAsync(model.PrimaryPart.Position, enemy.PrimaryPart.Position)
        end)

        if success and path.Status == Enum.PathStatus.Success then
            local points = path:GetWaypoints()
            local point = points[math.min(2, #points)]
            if point then
                if point.Action == Enum.PathWaypointAction.Jump then
                    humanoid.Jump = true
                end
                humanoid:MoveTo(point.Position)
                return
            end
        end

        humanoid:MoveTo(enemy.PrimaryPart.Position)
        return
    end

    humanoid:MoveTo(playerRoot.Position + Vector3.new(5, 0, 5))
end

function Service:Init(config, dataService)
    Config = config
    DataService = dataService

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            refresh(player)
        end)

        player:GetAttributeChangedSignal("DataReady"):Connect(function()
            if player:GetAttribute("DataReady") == true then
                refresh(player)
            end
        end)

        for _, attribute in ipairs({"Pass_SecondCompanion", "Pass_StarterCompanion", "Zone"}) do
            player:GetAttributeChangedSignal(attribute):Connect(function()
                refresh(player)
            end)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        for _, state in ipairs(active[player] or {}) do
            if state.Model.Parent then
                state.Model:Destroy()
            end
        end
        active[player] = nil
        friendCache[player] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(refresh, player)
    end

    task.spawn(function()
        while true do
            for player, states in pairs(active) do
                if player.Parent then
                    for _, state in ipairs(states) do
                        think(player, state)
                    end
                end
            end
            task.wait(0.18)
        end
    end)
end

return Service
