--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Profiles = require(ReplicatedStorage.Characters.CharacterDefinitions)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)
local Moves = require(ReplicatedStorage.Characters.CharacterMoves)

local CharacterKit = {}

local function rootOf(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function front(ctx: any, player: Player, range: number, width: number, height: number)
    return ctx.hitbox:NearestTargetInFront(player, range, width, height)
end

local function area(ctx: any, player: Player, radius: number)
    return ctx.hitbox:TargetsInRadius(player, radius)
end

local function isEmpowered(player: Player): boolean
    return player:GetAttribute("AwakeningActive") == true
        or player:GetAttribute("UltimateActive") == true
end

local function announce(
    ctx: any,
    player: Player,
    characterId: string,
    action: string,
    moveName: string,
    payload: {[string]: any}?
)
    local root = rootOf(player)
    if not root then
        return
    end

    local data = payload or {}
    data.character = characterId
    data.action = action
    data.move = moveName
    data.actor = player.Character
    data.direction = root.CFrame.LookVector

    ctx.fx("CharacterMove", root.Position, data)
end

local function applyHit(
    ctx: any,
    player: Player,
    target: any,
    move: any,
    damage: number,
    tag: string
): boolean
    if not target or not target.humanoid then
        return false
    end

    local state = ctx.getState(player)
    local attackId = state
        and state.Vars
        and state.Vars.ActiveAttackId

    if attackId and ctx.hitRegistry then
        if ctx.hitRegistry:Has(player, attackId, target.model) then
            return false
        end
        ctx.hitRegistry:Add(player, attackId, target.model)
    end

    local root = rootOf(player)
    local direction = root and root.CFrame.LookVector or Vector3.zAxis

    return ctx.damage(
        player,
        target.humanoid,
        math.max(0, damage),
        {
            stun = math.max(0, tonumber(move.Stun) or 0.2),
            knockback = math.max(0, tonumber(move.Knockback) or 0),
            direction = direction,
            guardBreak = move.GuardBreak == true or move.Type == "Burst",
            ragdoll = move.Ragdoll == true,
            ragdollDuration = move.Ragdoll and 0.48 or nil,
            launch = move.Launch == true,
            slam = move.Slam == true,
            reaction = move.Type == "Burst" and "Heavy" or "Skill",
            tag = tag
        }
    )
end

local function executeMove(ctx: any, player: Player, move: any, damage: number): boolean
    local tag = tostring(move.Tag or move.Name):gsub("%W", "")

    if move.Type == "Melee" then
        return applyHit(
            ctx,
            player,
            front(ctx, player, tonumber(move.Range) or 9, 8, 8),
            move,
            damage,
            tag
        )
    end

    if move.Type == "Projectile" then
        local target = front(
            ctx,
            player,
            tonumber(move.Range) or 24,
            8,
            8
        )

        local success = applyHit(ctx, player, target, move, damage, tag)

        if success and target then
            ctx.fx("ProjectileImpact", target.root.Position, {
                actor = target.model,
                character = player:GetAttribute("CharacterId"),
                move = move.Name,
                tag = tag
            })
        end

        return success
    end

    if move.Type == "Area" or move.Type == "Burst" then
        local success = false

        for _, target in ipairs(area(
            ctx,
            player,
            tonumber(move.Radius) or 10
        )) do
            if applyHit(ctx, player, target, move, damage, tag) then
                success = true
            end
        end

        return success
    end

    if move.Type == "Control" then
        local target = if move.Radius
            then area(ctx, player, tonumber(move.Radius) or 10)[1]
            else front(ctx, player, tonumber(move.Range) or 12, 9, 8)

        local success = applyHit(ctx, player, target, move, damage, tag)

        if success and target and move.Pull then
            local root = rootOf(player)
            if root then
                local delta = root.Position - target.root.Position
                if delta.Magnitude > 0.01 then
                    target.root.AssemblyLinearVelocity =
                        delta.Unit * tonumber(move.Pull)
                        + Vector3.new(0, 10, 0)
                end
            end
        end

        return success
    end

    return false
end

local function sync(player: Player, vars: {[string]: any})
    for key, value in pairs(vars) do
        if type(value) == "string"
            or type(value) == "number"
            or type(value) == "boolean" then
            player:SetAttribute(key, value)
        end
    end
end

local function freshVars(): {[string]: any}
    return {
        Momentum = 0,
        Infinity = false,
        InfinityUntil = 0,
        ShrineMode = "Dismantle",
        TenShadowsMode = "Divine Dog",
        ShadowCharge = 0
    }
end

function CharacterKit.Build(id: string)
    local profile = Profiles[id]
    if not profile then
        error("Unknown playable character: " .. id)
    end

    local module = {}

    function module.Init(player: Player, ctx: any)
        local state = ctx.getState(player)
        state.Vars = freshVars()

        player:SetAttribute("CharacterId", id)
        player:SetAttribute("CharacterName", profile.Name)
        player:SetAttribute("CharacterTitle", profile.Subtitle)
        player:SetAttribute("UniqueState", profile.Unique)
        player:SetAttribute("SpecialName", Moves[id].SpecialName)
        player:SetAttribute("AwakeningName", profile.AwakeningName)

        sync(player, state.Vars)
    end

    function module.GetMoves(player: Player?)
        return Movesets.Get(
            id,
            player ~= nil and isEmpowered(player)
        )
    end

    function module.GetCooldown(action: string, slot: number?): number
        if action == "Special" then
            return math.clamp(profile.SpecialCooldown, 0.25, 20)
        end

        if action == "Skill" and slot then
            local move = Movesets.GetMove(id, slot, false)
            return math.clamp(
                tonumber(move and move.Cooldown) or profile.SkillCooldown,
                0.25,
                10
            )
        end

        return profile.SkillCooldown
    end

    function module.SkillSlot(player: Player, ctx: any, slot: number): boolean
        local empowered = isEmpowered(player)
        local move = Movesets.GetMove(id, slot, empowered)

        if not move then
            return false
        end

        local state = ctx.getState(player)
        state.Vars.ActiveMove = move

        local vars = state.Vars
        local damage = tonumber(move.Damage) or 0

        if id == "Yuji" then
            damage += math.min(8, tonumber(vars.Momentum) or 0) * 1.5
            if slot == 3 then
                damage += math.min(8, tonumber(vars.Momentum) or 0) * 2
            end
        elseif id == "Gojo" then
            if slot == 1 then
                vars.Infinity = false
                vars.InfinityUntil = os.clock() + 0.55
            elseif slot == 2 then
                vars.Infinity = false
                vars.InfinityUntil = 0
            elseif slot == 4 then
                damage += empowered and 8 or 0
            end
        elseif id == "Sukuna" then
            vars.ShrineMode = ({
                [1] = "Dismantle",
                [2] = "Cleave",
                [3] = "Flame",
                [4] = "WorldCut"
            })[slot] or vars.ShrineMode
            damage += slot == 4 and 8 or 0
        elseif id == "Megumi" then
            vars.TenShadowsMode = ({
                [1] = "Divine Dog",
                [2] = "Nue",
                [3] = "Max Elephant",
                [4] = "Totality"
            })[slot] or vars.TenShadowsMode
            damage += (tonumber(vars.ShadowCharge) or 0) * 0.04
        end

        sync(player, vars)

        announce(ctx, player, id, "Skill" .. tostring(slot), move.Name, {
            slot = slot,
            awakened = empowered
        })

        local success = executeMove(ctx, player, move, damage)

        if success and id == "Yuji" then
            vars.Momentum = math.min(
                8,
                (tonumber(vars.Momentum) or 0) + (slot == 3 and 2 or 1)
            )
            sync(player, {Momentum = vars.Momentum})
        elseif success and id == "Megumi" then
            vars.ShadowCharge = math.min(
                100,
                (tonumber(vars.ShadowCharge) or 0) + 18
            )
            sync(player, {ShadowCharge = vars.ShadowCharge})
        end

        return success
    end

    function module.Special(player: Player, ctx: any): boolean
        local state = ctx.getState(player)
        local vars = state.Vars
        local empowered = isEmpowered(player)

        local move: any
        local damage: number

        if id == "Yuji" then
            move = Movesets.GetMove(id, empowered and 4 or 3, empowered)
            damage = (empowered and 52 or 42)
                + math.min(8, tonumber(vars.Momentum) or 0) * 2.5
            vars.Momentum = 0
        elseif id == "Gojo" then
            move = Movesets.GetMove(id, 1, empowered)
            damage = empowered and 38 or 28
            vars.Infinity = true
            vars.InfinityUntil = os.clock() + 0.95
            state.InvulnerableUntil = math.max(
                state.InvulnerableUntil,
                vars.InfinityUntil
            )
        elseif id == "Sukuna" then
            move = Movesets.GetMove(id, empowered and 4 or 2, empowered)
            damage = empowered and 46 or 30
            vars.ShrineMode = "Cleave"
        else
            move = Movesets.GetMove(id, empowered and 4 or 1, empowered)
            damage = empowered and 44 or 24
            vars.ShadowCharge = math.min(
                100,
                (tonumber(vars.ShadowCharge) or 0) + 25
            )
            vars.TenShadowsMode = empowered and "Chimera" or "Shadow Step"
        end

        state.Vars.ActiveMove = move
        sync(player, vars)

        announce(ctx, player, id, "Special", move.Name, {
            awakened = empowered,
            power = damage
        })

        return executeMove(ctx, player, move, damage)
    end

    function module.OnIncomingDamage(
        player: Player,
        ctx: any,
        amount: number,
        meta: any
    ): number
        if id ~= "Gojo" then
            return amount
        end

        local state = ctx.getState(player)
        local vars = state.Vars
        local now = os.clock()

        if (vars.Infinity == true or vars.InfinityUntil > now)
            and meta.guardBreak ~= true then
            return 0
        end

        return amount
    end

    function module.OnM1Hit(
        player: Player,
        ctx: any,
        combo: number,
        success: boolean
    )
        if not success then
            return
        end

        local state = ctx.getState(player)
        local vars = state.Vars

        if id == "Yuji" then
            vars.Momentum = math.min(
                8,
                (tonumber(vars.Momentum) or 0) + 1
            )
            sync(player, {Momentum = vars.Momentum})
        elseif id == "Sukuna" then
            vars.ShrineMode = combo == 4 and "Cleave" or "Dismantle"
            sync(player, {ShrineMode = vars.ShrineMode})
        elseif id == "Megumi" then
            vars.ShadowCharge = math.min(
                100,
                (tonumber(vars.ShadowCharge) or 0) + 8
            )
            sync(player, {ShadowCharge = vars.ShadowCharge})
        end
    end

    return module
end

return CharacterKit
