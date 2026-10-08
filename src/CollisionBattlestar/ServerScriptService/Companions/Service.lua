--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FriendRules = require(ReplicatedStorage.Shared.FriendRules)
local CompanionRules = require(ReplicatedStorage.Shared.CompanionRules)
local Classes = require(ReplicatedStorage.Shared.CompanionDefinitions)

local CompanionFactory = require(script.Parent.Factory)
local EchoBrain = require(script.Parent.Brain)

local CompanionService = {}
CompanionService.__index = CompanionService

local REQUEST_COOLDOWN = 1.5

function CompanionService.new(playerState, friendService, securityService, remotes, enemyService)
    return setmetatable({
        playerState = playerState,
        friendService = friendService,
        securityService = securityService,
        remotes = remotes,
        enemyService = enemyService,
        active = {} :: {[Player]: {friendUserId: number, classId: string, brain: any, model: Model}},
        requests = {} :: {[Player]: number},
    }, CompanionService)
end

function CompanionService:Start()
    Players.PlayerRemoving:Connect(function(player)
        self:Unsummon(player, "owner_left")
        self.requests[player] = nil
    end)

    Players.PlayerAdded:Connect(function(player)
        self:DisableEchoesRepresenting(player.UserId)
        player:GetAttributeChangedSignal("CBS_PvP"):Connect(function()
            if player:GetAttribute("CBS_PvP") == true then
                self:Unsummon(player, "entered_pvp")
            end
        end)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self:DisableEchoesRepresenting(player.UserId)
        player:GetAttributeChangedSignal("CBS_PvP"):Connect(function()
            if player:GetAttribute("CBS_PvP") == true then
                self:Unsummon(player, "entered_pvp")
            end
        end)
    end

    self.remotes.Companion.OnServerEvent:Connect(function(player, request)
        self:HandleRequest(player, request)
    end)
end

function CompanionService:CanRequest(player: Player)
    local now = os.clock()
    local last = self.requests[player] or -math.huge

    if now - last < REQUEST_COOLDOWN then
        return false
    end

    self.requests[player] = now
    return true
end

function CompanionService:HandleRequest(player: Player, request: any)
    if type(request) ~= "table" or not self:CanRequest(player) then
        return
    end

    if request.action == "ListFriends" then
        local friends, status = self.friendService:Resolve(player, false)
        self.remotes.Companion:FireClient(player, "Friends", {
            friends = friends,
            status = status,
        })
        return
    end

    if request.action == "Summon" then
        local ok, value = self:Summon(player, request.friendUserId, request.classId)
        self.remotes.Companion:FireClient(player, "SummonResult", {
            success = ok,
            value = value,
            snapshot = self:GetSnapshot(player),
        })
        return
    end

    if request.action == "Unsummon" then
        local ok, value = self:Unsummon(player, "player_request")
        self.remotes.Companion:FireClient(player, "UnsummonResult", {
            success = ok,
            value = value,
            snapshot = self:GetSnapshot(player),
        })
        return
    end
end

function CompanionService:Summon(player: Player, friendUserId: any, classId: any)
    if self.active[player] then
        if self.active[player].model:GetAttribute("CBS_EchoDisabled") == true then
            self:Unsummon(player, "replace_disabled")
        else
            return false, "already_active"
        end
    end

    if not FriendRules.isValidClass(classId) then
        return false, "invalid_class"
    end

    if self:FriendPresent(friendUserId) then
        return false, "friend_present"
    end

    local selected, friendOrReason = self.friendService:Select(player, friendUserId, classId)
    if not selected then
        return false, friendOrReason
    end

    local profile = self.playerState:GetProfile(player)
    if not profile then
        return false, "profile_unavailable"
    end

    local key = tostring(friendUserId)
    local saved = profile.Echoes[key]

    if type(saved) ~= "table" then
        saved = {
            FriendUserId = friendUserId,
            ClassId = classId,
            Level = 1,
            Bond = 0,
            CosmeticIds = {},
            Equipped = true,
        }
        profile.Echoes[key] = saved
    else
        saved.ClassId = classId
        saved.Equipped = true
    end

    for _, echo in pairs(profile.Echoes) do
        if type(echo) == "table" then
            echo.Equipped = false
        end
    end
    saved.Equipped = true

    local level = math.max(1, math.floor(tonumber(saved.Level) or 1))
    local model, humanoid, root = CompanionFactory.Create(friendUserId, classId, level)

    if not model or not humanoid or not root then
        saved.Equipped = false
        return false, "factory_failed"
    end

    local ownerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not ownerRoot or not ownerRoot:IsA("BasePart") then
        model:Destroy()
        saved.Equipped = false
        return false, "owner_not_ready"
    end

    model.Parent = workspace:FindFirstChild("CollisionBattlestarWorld") or workspace
    root.CFrame = ownerRoot.CFrame * CFrame.new(-6, 0, 5)

    local brain = EchoBrain.new(
        player,
        model,
        humanoid,
        root,
        classId,
        level,
        {
            onAttack = function(owner, echoModel, target, damage, range)
                return self:ApplyEchoDamage(owner, echoModel, target, damage, range)
            end,
            getTargets = function(origin, radius)
                return self.enemyService:GetTargetCandidates(origin, radius)
            end,
            onHeal = function(owner, amount, position)
                self.remotes.FX:FireAllClients("EchoHeal", {
                    userId = owner.UserId,
                    amount = amount,
                    position = position,
                })
            end,
        }
    )

    self.active[player] = {
        friendUserId = friendUserId,
        classId = classId,
        brain = brain,
        model = model,
    }

    model:SetAttribute("CBS_EchoOwnerUserId", player.UserId)
    brain:Start()

    return true, friendOrReason
end

function CompanionService:ApplyEchoDamage(owner: Player, echoModel: Model, target: Model, damage: number, range: number)
    local echoRoot = echoModel:FindFirstChild("HumanoidRootPart")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = target:FindFirstChildOfClass("Humanoid")

    if not echoRoot or not targetRoot or not targetHumanoid or not echoRoot:IsA("BasePart") or not targetRoot:IsA("BasePart") then
        return false
    end

    if echoModel:GetAttribute("CBS_EchoOwnerUserId") ~= owner.UserId then
        return false
    end

    if target:GetAttribute("CBS_Enemy") ~= true or targetHumanoid.Health <= 0 then
        return false
    end

    if (targetRoot.Position - echoRoot.Position).Magnitude > range + 0.5 then
        return false
    end

    local valid, _, verifiedRoot = self.securityService:ValidateAttackTargetForActor(echoRoot, target, range)
    if not valid or verifiedRoot ~= targetRoot then
        return false
    end

    target:SetAttribute("CBS_LastHitUserId", owner.UserId)
    targetHumanoid:TakeDamage(damage)

    self.remotes.FX:FireAllClients("EchoHit", {
        userId = owner.UserId,
        position = targetRoot.Position,
        elite = target:GetAttribute("CBS_Elite") == true,
    })

    return true
end

function CompanionService:FriendPresent(friendUserId: any)
    if not FriendRules.isValidUserId(friendUserId) then
        return false
    end

    return Players:GetPlayerByUserId(friendUserId) ~= nil
end

function CompanionService:DisableEchoesRepresenting(friendUserId: number)
    for owner, active in pairs(self.active) do
        if active.friendUserId == friendUserId then
            active.brain:Disable("friend_present")
            owner:SetAttribute("CBS_EchoDisabled", true)
            if active.model then
                active.model:SetAttribute("CBS_EchoDisabled", true)
            end
        end
    end
end

function CompanionService:Unsummon(player: Player, reason: string)
    local active = self.active[player]
    if not active then
        return false, "not_active"
    end

    active.brain:Stop()

    if active.model.Parent then
        active.model:Destroy()
    end

    self.active[player] = nil
    player:SetAttribute("CBS_EchoDisabled", false)

    return true, reason
end

function CompanionService:GetSnapshot(player: Player)
    local active = self.active[player]
    if not active then
        return {
            active = false,
        }
    end

    local profile = self.playerState:GetProfile(player)
    local loadout = profile and profile.Echoes[tostring(active.friendUserId)]

    return {
        active = true,
        friendUserId = active.friendUserId,
        classId = active.classId,
        state = active.model:GetAttribute("CBS_EchoState") or "Follow",
        level = type(loadout) == "table" and loadout.Level or 1,
        bond = type(loadout) == "table" and loadout.Bond or 0,
        disabled = active.model:GetAttribute("CBS_EchoDisabled") == true,
    }
end

return CompanionService
