--!strict

local Players = game:GetService("Players")
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

local function humanoidOf(player: Player): Humanoid?
    local character = player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function front(ctx: any, player: Player, range: number, width: number, height: number)
    return ctx.hitbox:NearestTargetInFront(player, range, width, height)
end

local function area(ctx: any, player: Player, radius: number)
    return ctx.hitbox:TargetsInRadius(player, radius)
end

local function empowered(player: Player): boolean
    return player:GetAttribute("AwakeningActive") == true
        or player:GetAttribute("UltimateActive") == true
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

local function updateSkillNames(player: Player, moves: {any})
    for slot = 1, 4 do
        local move = moves[slot]
        player:SetAttribute(
            "Skill" .. tostring(slot) .. "Name",
            move and move.Name or "Locked"
        )
    end
end

local function emit(ctx: any, player: Player, action: string, moveName: string, extra: {[string]: any}?)
    local root = rootOf(player)
    if not root then
        return
    end

    local payload: {[string]: any} = extra or {}
    payload.character = player:GetAttribute("CharacterId")
    payload.move = moveName
    payload.action = action
    payload.actor = player.Character
    payload.direction = root.CFrame.LookVector

    ctx.fx("CharacterMove", root.Position, payload)
end

local function targetPlayer(target: any): Player?
    if not target or not target.model then
        return nil
    end

    return Players:GetPlayerFromCharacter(target.model)
end

local function hit(
    ctx: any,
    player: Player,
    target: any,
    move: any,
    damage: number,
    tag: string,
    uniqueKey: string?
): boolean
    if not target or not target.humanoid or target.humanoid.Health <= 0 then
        return false
    end

    local state = ctx.getState(player)
    local root = rootOf(player)
    if not state then
        return false
    end

    local attackId = state.Vars.ActiveAttackId or tag
    local registryKey = uniqueKey or attackId

    if ctx.hitRegistry and ctx.hitRegistry:Has(player, registryKey, target.model) then
        return false
    end

    if ctx.hitRegistry then
        ctx.hitRegistry:Add(player, registryKey, target.model)
    end

    local direction = root and root.CFrame.LookVector or Vector3.zAxis

    return ctx.damage(
        player,
        target.humanoid,
        math.max(0, damage),
        {
            stun = math.max(0, tonumber(move.Stun) or 0.2),
            knockback = math.max(0, tonumber(move.Knockback) or 0),
            direction = direction,
            guardBreak = move.GuardBreak == true,
            ragdoll = move.Ragdoll == true,
            ragdollDuration = move.Ragdoll == true and 0.58 or nil,
            launch = move.Launch == true,
            reaction = move.Ragdoll == true and "Finisher"
                or move.GuardBreak == true and "Heavy"
                or "Skill",
            bypassInfinity = move.BypassInfinity == true,
            noKillCredit = move.NoKillCredit == true,
            noAwakeningMeter = move.NoAwakeningMeter == true,
            tag = tag
        }
    )
end

local function hitFront(ctx: any, player: Player, move: any, damage: number, suffix: string?): (boolean, any?)
    local range = tonumber(move.Range) or 10
    local width = math.clamp(range * 0.70, 7, 13)
    local height = math.clamp(range * 0.70, 7, 13)
    local target = front(ctx, player, range, width, height)

    local key = nil
    if suffix then
        key = (ctx.getState(player).Vars.ActiveAttackId or move.Tag) .. ":" .. suffix
    end

    return hit(ctx, player, target, move, damage, move.Tag, key), target
end

local function hitArea(ctx: any, player: Player, move: any, damage: number, suffix: string?): boolean
    local success = false
    local state = ctx.getState(player)
    local baseKey = state and (state.Vars.ActiveAttackId or move.Tag) or move.Tag

    for index, target in ipairs(area(ctx, player, tonumber(move.Radius) or 10)) do
        local uniqueKey = baseKey .. ":" .. tostring(suffix or "Area") .. ":" .. tostring(index)
        if hit(ctx, player, target, move, damage, move.Tag, uniqueKey) then
            success = true
        end
    end

    return success
end

