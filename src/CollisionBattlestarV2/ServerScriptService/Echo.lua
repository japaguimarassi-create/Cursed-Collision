--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Echo = {}
Echo.__index = Echo

function Echo.new(players, enemies, remotes)
    return setmetatable({
        players = players,
        enemies = enemies,
        remotes = remotes,
        active = {},
        requests = {},
        connections = {},
    }, Echo)
end

function Echo:Remove(player: Player)
    local current = self.active[player]
    if not current then
        return
    end

    if current.model and current.model.Parent then
        current.model:Destroy()
    end

    self.active[player] = nil
    player:SetAttribute("CBS_Echo", false)
end

function Echo:Summon(player: Player)
    if player:GetAttribute("CBS_PvP") == true then
        return
    end

    self:Remove(player)

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end

    local model = Instance.new("Model")
    model.Name = "Echo"
    model:SetAttribute("CBS2_Echo", true)

    local core = Instance.new("Part")
    core.Name = "Core"
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(2, 2, 2)
    core.Material = Enum.Material.Neon
    core.Color = Color3.fromRGB(100, 200, 255)
    core.CanCollide = false
    core.CanTouch = false
    core.CanQuery = false
    core.CollisionGroup = "CBS_Echo"
    core.CFrame = root.CFrame * CFrame.new(3, 0, 3)
    core.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 80
    humanoid.Health = 80
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model

    model.PrimaryPart = core
    model.Parent = workspace

    self.active[player] = {
        model = model,
        nextAttack = 0,
        friendUserId = player.UserId,
    }

    player:SetAttribute("CBS_Echo", true)
end

function Echo:Tick(player, record, now)
    if not player.Parent or not record.model.Parent or player:GetAttribute("CBS_PvP") == true then
        self:Remove(player)
        return
    end

    local ownerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local echoRoot = record.model.PrimaryPart
    if not ownerRoot or not echoRoot or not ownerRoot:IsA("BasePart") then
        return
    end

    local desired = ownerRoot.Position + Vector3.new(3, 0, 3)
    local offset = desired - echoRoot.Position
    if offset.Magnitude > 1 then
        echoRoot.CFrame = CFrame.new(
            echoRoot.Position:Lerp(desired, 0.25)
        )
    end

    if now < record.nextAttack then
        return
    end

    local nearest = nil
    local nearestDistance = math.huge

    for model in pairs(self.enemies.active) do
        local root = model.PrimaryPart
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health > 0 then
            local distance = (root.Position - echoRoot.Position).Magnitude
            if distance < nearestDistance and distance <= 24 then
                nearestDistance = distance
                nearest = model
            end
        end
    end

    if nearest then
        record.nextAttack = now + 1.4
        self.enemies:TakeDamage(player, nearest, 8, false)
        self.remotes.FX:FireAllClients("EchoHit", {
            position = echoRoot.Position,
        })
    end
end

function Echo:Start()
    table.insert(self.connections, self.remotes.Echo.OnServerEvent:Connect(function(player, request)
        if type(request) ~= "table" then
            return
        end

        if request.action == "Summon" then
            self:Summon(player)
        elseif request.action == "Dismiss" then
            self:Remove(player)
        elseif request.action == "State" then
            self.remotes.Echo:FireClient(player, "State", self.active[player] ~= nil)
        end
    end))

    table.insert(self.connections, Players.PlayerRemoving:Connect(function(player)
        self:Remove(player)
    end))

    task.spawn(function()
        while true do
            local any = false
            local now = os.clock()
            for player, record in pairs(self.active) do
                any = true
                self:Tick(player, record, now)
            end
            task.wait(any and 0.2 or 0.5)
            if not self.connections then
                break
            end
        end
    end)
end

function Echo:ResetRuntime()
    local list = {}
    for player in pairs(self.active) do
        list[#list + 1] = player
    end
    for _, player in ipairs(list) do
        self:Remove(player)
    end
end

function Echo:Stop()
    self:ResetRuntime()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    table.clear(self.connections)
end

function Echo:Reload()
    self:Stop()
    self:Start()
end

return Echo
