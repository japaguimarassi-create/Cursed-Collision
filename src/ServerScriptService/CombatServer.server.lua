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
local StateManager = require(script.Parent.CombatCore.StateManager)
local CooldownService = require(script.Parent.CombatCore.CooldownService)
local NetworkService = require(script.Parent.CombatCore.NetworkService)
local AntiExploitService = require(script.Parent.CombatCore.AntiExploitService)
local MovementController = require(script.Parent.CombatCore.MovementController)
local DamageService = require(script.Parent.CombatCore.DamageService)
local DestructionService = require(script.Parent.CombatCore.DestructionService)
local CombatController = require(script.Parent.CombatCore.CombatController)

local remotes = RemoteService:Get()
local states = {}
local combatController = CombatController.new()

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

local function setMovement(player, speed, jump, autoRotate)
    MovementController:Set(player, speed, jump, autoRotate)
end

local function setCooldown(player, action, duration)
    CooldownService:Set(player, action, duration, now())
end

local function ready(player, action)
    return CooldownService:Ready(player, action, now())
end

local function allowAction(player)
    return AntiExploitService:AllowAction(player, Config.AntiCheat.MaxActions, Config.AntiCheat.Window)
end

local function canCombat(player)
    local state = states[player]
    local humanoid = humanoidOf(player)
    return state and humanoid and humanoid.Health > 0 and state.StunnedUntil <= now() and not state.Clash and not state.Blocking
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

context.hitbox = HitboxService
context.domain = DomainService

context.environmentImpact = function(origin, radius, power)
    local changed = DestructionService:Impact(origin, radius, power)
    if changed > 0 then
        remotes.CombatFX:FireAllClients("EnvironmentBreak", origin, {
            radius = radius,
            count = changed,
            power = power,
        })
    end
    return changed
end

function context.rootPosition(player)
    local root = rootOf(player)
    return root and root.Position or Vector3.zero
end

function context.fx(kind, ...)
    remotes.CombatFX:FireAllClients(kind, ...)
end

function context.account(player, eventName, payload)
    remotes.AccountEvent:FireClient(player, eventName, payload)
end

function context.damage(attacker, humanoid, amount, meta)
    return DamageService:Apply(attacker, humanoid, amount, meta)
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
DamageService:Configure(context)

local function isAirborne(player)
    local humanoid = humanoidOf(player)
    if not humanoid then
        return false
    end
    local current = humanoid:GetState()
    return current == Enum.HumanoidStateType.Jumping
        or current == Enum.HumanoidStateType.Freefall
        or current == Enum.HumanoidStateType.FallingDown
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
            direction=attackRoot.CFrame.LookVector,
            actor=player.Character
        })
    end
    if attackRoot then
        remotes.CombatFX:FireAllClients("CharacterMove", attackRoot.Position, {
            character=player:GetAttribute("CharacterId"),
            action="M1",
            move="M1",
            actor=player.Character
        })
    end

    local target = HitboxService.NearestTargetInFront(player, Config.Combat.M1.Range, Config.Combat.M1.Width, Config.Combat.M1.Height)
    if not target then return false end

    local airborne = isAirborne(player)
    local damageTable = airborne and Config.Combat.M1.AirDamage or Config.Combat.M1.Damage
    local damage = damageTable[state.Combo]
    if player:GetAttribute("CharacterId") == "Yuji" then
        damage += state.Momentum or 0
    end

    local finisher = state.Combo == 4
    local hit = context.damage(player, target.humanoid, damage, {
        stun = airborne and Config.Combat.M1.AirStun or Config.Combat.M1.Stun,
        knockback = finisher and (airborne and 18 or 32) or 10,
        lift = finisher and 7 or 3,
        launch = finisher and not airborne,
        launchPower = Config.Combat.M1.LauncherPower,
        wallCheck = finisher,
        reaction = airborne and "Air" or (finisher and "Launcher" or "Light"),
        tag = airborne and "AirM1" or "M1"
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
            direction=attackRoot.CFrame.LookVector,
            actor=player.Character
        })
    end
    if attackRoot then
        remotes.CombatFX:FireAllClients("CharacterMove", attackRoot.Position, {
            character=player:GetAttribute("CharacterId"),
            action="Heavy",
            move="Heavy",
            actor=player.Character
        })
    end
    local target = HitboxService.NearestTargetInFront(player, Config.Combat.Heavy.Range, Config.Combat.Heavy.Width, Config.Combat.Heavy.Height)
    if not target then return false end

    local airborne = isAirborne(player)
    return context.damage(player, target.humanoid, airborne and Config.Combat.Heavy.AirDamage or Config.Combat.Heavy.Damage, {
        stun = airborne and 0.42 or Config.Combat.Heavy.Stun,
        knockback = airborne and Config.Combat.Heavy.AirKnockback or Config.Combat.Heavy.Knockback,
        lift = airborne and 2 or 10,
        launch = not airborne,
        launchPower = Config.Combat.Heavy.LauncherPower,
        wallCheck = true,
        ragdoll = true,
        reaction = airborne and "Slam" or "Heavy",
        tag = airborne and "AirHeavy" or "Heavy"
    })