local function repeatedFront(ctx: any, player: Player, move: any, damage: number): boolean
    local count = math.max(1, math.floor(tonumber(move.Hits) or 1))
    local interval = math.max(0.025, tonumber(move.HitInterval) or 0.08)
    local success = false

    for index = 1, count do
        local delayTime = interval * (index - 1)

        task.delay(delayTime, function()
            if not player.Parent then
                return
            end

            local value = hitFront(
                ctx,
                player,
                move,
                damage,
                "Hit" .. tostring(index)
            )

            if value then
                success = true
            end
        end)
    end

    local firstTarget = front(ctx, player, tonumber(move.Range) or 10, 9, 9)
    if firstTarget then
        local value = hit(
            ctx,
            player,
            firstTarget,
            move,
            damage,
            move.Tag,
            (ctx.getState(player).Vars.ActiveAttackId or move.Tag) .. ":Immediate"
        )
        success = value or success
    end

    return success
end

local function repeatedArea(ctx: any, player: Player, move: any, damage: number): boolean
    local count = math.max(1, math.floor(tonumber(move.Hits) or 1))
    local interval = math.max(0.025, tonumber(move.HitInterval) or 0.10)
    local success = false

    for index = 1, count do
        local delayTime = interval * (index - 1)

        task.delay(delayTime, function()
            if player.Parent then
                local value = hitArea(
                    ctx,
                    player,
                    move,
                    damage,
                    "Hit" .. tostring(index)
                )
                success = value or success
            end
        end)
    end

    return success
end

local function pull(ctx: any, player: Player, move: any)
    local strength = tonumber(move.Pull) or 0
    if strength <= 0 then
        return
    end

    local target = front(ctx, player, move.Range or 16, 10, 10)
    local root = rootOf(player)

    if target and target.root and root then
        local delta = root.Position - target.root.Position
        if delta.Magnitude > 0.01 then
            target.root.AssemblyLinearVelocity = delta.Unit * strength + Vector3.new(0, 8, 0)
        end
    end
end

local function divergingFist(ctx: any, player: Player, move: any, damage: number): boolean
    local success, target = hitFront(ctx, player, move, damage, "Primary")
    if success and target then
        task.delay(
            math.max(0.05, tonumber(move.SecondaryDelay) or 0.17),
            function()
                if not player.Parent or target.humanoid.Health <= 0 then
                    return
                end

                hit(
                    ctx,
                    player,
                    target,
                    move,
                    tonumber(move.SecondaryDamage) or damage * 0.75,
                    move.Tag .. "_SecondImpact",
                    (ctx.getState(player).Vars.ActiveAttackId or move.Tag) .. ":SecondImpact"
                )
            end
        )

        emit(ctx, player, "DivergentFist", move.Name, {
            delayedImpact = true
        })
    end

    return success
end

local function shikigamiPulse(ctx: any, player: Player, label: string, radius: number, damage: number, knockback: number?)
    local root = rootOf(player)
    if not root then
        return false
    end

    emit(ctx, player, "Shikigami", label, {
        shikigami = label,
        radius = radius,
        damage = damage
    })

    local move = {
        Name = label,
        Type = "Area",
        Tag = "Summon_" .. label:gsub("%W", ""),
        Radius = radius,
        Damage = damage,
        Stun = 0.28,
        Knockback = knockback or 20,
        Ragdoll = false
    }

    return hitArea(ctx, player, move, damage, "Summon")
end

local function roundDeer(ctx: any, player: Player, move: any): boolean
    local root = rootOf(player)
    local humanoid = humanoidOf(player)
    if not root or not humanoid then
        return false
    end

    local oldHealth = humanoid.Health
    humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 24)

    emit(ctx, player, "ShikigamiHeal", move.Name, {
        shikigami = "Round Deer",
        healed = humanoid.Health - oldHealth
    })

    return shikigamiPulse(ctx, player, "Round Deer", 12, 5, 8)
end

local function mahoragaAttack(ctx: any, player: Player): boolean
    local state = ctx.getState(player)
    if not state then
        return false
    end

    local mode = tostring(state.Vars.MahoragaMode or "Attack")
    local move = {
        Name = "Mahoraga: " .. mode,
        Type = "Melee",
        Tag = "Megumi_Mahoraga_" .. mode,
        Range = 13,
        Damage = mode == "Attack" and 42
            or mode == "Defense" and 26
            or 35,
        Stun = mode == "Defense" and 0.60 or 0.48,
        Knockback = mode == "Attack" and 76 or 50,
        GuardBreak = mode == "Special",
        Ragdoll = mode == "Attack"
    }

    if mode == "Defense" then
        state.Vars.MahoragaGuardUntil = os.clock() + 0.55
        sync(player, {
            MahoragaGuardUntil = state.Vars.MahoragaGuardUntil
        })
    elseif mode == "Special" then
        state.Vars.MahoragaAdaptation = math.min(
            100,
            (tonumber(state.Vars.MahoragaAdaptation) or 0) + 25
        )

        sync(player, {
            MahoragaAdaptation = state.Vars.MahoragaAdaptation
        })
    end

    emit(ctx, player, "Mahoraga", move.Name, {
        mode = mode,
        adaptation = state.Vars.MahoragaAdaptation or 0
    })

    return hitFront(ctx, player, move, move.Damage, "Mahoraga")
