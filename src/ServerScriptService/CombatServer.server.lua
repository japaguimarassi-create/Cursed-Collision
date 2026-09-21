local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local HitboxService = require(ReplicatedStorage.Combat.HitboxService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local DomainService = require(ReplicatedStorage.Domains.DomainService)
local DomainClashService = require(ReplicatedStorage.DomainClash.DomainClashService)
local PerfectComboService = require(ReplicatedStorage.PerfectCombos.PerfectComboService)
local OneTimeAttackService = require(ReplicatedStorage.OneTimeAttacks.OneTimeAttackService)

local remotes = RemoteService:Get()
local states = {}
local actionWindows = {}
local cooldowns = {}

local function now()
    return os.clock()
end

local function rootOf(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function humanoidOf(player)
    local character = player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function setMovement(player, speed, jump)
    local humanoid = humanoidOf(player)
    if humanoid then
        humanoid.WalkSpeed = speed
        humanoid.JumpPower = jump
    end
end

local function stunPlayer(player, duration)
    local state = states[player]
    if not state then
        return
    end

    local expires = math.max(state.StunnedUntil or 0, now() + duration)
    state.StunnedUntil = expires
    setMovement(player, 0, 0)

    task.delay(duration + 0.03, function()
        if state.StunnedUntil <= now() and player.Parent then
            if not state.Clash and not state.Blocking and not state.Dodging then
                setMovement(player, 16, 50)
            end
        end
    end)
end

local function spendCE(player, cost)
    local current = player:GetAttribute("CE") or 0
    if current < cost then
        return false
    end
    player:SetAttribute("CE", current - cost)
    return true
end

local function addAwakening(player, amount)
    if player:GetAttribute("AwakeningActive") then
        return
    end
    local current = player:GetAttribute("Awakening") or 0
    local nextValue = math.clamp(current + amount, 0, Config.Awakening.Max)
    player:SetAttribute("Awakening", nextValue)
end

local context = {}

function context.getState(player)
    return states[player]
end

function context.setAttribute(player, name, value)
    player:SetAttribute(name, value)
    local state = states[player]
    if state then
        state[name] = value
    end
end

function context.spendCE(player, cost)
    return spendCE(player, cost)
end

context.hitbox = HitboxService
context.domain = DomainService

function context.rootPosition(player)
    local root = rootOf(player)
    return root and root.Position or Vector3.zero
end

function context.fx(kind, ...)
    remotes.CombatFX:FireAllClients(kind, ...)
end

function context.damage(attacker, humanoid, amount, meta)
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    local targetCharacter = humanoid.Parent
    local targetPlayer = targetCharacter and Players:GetPlayerFromCharacter(targetCharacter)
    if not targetPlayer then
        return false
    end

    local targetState = states[targetPlayer]
    if not targetState then
        return false
    end

    if targetState.Dodging and targetState.DodgeUntil > now() then
        remotes.ServerEvent:FireClient(attacker, "DodgeEvaded", targetPlayer.UserId)
        return false
    end

    if targetState.Clash then
        return false
    end

    local finalAmount
    if targetState.PerfectBlockUntil and now() <= targetState.PerfectBlockUntil then
        targetState.PerfectBlockUntil = 0
        finalAmount = 0
        stunPlayer(attacker, Config.Combat.Block.PerfectWindow + 0.2)
        remotes.CombatFX:FireAllClients("PerfectBlock", targetCharacter.HumanoidRootPart.Position)
    else
        finalAmount = CharacterService:IncomingDamage(targetPlayer, amount)
        if targetState.Blocking then
            finalAmount *= (1 - Config.Combat.Block.DamageReduction)
        end
    end

    if finalAmount <= 0 then
        return false
    end

    humanoid:TakeDamage(finalAmount)
    addAwakening(attacker, Config.Awakening.GainDamageDealt)
    addAwakening(targetPlayer, Config.Awakening.GainDamageTaken)

    if meta and meta.stun then
        stunPlayer(targetPlayer, meta.stun)
    end

    if meta and meta.knockback then
        local attackerRoot = rootOf(attacker)
        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        if attackerRoot and targetRoot then
            local direction = (targetRoot.Position - attackerRoot.Position).Unit
            targetRoot.AssemblyLinearVelocity = direction * meta.knockback + Vector3.new(0, 24, 0)
        end
    end

    remotes.CombatFX:FireAllClients("Hit", targetCharacter.HumanoidRootPart.Position, meta and meta.tag or "Hit")
    return true
end

function context.setBlackFlashWindow(player, duration)
    local state = states[player]
    if state then
        state.BlackFlashWindow = now() + duration
    end
end

CharacterService:Configure(context)
DomainClashService:Configure(context)

local function setCooldown(player, action, duration)
    cooldowns[player] = cooldowns[player] or {}
    cooldowns[player][action] = now() + duration
end

local function ready(player, action)
    local tableForPlayer = cooldowns[player]
    return not tableForPlayer or not tableForPlayer[action] or tableForPlayer[action] <= now()
end

local function allowAction(player)
    local bucket = actionWindows[player]
    local t = now()
    if not bucket or t - bucket.start >= Config.AntiCheat.Window then
        actionWindows[player] = {start = t, count = 1}
        return true
    end

    bucket.count += 1
    return bucket.count <= Config.AntiCheat.MaxActions
end

local function canCombat(player)
    local state = states[player]
    local humanoid = humanoidOf(player)
    return state and humanoid and humanoid.Health > 0 and state.StunnedUntil <= now() and not state.Clash and not state.Blocking
end

local function m1(player)
    local state = states[player]
    if not canCombat(player) or not ready(player, "M1") then
        return false
    end

    setCooldown(player, "M1", Config.Combat.M1.Cooldown)

    local t = now()
    if t - state.LastM1 > Config.Combat.Combo.ResetAfter then
        state.Combo = 0
    end

    state.Combo = math.clamp(state.Combo + 1, 1, Config.Combat.Combo.Max)
    state.LastM1 = t

    local target = HitboxService.NearestTargetInFront(player, Config.Combat.M1.Range, Config.Combat.M1.Width, Config.Combat.M1.Height)
    if not target then
        return false
    end

    local damage = Config.Combat.M1.Damage[state.Combo]
    local momentum = state.Momentum or 0
    if player:GetAttribute("CharacterId") == "Yuji" then
        damage += momentum
    end

    local hit = context.damage(player, target.humanoid, damage, {
        stun = Config.Combat.M1.Stun,
        knockback = state.Combo == 4 and 32 or 10,
        tag = "M1"
    })

    if hit and state.Combo == 3 then
        context.setBlackFlashWindow(player, 0.22)
        remotes.ServerEvent:FireClient(player, "BlackFlashWindow", 0.22)
    end

    if hit and state.Combo == 4 then
        state.Combo = 0
        remotes.CombatFX:FireAllClients("M1Finisher", target.root.Position)
    end

    return hit
end

local function heavy(player)
    if not canCombat(player) or not ready(player, "Heavy") or not spendCE(player, Config.CE.Costs.Heavy) then
        return false
    end

    setCooldown(player, "Heavy", Config.Combat.Heavy.Cooldown)

    local target = HitboxService.NearestTargetInFront(player, Config.Combat.Heavy.Range, Config.Combat.Heavy.Width, Config.Combat.Heavy.Height)
    if not target then
        return false
    end

    return context.damage(player, target.humanoid, Config.Combat.Heavy.Damage, {
        stun = Config.Combat.Heavy.Stun,
        knockback = Config.Combat.Heavy.Knockback,
        tag = "Heavy"
    })
end

local function dash(player)
    local state = states[player]
    local root = rootOf(player)
    if not state or not root or not canCombat(player) or not ready(player, "Dash") then
        return false
    end

    setCooldown(player, "Dash", Config.Combat.Dash.Cooldown)
    state.Dodging = true
    state.DodgeUntil = now() + Config.Combat.Dash.Duration

    root.AssemblyLinearVelocity = root.CFrame.LookVector * Config.Combat.Dash.Speed
    task.delay(Config.Combat.Dash.Duration, function()
        if state then
            state.Dodging = false
        end
    end)

    return true
end

local function dodge(player)
    local state = states[player]
    if not state or not canCombat(player) or not ready(player, "Dodge") then
        return false
    end

    if not spendCE(player, Config.CE.Costs.Dodge) then
        return false
    end

    setCooldown(player, "Dodge", Config.Combat.Dodge.Cooldown)
    state.Dodging = true
    state.DodgeUntil = now() + Config.Combat.Dodge.IFrame
    task.delay(Config.Combat.Dodge.IFrame, function()
        if state then
            state.Dodging = false
        end
    end)

    return true
end

local function grab(player)
    if not canCombat(player) or not ready(player, "Grab") or not spendCE(player, Config.CE.Costs.Grab) then
        return false
    end

    setCooldown(player, "Grab", Config.Combat.Grab.Cooldown)
    local target = HitboxService.NearestTargetInFront(player, Config.Combat.Grab.Range, Config.Combat.Grab.Width, Config.Combat.Grab.Height)
    if not target then
        return false
    end

    return context.damage(player, target.humanoid, Config.Combat.Grab.Damage, {
        stun = Config.Combat.Grab.Stun,
        knockback = 8,
        tag = "Grab"
    })
end

local function setBlock(player, active)
    local state = states[player]
    if not state or state.StunnedUntil > now() or state.Clash then
        return false
    end

    if active == state.Blocking then
        return false
    end

    state.Blocking = active
    player:SetAttribute("Blocking", active)

    if active then
        state.PerfectBlockUntil = now() + Config.Combat.Block.PerfectWindow
        setMovement(player, 8, 0)
    else
        state.PerfectBlockUntil = 0
        if state.StunnedUntil <= now() then
            setMovement(player, 16, 50)
        end
    end

    return true
end

local function awaken(player)
    local state = states[player]
    if not state or state.Awakening or state.Clash then
        return false
    end

    if (player:GetAttribute("Awakening") or 0) < Config.Awakening.MinToActivate then
        return false
    end

    state.Awakening = true
    player:SetAttribute("AwakeningActive", true)
    PerfectComboService:OnAwakening(player)
    CharacterService:Awaken(player)

    task.delay(Config.Awakening.Duration, function()
        if not player.Parent then
            return
        end
        state.Awakening = false
        player:SetAttribute("AwakeningActive", false)
        player:SetAttribute("Awakening", 0)
        PerfectComboService:End(player)
        OneTimeAttackService:End(player)
        setMovement(player, 16, 50)
        remotes.CombatFX:FireAllClients("AwakeningEnd", context.rootPosition(player))
    end)

    remotes.CombatFX:FireAllClients("Awakening", context.rootPosition(player), player:GetAttribute("CharacterId"))
    return true
end

local function domain(player)
    local state = states[player]
    if not state or state.Clash or not ready(player, "Domain") then
        return false
    end

    if not spendCE(player, Config.CE.Costs.Domain) then
        return false
    end

    setCooldown(player, "Domain", Config.Domain.Cooldown)

    local result = CharacterService:Domain(player)
    if result then
        local started = DomainClashService:TryStart(player)
        if started then
            remotes.CombatFX:FireAllClients("DomainClashStart", context.rootPosition(player))
        else
            remotes.CombatFX:FireAllClients("DomainStart", context.rootPosition(player), player:GetAttribute("CharacterId"))
        end
    end
    return result
end

local function characterAction(player, action)
    if action == "Special" then
        if states[player].Clash then
            if not spendCE(player, Config.CE.Costs.ClashSpecial) then
                return false
            end
            return DomainClashService:Special(player)
        end
        if not ready(player, "Special") then
            return false
        end
        setCooldown(player, "Special", 0.55)
        local success = CharacterService:Special(player, "Special")
        if success then
            PerfectComboService:Record(player, "Special")
        end
        return success
    end

    if action == "Skill" then
        if not canCombat(player) or not ready(player, "Skill") then
            return false
        end
        if not spendCE(player, Config.CE.Costs.Skill) then
            return false
        end
        setCooldown(player, "Skill", 0.75)
        local success = CharacterService:Special(player, "Skill")
        if success then
            PerfectComboService:Record(player, "Skill")
        end
        return success
    end

    return false
end

local function oneTime(player)
    if not states[player] then
        return false
    end
    local success = OneTimeAttackService:TryUse(player, CharacterService)
    if success then
        PerfectComboService:End(player)
        remotes.CombatFX:FireAllClients("OneTimeAttack", context.rootPosition(player), player:GetAttribute("CharacterId"))
    end
    return success
end

local function handle(player, action)
    if type(action) ~= "string" or #action > 32 then
        return
    end
    if not allowAction(player) then
        return
    end

    if action == "M1" then
        if m1(player) then
            PerfectComboService:Record(player, "M1")
        end
    elseif action == "Heavy" then
        heavy(player)
    elseif action == "Dash" then
        dash(player)
    elseif action == "Dodge" then
        dodge(player)
    elseif action == "Grab" then
        grab(player)
    elseif action == "BlockStart" then
        setBlock(player, true)
    elseif action == "BlockEnd" then
        setBlock(player, false)
    elseif action == "Special" or action == "Skill" then
        characterAction(player, action)
    elseif action == "Awaken" then
        awaken(player)
    elseif action == "Domain" then
        domain(player)
    elseif action == "OneTime" then
        oneTime(player)
    end
end

remotes.CombatAction.OnServerEvent:Connect(function(player, action, payload)
    if type(action) ~= "string" or #action > 32 then
        return
    end

    if action == "ClashMove" then
        if type(payload) == "number" and allowAction(player) then
            DomainClashService:Move(player, payload)
        end
        return
    end

    handle(player, action)
end)

remotes.Selection.OnServerEvent:Connect(function(player, characterId)
    if type(characterId) ~= "string" or #characterId > 32 then
        return
    end
    CharacterService:Select(player, characterId)
end)

local function setupPlayer(player)
    states[player] = {
        Combo = 0,
        LastM1 = 0,
        StunnedUntil = 0,
        Blocking = false,
        Dodging = false,
        DodgeUntil = 0,
        PerfectBlockUntil = 0,
        Awakening = false,
        Clash = false,
        Domain = false,
        Momentum = 0,
        BlackFlashWindow = nil
    }

    actionWindows[player] = nil
    cooldowns[player] = {}

    CharacterService:Initialize(player)
    OneTimeAttackService:Initialize(player)

    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        states[player].StunnedUntil = 0
        states[player].Blocking = false
        states[player].Dodging = false
        states[player].Awakening = false
        player:SetAttribute("AwakeningActive", false)
        player:SetAttribute("DomainActive", false)
        player:SetAttribute("InClash", false)
        task.wait()
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end)

    task.spawn(function()
        while player.Parent do
            task.wait(0.25)
            local maxCE = player:GetAttribute("MaxCE") or Config.CE.Max
            local ce = player:GetAttribute("CE") or maxCE
            player:SetAttribute("CE", math.min(maxCE, ce + Config.CE.RegenPerSecond * 0.25))
        end
    end)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
    states[player] = nil
    actionWindows[player] = nil
    cooldowns[player] = nil
    PerfectComboService:Reset(player)
    OneTimeAttackService:End(player)
    DomainService:Stop(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end