end

local function dashVector(root, direction)
    if direction == "Back" then
        return -root.CFrame.LookVector
    elseif direction == "Left" then
        return -root.CFrame.RightVector
    elseif direction == "Right" then
        return root.CFrame.RightVector
    end

    local humanoid = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
        return humanoid.MoveDirection.Unit
    end

    return root.CFrame.LookVector
end

local function dash(player, direction)
    local state = states[player]
    local root = rootOf(player)
    if not state or not root or not canCombat(player) or not ready(player, "Dash") then return false end

    setCooldown(player, "Dash", Config.Combat.Dash.Cooldown)
    QuestService:Record(player, "Dash", 1, player:GetAttribute("CharacterId"))

    state.Dodging = true
    state.DodgeUntil = now() + Config.Combat.Dash.Duration

    direction = NetworkService:SanitizeDashDirection(direction)
    local dashDir = dashVector(root, direction)
    local speed = direction == "Back" and Config.Combat.Dash.BackSpeed
        or (direction == "Forward" and Config.Combat.Dash.Speed or Config.Combat.Dash.SideSpeed)

    root.AssemblyLinearVelocity = dashDir * speed + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)

    remotes.CombatFX:FireAllClients("Dash", root.Position, {
        character=player:GetAttribute("CharacterId"),
        direction=dashDir,
        dashType=direction,
        actor=player.Character
    })

    remotes.CombatFX:FireAllClients("CharacterMove", root.Position, {
        character=player:GetAttribute("CharacterId"),
        action="Dash",
        move="Dash",
        actor=player.Character,
    })

    task.delay(Config.Combat.Dash.Duration, function()
        if state then
            state.Dodging = false
        end
    end)

    if direction == "Forward" then
        local hitTarget = HitboxService.NearestTargetInFront(player, Config.Combat.Dash.AttackRange, Config.Combat.Dash.AttackWidth, Config.Combat.Dash.AttackHeight)
        if hitTarget and ready(player, "DashAttack") then
            setCooldown(player, "DashAttack", Config.Combat.Dash.Cooldown)
            context.damage(player, hitTarget.humanoid, 8, {
                stun=0.22,
                knockback=24,
                reaction="Light",
                tag="DashStrike"
            })
        end
    end

    return true
end

local function dodge(player)
    local state = states[player]
    local root = rootOf(player)
    if not state or not root or not canCombat(player) or not ready(player, "Dodge") then return false end

    setCooldown(player, "Dodge", Config.Combat.Dodge.Cooldown)
    QuestService:Record(player, "Dodge", 1, player:GetAttribute("CharacterId"))
    state.Dodging = true
    state.DodgeUntil = now() + Config.Combat.Dodge.IFrame

    local humanoid = humanoidOf(player)
    local move = humanoid and humanoid.MoveDirection or Vector3.zero
    local direction = move.Magnitude > 0.1 and move.Unit or root.CFrame.LookVector
    root.AssemblyLinearVelocity = direction * Config.Combat.Dodge.Speed + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)

    remotes.CombatFX:FireAllClients("Dodge", root.Position, {
        character=player:GetAttribute("CharacterId"),
        direction=direction,
        actor=player.Character
    })

    remotes.CombatFX:FireAllClients("CharacterMove", root.Position, {
        character=player:GetAttribute("CharacterId"),
        action="Dodge",
        move="Dash",
        actor=player.Character
    })

    task.delay(Config.Combat.Dodge.IFrame, function()
        if state then
            state.Dodging = false
        end
    end)

    return true
end

local function counter(player)
    local state = states[player]
    if not state or not canCombat(player) or not ready(player, "Counter") then return false end

    setCooldown(player, "Counter", Config.Combat.Counter.Cooldown)
    state.CounterUntil = now() + Config.Combat.Counter.Window
    state.Phase = "Attack"

    local root = rootOf(player)
    if root then
        remotes.CombatFX:FireAllClients("CharacterMove", root.Position, {
            character=player:GetAttribute("CharacterId"),
            action="Skill",
            move="Counter",
            actor=player.Character,
            reaction="Counter"
        })
    end

    task.delay(Config.Combat.Counter.Window, function()
        if state and state.CounterUntil <= now() then
            state.CounterUntil = 0
        end
    end)

    return true
end

local function slam(player)
    local state = states[player]
    local root = rootOf(player)
    if not state or not root or not isAirborne(player) or not ready(player, "Slam") then return false end

    setCooldown(player, "Slam", Config.Combat.Air.SlamCooldown)
    state.Phase = "Attack"
    root.AssemblyLinearVelocity = Vector3.new(
        root.AssemblyLinearVelocity.X,
        -Config.Combat.Air.SlamSpeed,
        root.AssemblyLinearVelocity.Z
    )

    local targets = HitboxService.AreaTargets(
        player,
        root.Position - Vector3.new(0, 2.5, 0),
        Config.Combat.M1.SlamRadius,
        6
    )

    for _, target in ipairs(targets) do
        context.damage(player, target.humanoid, Config.Combat.M1.SlamDamage, {
            stun=0.65,
            knockback=12,
            slam=true,
            slamPower=74,
            ragdoll=true,
            ragdollDuration=0.65,
            reaction="Slam",
            tag="Slam"
        })
    end

    remotes.CombatFX:FireAllClients("CharacterMove", root.Position, {
        character=player:GetAttribute("CharacterId"),
        action="Skill",
        move="Slam",
        actor=player.Character
    })

    return true
