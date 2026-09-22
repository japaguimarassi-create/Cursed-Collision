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
local QuestService = require(ReplicatedStorage.Economy.QuestService)
local DataService = require(ReplicatedStorage.Economy.DataService)

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
    if not state then return end

    state.StunnedUntil = math.max(state.StunnedUntil or 0, now() + duration)
    setMovement(player, 0, 0)

    task.delay(duration + 0.03, function()
        if not player.Parent or state.StunnedUntil > now() then return end
        if not state.Clash and not state.Blocking and not state.Dodging then
            setMovement(player, 16, 50)
        end
    end)
end

local function addAwakening(player, amount)
    if player:GetAttribute("AwakeningActive") then return end
    local current = player:GetAttribute("Awakening") or 0
    player:SetAttribute("Awakening", math.clamp(current + amount, 0, Config.Awakening.Max))
end

local context = {}

function context.getState(player)
    return states[player]
end

function context.setAttribute(player, name, value)
    player:SetAttribute(name, value)
    local state = states[player]
    if state then state[name] = value end
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
    if not humanoid or humanoid.Health <= 0 or type(amount) ~= "number" or amount <= 0 then
        return false
    end

    local targetCharacter = humanoid.Parent
    local targetPlayer = targetCharacter and Players:GetPlayerFromCharacter(targetCharacter)
    if not targetPlayer or targetPlayer == attacker then
        return false
    end

    local targetState = states[targetPlayer]
    if not targetState then return false end

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
        local root = targetCharacter:FindFirstChild("HumanoidRootPart")
        if root then remotes.CombatFX:FireAllClients("PerfectBlock", root.Position) end
    else
        finalAmount = tonumber(CharacterService:IncomingDamage(targetPlayer, amount)) or amount
        if targetState.Blocking then
            finalAmount *= 1 - Config.Combat.Block.DamageReduction
        end
    end

    if finalAmount <= 0 then
        return false
    end

    humanoid:TakeDamage(finalAmount)
    addAwakening(attacker, Config.Awakening.GainDamageDealt)
    addAwakening(targetPlayer, Config.Awakening.GainDamageTaken)

    local attackerCharacterId = attacker:GetAttribute("CharacterId")
    QuestService:Record(attacker, "Damage", finalAmount, attackerCharacterId)
    if humanoid.Health <= 0 then
        DataService:AddCredits(attacker, 5)
        QuestService:Record(attacker, "Kill", 1, attackerCharacterId)
        remotes.AccountEvent:FireClient(attacker, "Notice", {
            Message = "+5 Credits • Kill",
            Success = true
        })
    end

    if meta and meta.stun then
        stunPlayer(targetPlayer, meta.stun)
    end

    if meta and meta.knockback and meta.knockback > 0 then
        local attackerRoot = rootOf(attacker)
        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        if attackerRoot and targetRoot then
            local delta = targetRoot.Position - attackerRoot.Position
            if delta.Magnitude > 0.01 then
                targetRoot.AssemblyLinearVelocity = delta.Unit * meta.knockback + Vector3.new(0, 24, 0)
            end
        end
    end

    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if targetRoot then
        remotes.CombatFX:FireAllClients("Hit", targetRoot.Position, meta and meta.tag or "Hit")
    end
    return true
end

function context.setBlackFlashWindow(player, duration)
    local state = states[player]
    if state then
        state.BlackFlashWindow = now() + duration
    end
end

CharacterService:Configure(context)
DomainService:Configure(context)
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
        actionWindows[player] = {start=t, count=1}
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
    if not canCombat(player) or not ready(player, "M1") then return false end

    setCooldown(player, "M1", Config.Combat.M1.Cooldown)

    local t = now()
    if t - state.LastM1 > Config.Combat.Combo.ResetAfter then
        state.Combo = 0
    end

    state.Combo = math.clamp(state.Combo + 1, 1, Config.Combat.Combo.Max)
    state.LastM1 = t

    local attackRoot = rootOf(player)
    if attackRoot then
        remotes.CombatFX:FireAllClients("MeleeSwing", attackRoot.Position, {
            character=player:GetAttribute("CharacterId"),
            combo=state.Combo,
            direction=attackRoot.CFrame.LookVector
        })
    end

    local target = HitboxService.NearestTargetInFront(player, Config.Combat.M1.Range, Config.Combat.M1.Width, Config.Combat.M1.Height)
    if not target then return false end

    local damage = Config.Combat.M1.Damage[state.Combo]
    if player:GetAttribute("CharacterId") == "Yuji" then
        damage += state.Momentum or 0
    end

    local hit = context.damage(player, target.humanoid, damage, {
        stun=Config.Combat.M1.Stun,
        knockback=state.Combo == 4 and 32 or 10,
        tag="M1"
    })

    if hit and state.Combo == 3 and player:GetAttribute("CharacterId") == "Yuji" then
        context.setBlackFlashWindow(player, 0.24)
        remotes.ServerEvent:FireClient(player, "BlackFlashWindow", 0.24)
    end

    if hit and state.Combo == 4 then
        state.Combo = 0
        remotes.CombatFX:FireAllClients("M1Finisher", target.root.Position)
    end

    if hit then
        PerfectComboService:Record(player, "M1")
        QuestService:Record(player, "M1", 1, player:GetAttribute("CharacterId"))
    end
    return hit
