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
local HitboxService = require(ReplicatedStorage.Combat.HitboxService)

local remotes = RemoteService:Get()
local activePlayers = {}

local context = {}

function context.rootPosition(player: Player): Vector3
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    return if root and root:IsA("BasePart") then root.Position else Vector3.zero
end

function context.fx(kind: string, position: Vector3, payload: any)
    remotes.CombatFX:FireAllClients(kind, position, payload)
end

function context.damage(
    attacker: Player,
    humanoid: Humanoid,
    amount: number,
    meta: any
)
    return DamageService:Apply(
        attacker,
        humanoid,
        amount,
        meta
    )
end

context.hitbox = HitboxService

CharacterService:Configure(context)
DamageService:Configure(context)

local combat = CombatService.new(context)

local function allow(player: Player): boolean
    return AntiExploitService:AllowAction(
        player,
        Config.AntiCheat.MaxActions,
        Config.AntiCheat.Window
    )
end

local function setupPlayer(player: Player)
    StateManager:Init(player)
    activePlayers[player] = true

    player:SetAttribute("CombatStunned", false)
    player:SetAttribute("Blocking", false)

    CharacterService:Initialize(player)

    player.CharacterAdded:Connect(function()
        task.defer(function()
            StateManager:Reset(player)
            CooldownService:Clear(player)

            player:SetAttribute("CombatStunned", false)
            player:SetAttribute("Blocking", false)

            CharacterService:Initialize(player)

            local humanoid = player.Character
                and player.Character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                humanoid.WalkSpeed = Config.Movement.WalkSpeed
                humanoid.JumpPower = Config.Movement.JumpPower
            end
        end)
    end)
end

local function handle(player: Player, action: any, payload: any)
    if not NetworkService:IsKnownAction(action) then
        AntiExploitService:Flag(player)
        return
    end

    if not NetworkService:ValidatePayload(action, payload) then
        AntiExploitService:Flag(player)
        return
    end

    if not allow(player) then
        return
    end

    if action == "M1" then
        combat:M1(player)
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
    elseif action == "SelectCharacter" then
        CharacterService:Select(player, payload)
    end
end

remotes.CombatAction.OnServerEvent:Connect(function(
    player,
    action,
    payload
)
    if activePlayers[player] then
        handle(player, action, payload)
    end
end)

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
    CooldownService:Clear(player)
    AntiExploitService:Clear(player)
    StateManager:Clear(player)
    activePlayers[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

RunService.Heartbeat:Connect(function()
    for player in pairs(activePlayers) do
        combat:StepPlayer(player)
    end
end)