end

local function enchain(ctx: any, player: Player): boolean
    local target = front(ctx, player, 17, 10, 10)
    local targetOwner = targetPlayer(target)

    if not targetOwner or targetOwner == player then
        return false
    end

    if targetOwner:GetAttribute("CharacterId") ~= "Megumi" then
        return false
    end

    local humanoid = target.humanoid
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    local state = ctx.getState(player)
    if not state then
        return false
    end

    state.Vars.EnchainActive = true
    state.Vars.CopiedMegumi = true
    state.Vars.CopiedTechnique = "Megumi"
    state.Vars.CopiedTechniqueMode = "Megumi"
    state.Vars.EnchainTargetUserId = targetOwner.UserId

    sync(player, {
        EnchainActive = true,
        CopiedMegumi = true,
        CopiedTechnique = "Megumi",
        CopiedTechniqueMode = "Megumi",
        EnchainTargetUserId = targetOwner.UserId,
        SpecialName = "Switch Technique"
    })

    updateSkillNames(player, Movesets.Get("Megumi", true))

    emit(ctx, player, "Enchain", "Enchain", {
        target = target.model,
        targetPlayer = targetOwner,
        copiedCharacter = "Megumi",
        economyCredit = false,
        resetTarget = true
    })

    ctx.damage(
        player,
        humanoid,
        math.max(1000, humanoid.Health + 100),
        {
            stun = 0,
            knockback = 0,
            guardBreak = true,
            final = true,
            reaction = "Finisher",
            noKillCredit = true,
            noAwakeningMeter = true,
            tag = "Enchain_Reset"
        }
    )

    return true
end