end

local function heavy(player)
    if not canCombat(player) or not ready(player, "Heavy") then return false end
    setCooldown(player, "Heavy", Config.Combat.Heavy.Cooldown)
    QuestService:Record(player, "Heavy", 1, player:GetAttribute("CharacterId"))
    local attackRoot = rootOf(player)
    if attackRoot then
        remotes.CombatFX:FireAllClients("Heavy", attackRoot.Position, {
            character=player:GetAttribute("CharacterId"),
            direction=attackRoot.CFrame.LookVector
        })
    end
    local target = HitboxService.NearestTargetInFront(player, Config.Combat.Heavy.Range, Config.Combat.Heavy.Width, Config.Combat.Heavy.Height)
    if not target then return false end
    return context.damage(player, target.humanoid, Config.Combat.Heavy.Damage, {
        stun=Config.Combat.Heavy.Stun,
        knockback=Config.Combat.Heavy.Knockback,
        tag="Heavy"
    })
end

local function dash(player)
    local state = states[player]
    local root = rootOf(player)
    if not state or not root or not canCombat(player) or not ready(player, "Dash") then return false end

    setCooldown(player, "Dash", Config.Combat.Dash.Cooldown)
    QuestService:Record(player, "Dash", 1, player:GetAttribute("CharacterId"))
    state.Dodging = true
    state.DodgeUntil = now() + Config.Combat.Dash.Duration
    root.AssemblyLinearVelocity = root.CFrame.LookVector * Config.Combat.Dash.Speed
    remotes.CombatFX:FireAllClients("Dash", root.Position, {
        character=player:GetAttribute("CharacterId"),
        direction=root.CFrame.LookVector
    })

    task.delay(Config.Combat.Dash.Duration, function()
        if state then state.Dodging = false end
    end)
    return true
end

local function dodge(player)
    local state = states[player]
    if not state or not canCombat(player) or not ready(player, "Dodge") then return false end

    setCooldown(player, "Dodge", Config.Combat.Dodge.Cooldown)
    QuestService:Record(player, "Dodge", 1, player:GetAttribute("CharacterId"))
    state.Dodging = true
    state.DodgeUntil = now() + Config.Combat.Dodge.IFrame

    task.delay(Config.Combat.Dodge.IFrame, function()
        if state then state.Dodging = false end
    end)
    return true
end

local function grab(player)
    if not canCombat(player) or not ready(player, "Grab") then return false end
    setCooldown(player, "Grab", Config.Combat.Grab.Cooldown)
    QuestService:Record(player, "Grab", 1, player:GetAttribute("CharacterId"))
    local attackRoot = rootOf(player)
    if attackRoot then
        remotes.CombatFX:FireAllClients("Grab", attackRoot.Position, {
            character=player:GetAttribute("CharacterId"),
            direction=attackRoot.CFrame.LookVector
        })
    end
    local target = HitboxService.NearestTargetInFront(player, Config.Combat.Grab.Range, Config.Combat.Grab.Width, Config.Combat.Grab.Height)
    if not target then return false end
    return context.damage(player, target.humanoid, Config.Combat.Grab.Damage, {
        stun=Config.Combat.Grab.Stun,
        knockback=8,
        tag="Grab"
    })
end

local function setBlock(player, active)
    local state = states[player]
    if not state or state.StunnedUntil > now() or state.Clash then return false end
    if active == state.Blocking then return false end

    state.Blocking = active
    player:SetAttribute("Blocking", active)

    if active then
        QuestService:Record(player, "Block", 1, player:GetAttribute("CharacterId"))
        local attackRoot = rootOf(player)
        if attackRoot then
            remotes.CombatFX:FireAllClients("Block", attackRoot.Position, {
                character=player:GetAttribute("CharacterId")
            })
        end
        state.PerfectBlockUntil = now() + Config.Combat.Block.PerfectWindow
        setMovement(player, 8, 0)
    else
        state.PerfectBlockUntil = 0
        if state.StunnedUntil <= now() then setMovement(player, 16, 50) end
    end
    return true
end

