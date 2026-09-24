--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local RigAnimator: any = require(script.Parent.Controllers.AnimationConstraintAnimator)

local remotes = RemoteService:Get()
local bound: {[Model]: boolean} = {}

local function movementState(humanoid: Humanoid): string
    local state = humanoid:GetState()

    if state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.Freefall
        or state == Enum.HumanoidStateType.FallingDown then
        if state == Enum.HumanoidStateType.Jumping then
            return "Jump"
        end
        return "Fall"
    end

    local magnitude = humanoid.MoveDirection.Magnitude
    local speed = humanoid.WalkSpeed

    if magnitude < 0.05 then
        return "Idle"
    end

    if speed >= 21 then
        return "Sprint"
    end

    if speed >= 18 then
        return "Running"
    end

    return "Walking"
end

local function bind(character: Model)
    if bound[character] then
        return
    end

    if RigAnimator:Bind(character) then
        bound[character] = true
    end
end

local function eachCharacter(callback: (Model, Humanoid) -> ())
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if character and humanoid then
            callback(character, humanoid)
        end
    end
end

local function onCharacter(character: Model)
    bind(character)
    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            bound[character] = nil
            RigAnimator:Unbind(character)
        end
    end)
end

local function onPlayer(player: Player)
    if player.Character then
        onCharacter(player.Character)
    end
    player.CharacterAdded:Connect(onCharacter)
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayer(player)
end

Players.PlayerAdded:Connect(onPlayer)

remotes.CombatFX.OnClientEvent:Connect(function(kind: string, _position: Vector3, payload: any)
    if type(payload) ~= "table" then
        return
    end

    local actor = payload.actor
    if not actor or not actor:IsA("Model") then
        return
    end

    bind(actor)

    if kind == "CombatAction" then
        local action = tostring(payload.action or "")
        if action == "M1Start" then
            local combo = math.clamp(math.floor(tonumber(payload.combo) or 1), 1, 4)
            RigAnimator:Play(actor, "M1_" .. tostring(combo), payload)
        elseif action == "SkillStart" or action == "SpecialStart" then
            RigAnimator:Play(actor, tostring(payload.move or action), payload)
        elseif action == "Dash" then
            RigAnimator:Play(actor, "Dash", payload)
        end
    elseif kind == "Hit" then
        RigAnimator:HitReact(
            actor,
            tonumber(payload.damage) or 1,
            tostring(payload.reaction or "Light")
        )
    elseif kind == "PerfectBlock" then
        RigAnimator:HitReact(actor, 1.4, "Parry")
    elseif kind == "Death" then
        RigAnimator:HitReact(actor, 2, "Death")
    elseif kind == "Awakening" or kind == "Ultimate" then
        RigAnimator:Play(actor, "Awakening", payload)
    end
end)

local accumulator = 0

RunService.PreSimulation:Connect(function(dt)
    accumulator += dt
    local now = os.clock()

    eachCharacter(function(character, humanoid)
        if not bound[character] then
            bind(character)
        end

        if bound[character] then
            local state = movementState(humanoid)
            RigAnimator:UpdateLocomotion(character, state, humanoid.MoveDirection.Magnitude)
        end
    end)

    if accumulator >= (1 / 60) then
        accumulator = 0
        RigAnimator:StepAll(now)
    end
end)