--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)

local StateManager = require(script.Parent.CombatCore.StateManager)
local CooldownService = require(script.Parent.CombatCore.CooldownService)
local NetworkService = require(script.Parent.CombatCore.NetworkService)
local AntiExploitService = require(script.Parent.CombatCore.AntiExploitService)
local DamageService = require(script.Parent.CombatCore.DamageService)
local CombatService = require(script.Parent.CombatCore.CombatService)
local CombatMarkerService = require(script.Parent.CombatCore.CombatMarkerService)
local HitboxService = require(ReplicatedStorage.Combat.HitboxService)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)
local UltimateService = require(script.Parent.CombatCore.UltimateService)
local MovementController = require(script.Parent.CombatCore.MovementController)

local remotes = RemoteService:Get()
local activePlayers: {[Player]: boolean} = {}

type Context = {
    rootPosition: (Player) -> Vector3,
    fx: (string, Vector3, {[string]: any}) -> (),
    damage: (Player, Humanoid, number, {[string]: any}) -> boolean,
    hitbox: any,
    hitRegistry: any,
    getState: (Player) -> any
}

local context: Context = {
    rootPosition = function(player: Player): Vector3
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        return if root and root:IsA("BasePart")
            then root.Position
            else Vector3.zero
    end,

    fx = function(kind: string, position: Vector3, payload: {[string]: any})
        remotes.CombatFX:FireAllClients(kind, position, payload)
    end,

    damage = function(
        attacker: Player,
        humanoid: Humanoid,
        amount: number,
        meta: {[string]: any}
    ): boolean
        return DamageService:Apply(attacker, humanoid, amount, meta)
    end,

    hitbox = HitboxService,
    hitRegistry = HitRegistry,

    getState = function(player: Player)
        return StateManager:Get(player)
    end
}

CharacterService:Configure(context)
DamageService:Configure(context)

local combat: any = CombatService.new(context)

local function allow(player: Player): boolean
    return AntiExploitService:AllowAction(
        player,
        Config.AntiCheat.MaxActions,
        Config.AntiCheat.Window
    )
end

local function ensureAnimator(player: Player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return
    end

    if not humanoid:FindFirstChildOfClass("Animator") then
        local animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
end

local function setupPlayer(player: Player)
    StateManager:Init(player)
    activePlayers[player] = true

    player:SetAttribute("CombatStunned", false)
    player:SetAttribute("Stunned", false)
    player:SetAttribute("Blocking", false)
    player:SetAttribute("IsAttacking", false)
    player:SetAttribute("Ragdolled", false)

    CharacterService:Initialize(player)
    UltimateService:Init(player)
    ensureAnimator(player)
end

local function resetCharacter(player: Player)
    StateManager:Reset(player)
    CooldownService:Clear(player)
    HitRegistry:Clear(player)
    CombatMarkerService:Clear(player)
    MovementController:Clear(player)

    player:SetAttribute("CombatStunned", false)
    player:SetAttribute("Stunned", false)
    player:SetAttribute("Blocking", false)
    player:SetAttribute("IsAttacking", false)
    player:SetAttribute("Ragdolled", false)

    CharacterService:Initialize(player)
    UltimateService:Init(player)
    ensureAnimator(player)

    local humanoid = player.Character
        and player.Character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.WalkSpeed = Config.Movement.WalkSpeed
        humanoid.JumpPower = Config.Movement.JumpPower
    end
end

local function handleCombatAction(
    player: Player,
    action: any,
    payload: any
)
    if not NetworkService:IsKnownAction(action)
        or not NetworkService:ValidatePayload(action, payload) then
        AntiExploitService:Flag(player)
        return
    end

    if not allow(player) then
        return
    end

    if action == "M1" then
        combat:M1(player)
    elseif action == "M1Hit" then
        combat:M1Hit(player, payload.attackId)
    elseif action == "Dash" then
        combat:Dash(
            player,
            NetworkService:SanitizeDashDirection(payload)
        )
    elseif action == "BlockStart" then
        combat:SetBlock(player, true)
    elseif action == "BlockEnd" then
        combat:SetBlock(player, false)
    elseif action == "Special" then
        combat:Special(player)
    elseif action == "Skill1" then
        combat:SkillSlot(player, 1)
    elseif action == "Skill2" then
        combat:SkillSlot(player, 2)
    elseif action == "Skill3" then
        combat:SkillSlot(player, 3)
    elseif action == "Skill4" then
        combat:SkillSlot(player, 4)
    elseif action == "M1Hit"
        or action == "SkillHit"
        or action == "SpecialHit" then
        CombatMarkerService:Resolve(
            player,
            payload.attackId
        )
    elseif action == "SelectCharacter" then
        CharacterService:Select(player, payload)
    elseif action == "Ultimate" then
        UltimateService:Activate(player, "Ultimate")
    elseif action == "Awakening" then
        UltimateService:Activate(player, "Awakening")
    end
end

remotes.CombatAction.OnServerEvent:Connect(function(
    player: Player,
    action: any,
    payload: any
)
    if activePlayers[player] then
        handleCombatAction(player, action, payload)
    end
end)

remotes.MovementRemote.OnServerEvent:Connect(function(
    player: Player,
    action: any,
    payload: any
)
    if not activePlayers[player]
        or type(action) ~= "string"
        or #action > 24
        or payload ~= nil then
        return
    end

    if not allow(player) then
        return
    end

    if action == "SprintStart" then
        MovementController:SetSprinting(player, true)
    elseif action == "SprintEnd" then
        MovementController:SetSprinting(player, false)
    end
end)

Players.PlayerAdded:Connect(function(player)
    setupPlayer(player)

    player.CharacterAdded:Connect(function()
        task.defer(function()
            if activePlayers[player] then
                resetCharacter(player)
            end
        end)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    activePlayers[player] = nil
    CooldownService:Clear(player)
    HitRegistry:Clear(player)
    CombatMarkerService:Clear(player)
    MovementController:Clear(player)
    AntiExploitService:Clear(player)
    StateManager:Clear(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)

    player.CharacterAdded:Connect(function()
        task.defer(function()
            if activePlayers[player] then
                resetCharacter(player)
            end
        end)
    end)
end

RunService.Heartbeat:Connect(function(dt)
    for player in pairs(activePlayers) do
        combat:StepPlayer(player)
        MovementController:Step(player, dt)
    end
end)