local function awaken(player)
    local state = states[player]
    if not state or state.Awakening or state.Clash then return false end
    if (player:GetAttribute("Awakening") or 0) < Config.Awakening.MinToActivate then return false end

    state.Awakening = true
    player:SetAttribute("Awakening", 0)
    player:SetAttribute("AwakeningActive", true)
    PerfectComboService:OnAwakening(player)
    CharacterService:Awaken(player)
    QuestService:Record(player, "Awaken", 1, player:GetAttribute("CharacterId"))
    remotes.CombatFX:FireAllClients("Awakening", context.rootPosition(player), player:GetAttribute("CharacterId"))

    task.delay(Config.Awakening.Duration, function()
        if not player.Parent then return end
        state.Awakening = false
        player:SetAttribute("AwakeningActive", false)
        PerfectComboService:End(player)
        OneTimeAttackService:End(player)
        setMovement(player, 16, 50)
        remotes.CombatFX:FireAllClients("AwakeningEnd", context.rootPosition(player))
    end)
    return true
end

local function domain(player)
    local state = states[player]
    if not state or state.Clash or state.Awakening or not ready(player, "Domain") then return false end

    local result = CharacterService:Domain(player)
    if not result then return false end

    setCooldown(player, "Domain", Config.Domain.Cooldown)
    local started = DomainClashService:TryStart(player)
    QuestService:Record(player, "Domain", 1, player:GetAttribute("CharacterId"))
    remotes.CombatFX:FireAllClients(started and "DomainClashStart" or "DomainStart", context.rootPosition(player), player:GetAttribute("CharacterId"))
    return true
end

local function characterAction(player, action)
    local state = states[player]
    if not state then return false end

    if action == "Special" and state.Clash then
        if not ready(player, "ClashSpecial") then return false end
        setCooldown(player, "ClashSpecial", 0.8)
        return DomainClashService:Special(player)
    end

    if action ~= "Special" and action ~= "Skill" then return false end
    if not canCombat(player) or not ready(player, action) then return false end

    setCooldown(player, action, CharacterService:GetCooldown(player, action))
    local success = CharacterService:Special(player, action)
    if success then
        PerfectComboService:Record(player, action)
        QuestService:Record(player, action, 1, player:GetAttribute("CharacterId"))
    end
    return success
end

local function oneTime(player)
    local success = OneTimeAttackService:TryUse(player, CharacterService)
    if success then
        PerfectComboService:End(player)
        QuestService:Record(player, "OneTime", 1, player:GetAttribute("CharacterId"))
        remotes.CombatFX:FireAllClients("OneTimeAttack", context.rootPosition(player), player:GetAttribute("CharacterId"))
    end
    return success
end

local function handle(player, action)
    if type(action) ~= "string" or #action > 32 or not states[player] then return end
    if not allowAction(player) then return end

    if action == "M1" then
        m1(player)
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
    if type(action) ~= "string" or #action > 32 or not states[player] then return end
    if payload ~= nil and type(payload) ~= "number" and type(payload) ~= "string" and type(payload) ~= "boolean" then return end

    if action == "ClashMove" then
        if type(payload) == "number" and allowAction(player) then
            DomainClashService:Move(player, payload)
        end
        return
    end

    handle(player, action)
end)

remotes.Selection.OnServerEvent:Connect(function(player, characterId)
    if type(characterId) ~= "string" or #characterId > 32 or not allowAction(player) then return end
    CharacterService:Select(player, characterId)
end)

local function setupPlayer(player)
    states[player] = {
        Combo=0,
        LastM1=0,
        StunnedUntil=0,
        Blocking=false,
        Dodging=false,
        DodgeUntil=0,
        PerfectBlockUntil=0,
        Awakening=false,
        Clash=false,
        Domain=false,
        Momentum=0,
        BlackFlashWindow=nil
    }

    actionWindows[player] = nil
    cooldowns[player] = {}

    CharacterService:Initialize(player)
    OneTimeAttackService:Initialize(player)

    player.CharacterAdded:Connect(function(character)
        DomainClashService:Cancel(player)
        DomainService:Stop(player)

        local humanoid = character:WaitForChild("Humanoid")
        local state = states[player]
        if not state then return end

        state.Combo=0
        state.LastM1=0
        state.StunnedUntil=0
        state.Blocking=false
        state.Dodging=false
        state.DodgeUntil=0
        state.PerfectBlockUntil=0
        state.Awakening=false
        state.Clash=false
        state.Domain=false
        state.Momentum=0
        state.BlackFlashWindow=nil

        cooldowns[player] = {}
        player:SetAttribute("Awakening", 0)
        player:SetAttribute("AwakeningActive", false)
        player:SetAttribute("DomainActive", false)
        player:SetAttribute("InClash", false)
        player:SetAttribute("Blocking", false)
        player:SetAttribute("ClashOpening", false)

        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        CharacterService:Initialize(player)
        OneTimeAttackService:Initialize(player)
    end)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
    DomainClashService:Cancel(player)
    DomainService:Stop(player)
    PerfectComboService:Reset(player)
    OneTimeAttackService:End(player)
    states[player]=nil
    actionWindows[player]=nil
    cooldowns[player]=nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end