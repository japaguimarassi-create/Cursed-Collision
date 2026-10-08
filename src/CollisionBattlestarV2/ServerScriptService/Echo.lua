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
        running = false,
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

function Echo:IsFriend(player: Player, friendUserId: number)
    local ok, pages = pcall(function()
        return Players:GetFriendsAsync(player.UserId)
    end)

    if not ok then
        return false
    end

    for _ = 1, 3 do
        for _, friend in ipairs(pages:GetCurrentPage()) do
            if type(friend) == "table" and friend.Id == friendUserId then
                return true
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

    return false
end

function Echo:Friends(player: Player)
    local friends = {}

    local ok, pages = pcall(function()
        return Players:GetFriendsAsync(player.UserId)
    end)

    if not ok then
        return friends
    end

    for _ = 1, 3 do
        for _, friend in ipairs(pages:GetCurrentPage()) do
            if type(friend) == "table" and type(friend.Id) == "number" then
                friends[#friends + 1] = {
                    id = friend.Id,
                    name = type(friend.DisplayName) == "string" and friend.DisplayName or friend.Username or tostring(friend.Id),
                }
                if #friends >= 20 then
                    return friends
                end
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

    table.sort(friends, function(a, b)
        return a.name < b.name
    end)

    return friends
end

function Echo:Summon(player: Player, friendUserId: any)
    if player:GetAttribute("CBS_PvP") == true
        or type(friendUserId) ~= "number"
        or friendUserId <= 0 then
        return
    end

    if self.requests[player] and os.clock() - self.requests[player] < 1.5 then
        return
    end
    self.requests[player] = os.clock()

    if not self:IsFriend(player, friendUserId) then
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
    model:SetAttribute("CBS2_EchoFriendUserId", friendUserId)

    local core = Instance.new("Part")
    core.Name = "Core"
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(2, 2, 2)
    core.Material = Enum.Material.Neon
    core.Color = Color3.fromRGB(100, 200, 255)
    core.Anchored = true
    core.CanCollide = false
    core.CanTouch = false
    core.CanQuery = false
    core.CastShadow = false
    core.CollisionGroup = "CBS_Echo"
    core.CFrame = root.CFrame * CFrame.new(3, 0, 3)
    core.Parent = model

    local label = Instance.new("BillboardGui")
    label.Name = "FriendName"
    label.Size = UDim2.fromOffset(150, 28)
    label.StudsOffset = Vector3.new(0, 2.3, 0)
    label.AlwaysOnTop = true
    label.MaxDistance = 55
    label.Parent = core

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = "FRIEND ECHO"
    text.TextColor3 = Color3.fromRGB(175, 225, 255)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 12
    text.Parent = label

    model.PrimaryPart = core
    model.Parent = workspace

    self.active[player] = {
        model = model,
        nextAttack = 0,
        friendUserId = friendUserId,
    }

    player:SetAttribute("CBS_Echo", true)
    self.remotes.Echo:FireClient(player, "State", true)
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

        if request.action == "ListFriends" then
            self.remotes.Echo:FireClient(player, "Friends", self:Friends(player))
        elseif request.action == "Summon" then
            self:Summon(player, request.friendUserId)
        elseif request.action == "Dismiss" then
            self:Remove(player)
        elseif request.action == "State" then
            self.remotes.Echo:FireClient(player, "State", self.active[player] ~= nil)
        end
    end))

    table.insert(self.connections, Players.PlayerRemoving:Connect(function(player)
        self:Remove(player)
    end))

    self.running = true
    task.spawn(function()
        while self.running do
            local any = false
            local now = os.clock()
            for player, record in pairs(self.active) do
                any = true
                self:Tick(player, record, now)
            end
            task.wait(any and 0.2 or 0.5)
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
    self.running = false
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