end

local function grab(player)(player)
    if not canCombat(player) or not ready(player, "Grab") then return false end
    setCooldown(player, "Grab", Config.Combat.Grab.Cooldown)
    QuestService:Record(player, "Grab", 1, player:GetAttribute("CharacterId"))
    local attackRoot = rootOf(player)
    if attackRoot then
        remotes.CombatFX:FireAllClients("Grab", attackRoot.Position, {
            character=player:GetAttribute("CharacterId"),
            direction=attackRoot.CFrame.LookVector,
            actor=player.Character
        })
    end
    if attackRoot then
        remotes.CombatFX:FireAllClients("CharacterMove", attackRoot.Position, {
            character=player:GetAttribute("CharacterId"),
            action="Grab",
            move="Grab",
            actor=player.Character
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
    remotes.CombatFX:FireAllClients(started and "DomainClashStart" or "DomainStart", context.rootPosition(player), {
        character = player:GetAttribute("CharacterId"),
        actor = player.Character,
        action = "Domain",
        move = "Domain Expansion"
    })
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

    local slot = tonumber(string.match(action, "^Skill(%d)$"))
    if action ~= "Special" and action ~= "Skill" and not slot then return false end
    if slot and (slot < 1 or slot > 4) then return false end
    if not canCombat(player) or not ready(player, action) then return false end

    local cooldown = CharacterService:GetCooldown(player, action)
    setCooldown(player, action, cooldown)
    local success
    if slot then
        success = CharacterService:SkillSlot(player, slot)
    else
        success = CharacterService:Special(player, action)
    end
    if success then
        local comboAction = slot == 1 and "Special" or "Skill"
        if not slot then comboAction = action end
        PerfectComboService:Record(player, comboAction)
        QuestService:Record(player, "Skill", 1, player:GetAttribute("CharacterId"))
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

combatController:Register("M1", function(player) return m1(player) end)
combatController:Register("Heavy", function(player) return heavy(player) end)
combatController:Register("Dash", function(player, payload) return dash(player, payload) end)
combatController:Register("DashAttack", function(player, payload) return dash(player, payload) end)
combatController:Register("Dodge", function(player) return dodge(player) end)
combatController:Register("Counter", function(player) return counter(player) end)
combatController:Register("Slam", function(player) return slam(player) end)
combatController:Register("Grab", function(player) return grab(player) end)
combatController:Register("BlockStart", function(player) return setBlock(player, true) end)
combatController:Register("BlockEnd", function(player) return setBlock(player, false) end)
combatController:Register("Special", function(player) return characterAction(player, "Special") end)
combatController:Register("Skill", function(player) return characterAction(player, "Skill") end)
combatController:Register("Skill1", function(player) return characterAction(player, "Skill1") end)
combatController:Register("Skill2", function(player) return characterAction(player, "Skill2") end)
combatController:Register("Skill3", function(player) return characterAction(player, "Skill3") end)
combatController:Register("Skill4", function(player) return characterAction(player, "Skill4") end)
combatController:Register("Awaken", function(player) return awaken(player) end)
combatController:Register("Domain", function(player) return domain(player) end)
combatController:Register("OneTime", function(player) return oneTime(player) end)

local function handle(player, action, payload)
    if type(action) ~= "string" or #action > 32 or not states[player] then
        return false
    end
    if not allowAction(player) then
        return false
    end
    return combatController:Dispatch(player, action, payload)
end
remotes.CombatAction.OnServerEvent:Connect(function(player, action, payload)
    if not NetworkService:IsKnownAction(action) or not states[player] then
        AntiExploitService:Flag(player)
        return
    end

    if not NetworkService:ValidatePayload(action, payload) then
        AntiExploitService:Flag(player)
        return
    end

    if action == "ClashMove" then
        if allowAction(player) then
            DomainClashService:Move(player, payload)
        end
        return
    end

    handle(player, action, payload)
end)

remotes.Selection.OnServerEvent:Connect(function(player, characterId)
    if type(characterId) ~= "string" or #characterId > 32 or not allowAction(player) then return end
    CharacterService:Select(player, characterId)
end)

local function setupPlayer(player)
    local state = StateManager:Init(player)
    states[player] = state
    player:SetAttribute("CombatValidationWarnings", 0)

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

        CooldownService:Clear(player)
        StateManager:ResetCombat(player)
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
    CooldownService:Clear(player)
    AntiExploitService:Clear(player)
    StateManager:Clear(player)
    states[player]=nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end