function CharacterKit.Build(id: string)
    local profile = Profiles[id]
    if not profile then
        error("Unknown playable character: " .. id)
    end

    local module = {}

    function module.Init(player: Player, ctx: any)
        local state = ctx.getState(player)

        state.Vars = {
            Momentum = 0,
            Infinity = false,
            InfinityUntil = 0,
            ShadowCharge = 0,
            MahoragaActive = false,
            MahoragaMode = "Attack",
            MahoragaAdaptation = 0,
            MahoragaGuardUntil = 0,
            EnchainActive = false,
            CopiedMegumi = false,
            CopiedTechnique = "None",
            CopiedTechniqueMode = "Megumi",
            EnchainTargetUserId = 0,
            BlackFlashCount = 0
        }

        player:SetAttribute("CharacterId", id)
        player:SetAttribute("CharacterName", profile.Name)
        player:SetAttribute("CharacterTitle", profile.Subtitle)
        player:SetAttribute("UniqueState", profile.Unique)
        player:SetAttribute("SpecialName", Moves[id].SpecialName)
        player:SetAttribute("AwakeningName", profile.AwakeningName)
        player:SetAttribute("SukunaVariant", "Standard")

        updateSkillNames(player, module.GetMoves(player))
        sync(player, state.Vars)
    end

    function module.GetMoves(player: Player?)
        local activeId = id
        local awake = player ~= nil and empowered(player)

        if id == "Sukuna"
            and player
            and player:GetAttribute("CopiedMegumi") == true
            and player:GetAttribute("CopiedTechniqueMode") == "Megumi" then
            activeId = "Megumi"
            awake = true
        end

        return Movesets.Get(activeId, awake)
    end

    function module.GetMove(player: Player, slot: number)
        local activeId = id
        local awake = empowered(player)

        if id == "Sukuna"
            and player:GetAttribute("CopiedMegumi") == true
            and player:GetAttribute("CopiedTechniqueMode") == "Megumi" then
            activeId = "Megumi"
            awake = true
        end

        return Movesets.GetMove(activeId, slot, awake)
    end

    function module.GetCooldown(action: string, slot: number?): number
        if action == "Special" then
            return math.clamp(profile.SpecialCooldown, 0.25, 20)
        end

        if action == "Skill" and slot then
            local move = Movesets.GetMove(id, slot, true)
            return math.clamp(
                tonumber(move and move.Cooldown) or profile.SkillCooldown,
                0.25,
                20
            )
        end

        return profile.SkillCooldown
    end

    function module.SkillSlot(player: Player, ctx: any, slot: number): boolean
        local move = module.GetMove(player, slot)
        if not move then
            return false
        end

        local state = ctx.getState(player)
        if not state then
            return false
        end

        state.Vars.ActiveMove = move
        local damage = tonumber(move.Damage) or 0
        local success = false

        if id == "Megumi" and empowered(player) and slot == 4 then
            if not state.Vars.MahoragaActive then
                state.Vars.MahoragaActive = true
                state.Vars.MahoragaMode = "Attack"
                state.Vars.MahoragaAdaptation = 0

                sync(player, {
                    MahoragaActive = true,
                    MahoragaMode = "Attack",
                    MahoragaAdaptation = 0,
                    Skill4Name = "Mahoraga: Attack"
                })

                emit(ctx, player, "MahoragaSummon", "Eight-Handled Divine General", {
                    mode = "Attack",
                    adaptation = 0
                })

                return true
            end

            return mahoragaAttack(ctx, player)
        end

        if move.Domain then
            return startDomain(ctx, player, move)
        end

        if id == "Megumi" and empowered(player) and slot == 3 then
            return roundDeer(ctx, player, move)
        end

        if id == "Yuji" and not empowered(player) and slot == 3 then
            success = divergingFist(ctx, player, move, damage)
        elseif move.Hits and move.Hits > 1 then
            if move.Type == "Area" or move.Type == "Burst" then
                success = repeatedArea(ctx, player, move, damage)
            else
                success = repeatedFront(ctx, player, move, damage)
            end
        elseif move.Type == "Melee"
            or move.Type == "Projectile"
            or move.Type == "Control" then
            local value, _ = hitFront(ctx, player, move, damage)
            success = value
            pull(ctx, player, move)
        elseif move.Type == "Area" or move.Type == "Burst" then
            success = hitArea(ctx, player, move, damage)
        elseif move.Type == "Utility" then
            success = true
        end

        if success and id == "Yuji" then
            state.Vars.Momentum = math.min(
                8,
                (tonumber(state.Vars.Momentum) or 0) + (slot == 3 and 2 or 1)
            )

            sync(player, {
                Momentum = state.Vars.Momentum
            })
        elseif success and id == "Megumi" then
            state.Vars.ShadowCharge = math.min(
                100,
                (tonumber(state.Vars.ShadowCharge) or 0) + 15
            )

            sync(player, {
                ShadowCharge = state.Vars.ShadowCharge
            })
        elseif success and id == "Sukuna" then
            state.Vars.ShrineMode = move.Name

            sync(player, {
                ShrineMode = state.Vars.ShrineMode
            })
        end

        emit(ctx, player, "Skill", move.Name, {
            slot = slot,
            awakened = empowered(player),
            copiedTechnique = player:GetAttribute("CopiedTechniqueMode"),
            mahoragaMode = state.Vars.MahoragaMode
        })

        return success
    end

    function module.Special(player: Player, ctx: any): boolean
        local state = ctx.getState(player)
        if not state then
            return false
        end

        local awake = empowered(player)

        if id == "Sukuna" then
            if awake and state.Vars.CopiedMegumi then
                local mode = state.Vars.CopiedTechniqueMode == "Megumi" and "Sukuna" or "Megumi"

                state.Vars.CopiedTechniqueMode = mode

                local moves = module.GetMoves(player)
                updateSkillNames(player, moves)

                sync(player, {
                    CopiedTechniqueMode = mode,
                    SpecialName = "Switch Technique"
                })

                emit(ctx, player, "TechniqueSwitch", "Switch Technique", {
                    mode = mode
                })

                return true
            end

            if awake then
                if enchain(ctx, player) then
                    return true
                end

                local move = Movesets.GetMove("Sukuna", 2, true)
                if not move then
                    return false
                end

                return hitArea(ctx, player, move, move.Damage)
            end

            local move = Movesets.GetMove("Sukuna", 2, false)
            if not move then
                return false
            end

            return hitArea(ctx, player, move, move.Damage)
        end

        if id == "Gojo" then
            state.Vars.Infinity = not state.Vars.Infinity
            state.Vars.InfinityUntil = state.Vars.Infinity and (os.clock() + 9999) or 0

            sync(player, {
                Infinity = state.Vars.Infinity,
                InfinityUntil = state.Vars.InfinityUntil
            })

            emit(ctx, player, "Infinity", state.Vars.Infinity and "Infinity: ON" or "Infinity: OFF", {
                enabled = state.Vars.Infinity
            })

            return true
        end

        if id == "Megumi" then
            if awake and state.Vars.MahoragaActive then
                local order = {
                    Attack = "Defense",
                    Defense = "Special",
                    Special = "Attack"
                }

                state.Vars.MahoragaMode = order[state.Vars.MahoragaMode] or "Attack"

                sync(player, {
                    MahoragaMode = state.Vars.MahoragaMode,
                    Skill4Name = "Mahoraga: " .. state.Vars.MahoragaMode
                })

                emit(ctx, player, "MahoragaMode", "Adaptation Wheel", {
                    mode = state.Vars.MahoragaMode,
                    adaptation = state.Vars.MahoragaAdaptation
                })

                return true
            end

            if awake and ctx.domainStart then
                return ctx.domainStart(
                    player,
                    "ChimeraShadowGarden",
                    19,
                    7,
                    "Megumi"
                )
            end

            local root = rootOf(player)
            if root then
                root.AssemblyLinearVelocity = root.CFrame.LookVector * 58
            end

            emit(ctx, player, "ShadowStep", "Ten Shadows", {
                shadow = true
            })

            return true
        end

        if id == "Yuji" then
            if awake then
                state.Vars.Momentum = 8

                sync(player, {
                    Momentum = 8
                })

                local now = os.clock()
                state.InvulnerableUntil = math.max(
                    state.InvulnerableUntil,
                    now + 1.25
                )

                emit(ctx, player, "SimpleDomain", "Simple Domain", {
                    duration = 1.25
                })

                return true
            end

            local move = Movesets.GetMove("Yuji", 3, false)
            local target = front(ctx, player, 11, 10, 10)

            if not move or not target then
                return false
            end

            local bonus = math.min(
                8,
                tonumber(state.Vars.Momentum) or 0
            ) * 2

            local success = hit(
                ctx,
                player,
                target,
                move,
                42 + bonus,
                "Yuji_BlackFlash",
                (state.Vars.ActiveAttackId or "Yuji_BlackFlash") .. ":Special"
            )

            if success then
                state.Vars.Momentum = 0
                state.Vars.BlackFlashCount = math.min(
                    4,
                    (tonumber(state.Vars.BlackFlashCount) or 0) + 1
                )

                sync(player, {
                    Momentum = 0,
                    BlackFlashCount = state.Vars.BlackFlashCount
                })

                emit(ctx, player, "BlackFlash", "Black Flash", {
                    critical = true,
                    chain = state.Vars.BlackFlashCount
                })
            end

            return success
        end

        return false
    end

    function module.OnIncomingDamage(player: Player, ctx: any, amount: number, meta: any): number
        if id == "Gojo" then
            local state = ctx.getState(player)
            local vars = state and state.Vars

            if vars
                and vars.Infinity == true
                and meta.bypassInfinity ~= true
                and meta.guardBreak ~= true then
                return 0
            end
        end

        if id == "Megumi" then
            local state = ctx.getState(player)
            local vars = state and state.Vars

            if vars
                and vars.MahoragaActive
                and (tonumber(vars.MahoragaGuardUntil) or 0) > os.clock()
                and meta.guardBreak ~= true then
                return math.min(amount, 4)
            end
        end

        return amount
    end

    function module.OnM1Hit(player: Player, ctx: any, combo: number, success: boolean)
        if not success then
            return
        end

        local state = ctx.getState(player)
        if not state then
            return
        end

        if id == "Yuji" then
            state.Vars.Momentum = math.min(
                8,
                (tonumber(state.Vars.Momentum) or 0) + 1
            )
            sync(player, {
                Momentum = state.Vars.Momentum
            })
        elseif id == "Megumi" then
            state.Vars.ShadowCharge = math.min(
                100,
                (tonumber(state.Vars.ShadowCharge) or 0) + 8
            )
            sync(player, {
                ShadowCharge = state.Vars.ShadowCharge
            })
        elseif id == "Sukuna" then
            state.Vars.ShrineMode = combo == 4 and "Cleave" or "Dismantle"
            sync(player, {
                ShrineMode = state.Vars.ShrineMode
            })
        end
    end

    return module
end

return CharacterKit
