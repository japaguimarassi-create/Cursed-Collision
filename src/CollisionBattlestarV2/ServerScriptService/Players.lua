--!strict

local Players = game:GetService("Players")

local Constants = require(script.Parent.ReplicatedStorage.Shared.Constants)
local PhysicsRules = require(script.Parent.ReplicatedStorage.Shared.PhysicsRules)
local Data = require(script.Parent.ReplicatedStorage.Shared.Data)
local Rules = require(script.Parent.ReplicatedStorage.Shared.Rules)

local PlayerService = {}
PlayerService.__index = PlayerService

function PlayerService.new(persistence)
    return setmetatable({
        persistence = persistence,
        states = {},
        connections = {},
        creditChanged = Instance.new("BindableEvent"),
        running = false,
    }, PlayerService)
end

function PlayerService:State(player: Player)
    return self.states[player]
end

function PlayerService:ApplyCharacter(player: Player, character: Model)
    local state = self.states[player]
    if not state then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        return
    end

    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CollisionGroup = "CBS_Player"
            descendant.CustomPhysicalProperties = PhysicsRules.Character
            descendant.CastShadow = false
        end
    end

    local oldTrail = character:FindFirstChild("CBS2Trail")
    if oldTrail then
        oldTrail:Destroy()
    end

    local skin = state.profile.Inventory.Equipped.PlayerSkin
    if skin == "BlueTrail" or skin == "RedTrail" then
        local a0 = Instance.new("Attachment")
        a0.Position = Vector3.new(0, -1, 0)
        a0.Parent = root

        local a1 = Instance.new("Attachment")
        a1.Position = Vector3.new(0, 1, 0)
        a1.Parent = root

        local trail = Instance.new("Trail")
        trail.Name = "CBS2Trail"
        trail.Attachment0 = a0
        trail.Attachment1 = a1
        trail.Lifetime = 0.18
        trail.LightEmission = 0.8
        trail.Color = skin == "RedTrail"
            and ColorSequence.new(Color3.fromRGB(255, 75, 85))
            or ColorSequence.new(Color3.fromRGB(90, 180, 255))
        trail.Parent = character
    end

    local health = Constants.PlayerHealth + state.profile.Upgrades.Health * 20
    humanoid.MaxHealth = health
    humanoid.Health = health
    humanoid.WalkSpeed = Constants.PlayerSpeed
    humanoid.AutoRotate = true
end

function PlayerService:Add(player: Player)
    if self.states[player] or not player.Parent then
        return
    end

    local profile, err = self.persistence:Load(player)
    if not profile then
        warn(("CBS2 profile load failed for %s: %s"):format(player.Name, tostring(err)))
        player:Kick("Could not safely load your data.")
        return
    end

    local state = {
        profile = Data.sanitize(profile),
        attackAt = -math.huge,
        dashAt = -math.huge,
        combo = 0,
        comboAt = -math.huge,
    }

    self.states[player] = state

    player:SetAttribute("CBS_PlayerReady", true)
    player:SetAttribute("CBS_Credits", state.profile.Credits)
    player:SetAttribute("CBS_Score", state.profile.Score)
    player:SetAttribute("CBS_Kills", state.profile.Kills)
    player:SetAttribute("CBS_Waves", state.profile.Waves)
    player:SetAttribute("CBS_PvP", false)
    player:SetAttribute("CBS_PlayerSkin", state.profile.Inventory.Equipped.PlayerSkin)

    for id, value in pairs(state.profile.Upgrades) do
        player:SetAttribute("CBS_" .. id .. "Level", value)
    end

    local level, progress, required = Rules.levelProgress(state.profile.Score)
    player:SetAttribute("CBS_Level", level)
    player:SetAttribute("CBS_LevelProgress", progress)
    player:SetAttribute("CBS_LevelRequired", required)

    table.insert(self.connections, player.CharacterAdded:Connect(function(character)
        self:ApplyCharacter(player, character)

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                local current = self.states[player]
                if current then
                    current.attackAt = -math.huge
                    current.dashAt = -math.huge
                    current.combo = 0
                    current.comboAt = -math.huge
                end
            end)
        end
    end))

    if player.Character then
        self:ApplyCharacter(player, player.Character)
    else
        task.defer(function()
            if player.Parent then
                pcall(function()
                    player:LoadCharacterAsync()
                end)
            end
        end)
    end
end

