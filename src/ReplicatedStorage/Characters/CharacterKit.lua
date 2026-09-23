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

local function awakened(player: Player): boolean
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

local function hit(
    ctx: any,
    player: Player,
    target: any,
    move: any,
    damage: number,
    attackTag: string,
    extra: any?
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
    local meta = {
        stun = math.max(0, tonumber(move.Stun) or 0.2),
        knockback = math.max(0, tonumber(move.Knockback) or 0),
        direction = direction,
        guardBreak = move.GuardBreak == true or move.Type == "Burst",
        ragdoll = move.Ragdoll == true,
        ragdollDuration = move.Ragdoll and 0.48 or nil,
        launch = move.Launch == true,
        slam = move.Slam == true,
        reaction = move.Type == "Burst" and "Heavy" or "Skill",
        tag = attackTag
    }

    for key, value in pairs(extra or {}) do
        (meta :: any)[key] = value
    end

    return ctx.damage(
        player,
        target.humanoid,
        math.max(0, damage),
        meta
    )
end

local function pulse(
    ctx: any,
    player: Player,
    move: any,
    damage: number,
    attackTag: string
): boolean
    local success = false

    for _, target in ipairs(area(
        ctx,
        player,
        tonumber(move.Radius) or 10
    )) do
        if hit(ctx, player, target, move, damage, attackTag) then
            success = true
        end
    end

    return success
end

local function executeMove(
    ctx: any,
    player: Player,
    move: any,
    damage: number
): boolean
    local tag = tostring(move.Tag or move.Name):gsub("%W", "")

    if move.Type == "Melee" then
        return hit(
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

        local success = hit(
            ctx,
            player,
            target,
            move,
            damage,
            tag
        )

        if success and target then
            ctx.fx("ProjectileImpact", target.root.Position, {
                character = player:GetAttribute("CharacterId"),
                move = move.Name,
                tag = tag,
                actor = target.model
            })
        end

        return success
    end

    if move.Type == "Area" or move.Type == "Burst" then
        return pulse(ctx, player, move, damage, tag)
    end

    if move.Type == "Control" then
        local target = if move.Radius
            then area(ctx, player, tonumber(move.Radius) or 10)[1]
            else front(ctx, player, tonumber(move.Range) or 12, 9, 8)

        local success = hit(ctx, player, target, move, damage, tag)

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

    if move.Type == "Mobility" then
        local root = rootOf(player)
        if root then
            root.AssemblyLinearVelocity =
                root.CFrame.LookVector * 72
                + Vector3.new(0, 6, 0)
        end

        return hit(
            ctx,
            player,
            front(ctx, player, tonumber(move.Range) or 10, 8, 8),
            move,
            damage,
            tag
        )
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

local function defaultVars(id: string): {[string]: any}
    return {
        Momentum = 0,
        Infinity = false,
        InfinityUntil = 0,
        ShrineMode = "Dismantle",
        TenShadowsMode = "Divine Dog",
        ShadowCharge = 0,
        Awakening = false
    }
end

function CharacterKit.Build(id: string)
    local profile = Profiles[id]
    if not profile then
        error("Unknown playable character: " .. id)
    end

    local M = {}

    function M.Init(player: Player, ctx: any)
        local state = ctx.getState(player)
        state.Vars = defaultVars(id)

        player:SetAttribute("CharacterId", id)
        player:SetAttribute("CharacterName", profile.Name)
        player:SetAttribute("CharacterTitle", profile.Subtitle)
        player:SetAttribute("UniqueState", profile.Unique)
        player:SetAttribute("SpecialName", Moves[id].SpecialName)
        player:SetAttribute("AwakeningName", profile.AwakeningName)

        sync(player, state.Vars)
    end

    function M.GetMoves(player: Player?)
        return Movesets.Get(id, player ~= nil and awakened(player))
    end

    function M.GetCooldown(action: string, slot: number?): number
        if action == "Special" then
            return math.clamp(profile.SpecialCooldown, 0.25, 20)
        end

        if action == "Skill" and slot then
            local move = Movesets.GetMove(id, slot, false)
            if move then
                return math.clamp(move.Cooldown, 0.25, 10)
            end
        end

        return profile.SkillCooldown
    end

    function M.SkillSlot(player: Player, ctx: any, slot: number): boolean
        local isAwake = awakened(player)
        local move = Movesets.GetMove(id, slot, isAwake)
        if not move then
            return false
        end

        local state = ctx.getState(player)
        state.Vars.ActiveMove = move

        local damage = tonumber(move.Damage) or 0
        local vars = state.Vars

        if id == "Yuji" then
            damage += math.min(8, tonumber(vars.Momentum) or 0) * 1.5
            if slot == 3 then
                damage += (tonumber(vars.Momentum) or 0) * 2
            end
        elseif id == "Gojo" then
            if slot == 1 then
                vars.Infinity = true
            elseif slot == 2 then
                vars.Infinity = false
            elseif slot == 4 then
                damage += isAwake and 8 or 0
            end
        elseif id == "Sukuna" then
            local modes = {"Dismantle", "Cleave", "Flame", "WorldCut"}
            vars.ShrineMode = modes[math.clamp(slot, 1, #modes)]
            if slot == 4 then
                damage += 8
            end
        elseif id == "Megumi" then
            local modes = {"Divine Dog", "Nue", "Max Elephant", "Totality"}
            vars.TenShadowsMode = modes[math.clamp(slot, 1, #modes)]
            damage += (tonumber(vars.ShadowCharge) or 0) * 0.04
        end

        sync(player, vars)

        announce(ctx, player, id, "Skill" .. tostring(slot), move.Name, {
            slot = slot,
            awakened = isAwake,
            power = damage
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

    function M.Special(player: Player, ctx: any): boolean
        local state = ctx.getState(player)
        local vars = state.Vars
        local isAwake = awakened(player)

        local move: any
        local damage: number

        if id == "Yuji" then
            move = Movesets.GetMove(id, isAwake and 4 or 3, isAwake)
            damage = isAwake and 52 or 42

            -- Janela curta de amplificação para representar o timing de Black Flash.
            damage += math.min(8, tonumber(vars.Momentum) or 0) * 2.5
            vars.Momentum = 0
            sync(player, {Momentum = 0})

        elseif id == "Gojo" then
            move = Movesets.GetMove(id, isAwake and 1 or 1, isAwake)
            damage = isAwake and 38 or 28
            vars.Infinity = true
            vars.InfinityUntil = os.clock() + 0.95
            state.InvulnerableUntil = math.max(
                state.InvulnerableUntil,
                vars.InfinityUntil
            )
            sync(player, {
                Infinity = true,
                InfinityUntil = vars.InfinityUntil
            })

        elseif id == "Sukuna" then
            move = Movesets.GetMove(id, isAwake and 4 or 2, isAwake)
            damage = isAwake and 46 or 30
            vars.ShrineMode = "Cleave"
            sync(player, {ShrineMode = vars.ShrineMode})

        else
            move = Movesets.GetMove(id, isAwake and 4 or 1, isAwake)
            damage = isAwake and 44 or 24
            vars.ShadowCharge = math.min(
                100,
                (tonumber(vars.ShadowCharge) or 0) + 25
            )
            vars.TenShadowsMode = isAwake
                and "Chimera"
                or "Shadow Step"
            sync(player, {
                ShadowCharge = vars.ShadowCharge,
                TenShadowsMode = vars.TenShadowsMode
            })
        end

        state.Vars.ActiveMove = move

        announce(ctx, player, id, "Special", move.Name, {
            awakened = isAwake,
            power = damage
        })

        return executeMove(ctx, player, move, damage)
    end

    function M.OnIncomingDamage(
        player: Player,
        _ctx: any,
        amount: number,
        meta: any
    ): number
        local state = _ctx.getState(player)
        local vars = state.Vars
        local now = os.clock()

        if id == "Gojo"
            and (vars.Infinity == true or vars.InfinityUntil > now)
            and not meta.guardBreak then
            return 0
        end

        return amount
    end

    function M.OnM1Hit(player: Player, ctx: any, combo: number, success: boolean)
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

    return M
end

return CharacterKit