function PlayerService:AddCredits(player: Player, amount: number)
    local state = self.states[player]
    local safe = math.floor(tonumber(amount) or 0)
    if not state or safe <= 0 then
        return false
    end

    state.profile.Credits = math.min(2147483647, state.profile.Credits + safe)
    player:SetAttribute("CBS_Credits", state.profile.Credits)
    self.persistence:MarkDirty(player)
    self.creditChanged:Fire(player, safe)
    return true
end

function PlayerService:GetCreditChanged()
    return self.creditChanged.Event
end

function PlayerService:AddScore(player: Player, amount: number)
    local state = self.states[player]
    local safe = math.floor(tonumber(amount) or 0)
    if not state or safe <= 0 then
        return false
    end

    state.profile.Score = math.min(9007199254740991, state.profile.Score + safe)
    local level, progress, required = Rules.levelProgress(state.profile.Score)

    player:SetAttribute("CBS_Score", state.profile.Score)
    player:SetAttribute("CBS_Level", level)
    player:SetAttribute("CBS_LevelProgress", progress)
    player:SetAttribute("CBS_LevelRequired", required)
    self.persistence:MarkDirty(player)
    return true
end

function PlayerService:AddKill(player: Player)
    local state = self.states[player]
    if not state then
        return false
    end
    state.profile.Kills += 1
    player:SetAttribute("CBS_Kills", state.profile.Kills)
    self.persistence:MarkDirty(player)
    return true
end

function PlayerService:AddWave(player: Player)
    local state = self.states[player]
    if not state then
        return false
    end
    state.profile.Waves += 1
    player:SetAttribute("CBS_Waves", state.profile.Waves)
    self.persistence:MarkDirty(player)
    return true
end

function PlayerService:Damage(player: Player, amount: number)
    local state = self.states[player]
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not state or not humanoid or humanoid.Health <= 0 then
        return false
    end

    humanoid:TakeDamage(math.max(0, math.floor(tonumber(amount) or 0)))
    return true
end

function PlayerService:Upgrade(player: Player, id: string, price: number)
    local state = self.states[player]
    if not state or state.profile.Upgrades[id] == nil then
        return false, "invalid_upgrade"
    end

    local level = state.profile.Upgrades[id]
    if level >= 25 then
        return false, "max_level"
    end

    local expected = math.floor(
        (100 + level * 65) * (id == "Dash" and 1.2 or 1)
    )

    if price ~= expected then
        return false, "stale_price"
    end

    if state.profile.Credits < expected then
        return false, "insufficient_credits"
    end

    state.profile.Credits -= expected
    state.profile.Upgrades[id] = level + 1

    player:SetAttribute("CBS_Credits", state.profile.Credits)
    player:SetAttribute("CBS_" .. id .. "Level", level + 1)
    self.persistence:MarkDirty(player)
    self.creditChanged:Fire(player, -expected)

    if player.Character then
        self:ApplyCharacter(player, player.Character)
    end

    return true, level + 1
end

function PlayerService:Equip(player: Player, id: string)
    local state = self.states[player]
    if not state or not state.profile.Inventory.Owned[id] then
        return false
    end

    state.profile.Inventory.Equipped.PlayerSkin = id
    player:SetAttribute("CBS_PlayerSkin", id)
    self.persistence:MarkDirty(player)

    if player.Character then
        self:ApplyCharacter(player, player.Character)
    end

    return true
end

function PlayerService:RecoverAll(world)
    for _, player in ipairs(Players:GetPlayers()) do
        local state = self.states[player]
        if state then
            task.spawn(function()
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local root = character and character:FindFirstChild("HumanoidRootPart")

                if not humanoid or not root or humanoid.Health <= 0 then
                    pcall(function()
                        player:LoadCharacterAsync()
                    end)
                    return
                end

                state.attackAt = -math.huge
                state.dashAt = -math.huge
                state.combo = 0
                state.comboAt = -math.huge
                player:SetAttribute("CBS_PvP", false)

                if world and not world:IsInArena(root.Position) then
                    root.CFrame = world:GetPlayerSpawn()
                    root.AssemblyLinearVelocity = Vector3.zero
                end

                self:ApplyCharacter(player, character)
            end)
        end
    end
end

function PlayerService:Start()
    if self.running then
        return
    end

    self.running = true
    Players.CharacterAutoLoads = true

    table.insert(self.connections, Players.PlayerAdded:Connect(function(player)
        task.spawn(function()
            self:Add(player)
        end)
    end))

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:Add(player)
        end)
    end
end

function PlayerService:Stop()
    self.running = false
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    table.clear(self.connections)
end

function PlayerService:Reload()
    return true
end

return PlayerService
