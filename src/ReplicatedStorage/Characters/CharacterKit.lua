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

local function announce(ctx: any, player: Player, id: string, action: string, move: string, power: number)
    local root = rootOf(player)
    if not root then
        return
    end

    ctx.fx("CharacterMove", root.Position, {
        character = id,
        action = action,
        move = move,
        power = power,
        direction = root.CFrame.LookVector,
        actor = player.Character
    })
end

local function hit(
    ctx: any,
    player: Player,
    target: any,
    damage: number,
    tag: string,
    stun: number,
    knockback: number,
    direction: Vector3?,
    extra: any?
): boolean
    if not target then
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
    local look = root and root.CFrame.LookVector or Vector3.zAxis
    local meta = extra or {}

    meta.stun = math.max(0, stun)
    meta.knockback = math.max(0, knockback)
    meta.direction = direction or look
    meta.reaction = meta.reaction or "Skill"
    meta.tag = tag

    return ctx.damage(player, target.humanoid, math.max(0, damage), meta)
end

local function pulse(
    ctx: any,
    player: Player,
    radius: number,
    damage: number,
    tag: string,
    stun: number,
    knockback: number
): boolean
    local success = false

    for _, target in ipairs(area(ctx, player, radius)) do
        if hit(ctx, player, target, damage, tag, stun, knockback) then
            success = true
        end
    end

    return success
end

local function swapNearest(ctx: any, player: Player, radius: number): boolean
    local targets = area(ctx, player, radius)
    local target = targets[1]

    if not target or not target.player then
        return false
    end

    local aRoot = rootOf(player)
    local bRoot = target.root

    if not aRoot or not bRoot then
        return false
    end

    local aCFrame = aRoot.CFrame
    aRoot.CFrame = bRoot.CFrame
    bRoot.CFrame = aCFrame
    aRoot.AssemblyLinearVelocity = Vector3.zero
    bRoot.AssemblyLinearVelocity = Vector3.zero

    return true
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

local function createVars(id: string): {[string]: any}
    return {
        Momentum = 0,
        Infinity = id == "Gojo",
        LimitlessState = "Neutral",
        SlashAdaptation = "Dismantle",
        ShikigamiMode = "Divine Dogs",
        RikaActive = id == "Yuta",
        CopySlot = 1,
        WeaponMode = "Katana",
        SoulIntegrity = 100,
        SwapReady = true,
        Jackpot = false,
        JackpotUntil = 0,
        Blood = 100,
        ElectricalCharge = 0,
        FrameSequence = 0,
        FrameWindowUntil = 0,
        TechniqueStock = 2,
        Heat = 0,
        Tide = 0,
        Roots = 0,
        Evidence = 0,
        Confiscated = false,
        ComedyContext = 0,
        Frost = 0,
        Construction = 0,
        OutputCharge = 0,
        SkyDistortion = 0,
        SimpleDomain = id == "Kusakabe"
    }
end

function CharacterKit.Build(id: string)
    local profile = Profiles[id]

    if not profile then
        error("Unknown character: " .. id)
    end

    local M = {}

    function M.Init(player: Player, ctx: any)
        local state = ctx.getState(player)
        state.Vars = createVars(id)

        player:SetAttribute("CharacterId", id)
        player:SetAttribute("CharacterName", profile.Name)
        player:SetAttribute("CharacterTitle", profile.Subtitle)
        player:SetAttribute("UniqueState", profile.Unique or id)
        player:SetAttribute(
            "SpecialName",
            Moves[id] and Moves[id].SpecialName or "Special"
        )

        sync(player, state.Vars)
    end

    function M.GetMoves()
        return Movesets.Get(id)
    end

    function M.GetCooldown(action: string, slot: number?): number
        if action == "Special" then
            return math.clamp(
                tonumber(profile.SpecialCooldown) or 4,
                0.25,
                20
            )
        end

        if action == "Skill" and slot then
            local move = M.GetMoves()[slot]
            return math.clamp(
                tonumber(move and move.Cooldown) or 1,
                0.25,
                10
            )
        end

        return 1
    end

    function M.SkillSlot(player: Player, ctx: any, slot: number): boolean
        local move = M.GetMoves()[slot]
        if not move then
            return false
        end

        local state = ctx.getState(player)
        local vars = state.Vars

        local damage = tonumber(move.Damage) or 0
        local stun = tonumber(move.Stun) or 0.3
        local knockback = tonumber(move.Knockback) or 0
        local range = tonumber(move.Range) or 9
        local radius = tonumber(move.Radius) or 10

        if id == "Yuji" then
            vars.Momentum = math.min(
                8,
                (vars.Momentum or 0) + (slot == 2 and 2 or 1)
            )
            damage += (vars.Momentum or 0) * 0.7
        elseif id == "Gojo" then
            if slot == 1 then
                vars.LimitlessState = "Neutral"
                vars.Infinity = true
                knockback = 0
            elseif slot == 2 then
                vars.LimitlessState = "Red"
                vars.Infinity = false
                damage += 7
                knockback += 35
            elseif slot == 3 then
                vars.LimitlessState = "Neutral"
                vars.Infinity = true
                knockback = 25
            else
                vars.LimitlessState = "Purple"
                vars.Infinity = false
                damage += 12
            end
        elseif id == "Sukuna" then
            vars.SlashAdaptation = ({
                [1] = "Dismantle",
                [2] = "Cleave",
                [3] = "Fire",
                [4] = "WorldCutting"
            })[slot]

            damage += slot == 4 and 15 or 0
        elseif id == "Megumi" then
            local modes = {
                "Divine Dogs", "Nue", "Toad", "Rabbit Escape",
                "Max Elephant", "Mahoraga"
            }
            vars.ShikigamiMode = modes[((slot - 1) % #modes) + 1]
            damage += vars.ShikigamiMode == "Mahoraga" and 12 or 0
        elseif id == "Yuta" then
            vars.CopySlot = ((slot - 1) % 3) + 1
            vars.RikaActive = slot % 2 == 0 or vars.RikaActive
            damage += vars.RikaActive and 3 or 0
        elseif id == "Maki" or id == "Toji" then
            local modes = id == "Maki"
                and {"Katana", "Spear", "Naginata", "Chain"}
                or {"Katana", "Chain", "Spear", "InvertedSpear"}

            vars.WeaponMode = modes[((slot - 1) % #modes) + 1]
            damage += slot == 4 and 8 or 0
        elseif id == "Mahito" then
            vars.SoulIntegrity = math.max(
                0,
                (vars.SoulIntegrity or 100) - (slot == 2 and 18 or 9)
            )
        elseif id == "Todo" and (slot == 1 or slot == 3) then
            vars.SwapReady = not vars.SwapReady
        elseif id == "Hakari" and slot == 2 then
            local roll = math.random(1, 100)
            vars.Jackpot = roll >= 70
            vars.JackpotUntil = vars.Jackpot and os.clock() + 14 or 0
        elseif id == "Choso" then
            vars.Blood = math.max(
                0,
                (vars.Blood or 100) - (slot == 4 and 32 or 12)
            )
            damage += (vars.Blood or 0) * 0.03
        elseif id == "Kashimo" then
            vars.ElectricalCharge = math.min(
                100,
                (vars.ElectricalCharge or 0) + (slot == 4 and 38 or 18)
            )
            damage += (vars.ElectricalCharge or 0) * 0.05
        elseif id == "Naoya" then
            local t = os.clock()
            vars.FrameSequence =
                (vars.FrameWindowUntil > t and (vars.FrameSequence or 0) or 0) + 1
            vars.FrameSequence = math.min(24, vars.FrameSequence)
            vars.FrameWindowUntil = t + 0.75
            damage += vars.FrameSequence * 0.4
        elseif id == "Kenjaku" then
            if slot == 2 then
                vars.TechniqueStock = math.min(
                    5,
                    (vars.TechniqueStock or 0) + 1
                )
            else
                vars.TechniqueStock = math.max(
                    0,
                    (vars.TechniqueStock or 0) - 1
                )
            end
            damage += (vars.TechniqueStock or 0) * 1.5
        elseif id == "Jogo" then
            vars.Heat = math.min(100, (vars.Heat or 0) + 20)
            damage += (vars.Heat or 0) * 0.05
        elseif id == "Dagon" then
            vars.Tide = math.min(100, (vars.Tide or 0) + 18)
            damage += (vars.Tide or 0) * 0.04
        elseif id == "Hanami" then
            vars.Roots = math.min(100, (vars.Roots or 0) + 18)
            damage += (vars.Roots or 0) * 0.04
        elseif id == "Higuruma" then
            vars.Evidence = math.min(100, (vars.Evidence or 0) + 22)
            if vars.Evidence >= 70 then
                vars.Confiscated = true
            end
            damage += (vars.Evidence or 0) * 0.035
        elseif id == "Takaba" then
            vars.ComedyContext = math.min(
                100,
                (vars.ComedyContext or 0) + 20
            )
            damage += vars.ComedyContext >= 70 and 9 or 0
        elseif id == "Uraume" then
            vars.Frost = math.min(100, (vars.Frost or 0) + 20)
            damage += (vars.Frost or 0) * 0.04
        elseif id == "Yorozu" then
            vars.Construction = math.min(
                100,
                (vars.Construction or 0) + 22
            )
            damage += (vars.Construction or 0) * 0.035
        elseif id == "Ryu" then
            vars.OutputCharge = math.min(
                100,
                (vars.OutputCharge or 0) + 24
            )
            damage += (vars.OutputCharge or 0) * 0.055
        elseif id == "Uro" then
            vars.SkyDistortion = math.min(
                100,
                (vars.SkyDistortion or 0) + 22
            )
            damage += (vars.SkyDistortion or 0) * 0.04
        elseif id == "Kusakabe" then
            vars.SimpleDomain = slot == 2 or vars.SimpleDomain
            damage *= vars.SimpleDomain and 1.12 or 1
        end

        sync(player, vars)

        announce(
            ctx,
            player,
            id,
            "Skill" .. tostring(slot),
            move.Name,
            1.0
        )

        if move.Type == "Melee" then
            return hit(
                ctx,
                player,
                front(ctx, player, range, 8, 8),
                damage,
                move.Tag,
                stun,
                knockback
            )
        end

        if move.Type == "Projectile" then
            local target = front(ctx, player, range, 8, 8)
            local success = hit(
                ctx,
                player,
                target,
                damage,
                move.Tag,
                stun,
                knockback
            )

            if success and target then
                ctx.fx("ProjectileImpact", target.root.Position, {
                    character = id,
                    move = move.Name,
                    tag = move.Tag
                })
            end

            return success
        end

        if move.Type == "Area" or move.Type == "Burst" then
            return pulse(
                ctx,
                player,
                radius,
                damage,
                move.Tag,
                stun,
                knockback
            )
        end

        if move.Type == "Control" then
            local target

            if move.Radius then
                target = area(ctx, player, radius)[1]
            else
                target = front(ctx, player, range, 9, 8)
            end

            local success = hit(
                ctx,
                player,
                target,
                damage,
                move.Tag,
                stun,
                knockback
            )

            if success and move.Pull and target then
                local root = rootOf(player)
                if root then
                    local delta = root.Position - target.root.Position
                    if delta.Magnitude > 0.01 then
                        target.root.AssemblyLinearVelocity =
                            delta.Unit * tonumber(move.Pull)
                            + Vector3.new(0, 8, 0)
                    end
                end
            end

            return success
        end

        if move.Type == "Mobility" then
            local root = rootOf(player)

            if root then
                root.AssemblyLinearVelocity =
                    root.CFrame.LookVector * 66
                    + Vector3.new(0, 7, 0)
            end

            return hit(
                ctx,
                player,
                front(ctx, player, range, 8, 8),
                damage,
                move.Tag,
                stun,
                knockback
            )
        end

        if move.Type == "Utility" then
            if id == "Todo" then
                local swapped = swapNearest(ctx, player, range)
                if swapped then
                    vars.SwapReady = false
                    sync(player, {SwapReady = false})
                    return true
                end
            end

            return pulse(
                ctx,
                player,
                math.min(radius, 10),
                damage,
                move.Tag,
                stun,
                knockback
            )
        end

        return false
    end

    function M.Special(player: Player, ctx: any): boolean
        local vars = ctx.getState(player).Vars
        local base = M.GetMoves()[1]

        local moveName =
            (Moves[id] and Moves[id].SpecialName)
            or (base and base.Name)
            or "Special"

        local damage = base and tonumber(base.Damage) or 18
        local range = base and tonumber(base.Range) or 10
        local radius = base and tonumber(base.Radius) or 10
        local stun = base and tonumber(base.Stun) or 0.5
        local knockback = base and tonumber(base.Knockback) or 40

        if id == "Gojo" then
            moveName = vars.LimitlessState == "Red"
                and "Reversal Red"
                or vars.LimitlessState == "Purple"
                and "Hollow Purple"
                or "Lapse Blue"
            damage = vars.LimitlessState == "Purple" and 44 or 28
            range = vars.LimitlessState == "Purple" and 30 or 18
            knockback = vars.LimitlessState == "Purple" and 120 or 78
        elseif id == "Sukuna" then
            moveName = vars.SlashAdaptation == "Fire"
                and "Fire Arrow"
                or vars.SlashAdaptation == "WorldCutting"
                and "World Cutting Slash"
                or "Cursed Slash"
            damage = vars.SlashAdaptation == "WorldCutting" and 52 or 27
            range = 28
        elseif id == "Megumi" then
            moveName = vars.ShikigamiMode or "Shikigami Assault"
            damage = vars.ShikigamiMode == "Mahoraga" and 40 or 24
            radius = 14
        elseif id == "Yuta" then
            moveName = "Rika Sword"
            damage = vars.RikaActive and 30 or 22
        elseif id == "Maki" or id == "Toji" then
            moveName = (vars.WeaponMode or "Katana") .. " Strike"
            damage = id == "Toji" and 32 or 29
        elseif id == "Mahito" then
            moveName = "Idle Transfiguration"
            damage = 26
            vars.SoulIntegrity = math.min(
                100,
                (vars.SoulIntegrity or 100) + 8
            )
        elseif id == "Todo" then
            moveName = "Boogie Woogie"
            damage = 24

            if vars.SwapReady and swapNearest(ctx, player, 20) then
                vars.SwapReady = false
                sync(player, {SwapReady = false})
                return true
            end
        elseif id == "Hakari" then
            moveName = "Private Pure Love"
            damage = vars.Jackpot and 31 or 22
        elseif id == "Choso" then
            moveName = "Piercing Blood"
            damage = 32 + (vars.Blood or 0) * 0.06
            range = 24
        elseif id == "Kashimo" then
            moveName = "Electrified Strike"
            damage = 26 + (vars.ElectricalCharge or 0) * 0.08
        elseif id == "Naoya" then
            moveName = "Projection Strike"
            damage = 25 + (vars.FrameSequence or 0) * 0.5
            range = 16
        elseif id == "Kenjaku" then
            moveName = "Cursed Spirit Burst"
            damage = 27 + (vars.TechniqueStock or 0) * 2
            range = 24
        elseif id == "Jogo" then
            moveName = "Volcanic Burst"
            damage = 28 + (vars.Heat or 0) * 0.08
            range = 25
        elseif id == "Dagon" then
            moveName = "Death Swarm"
            damage = 25 + (vars.Tide or 0) * 0.06
            radius = 12
        elseif id == "Hanami" then
            moveName = "Disaster Plants"
            damage = 27 + (vars.Roots or 0) * 0.05
            range = 20
        elseif id == "Higuruma" then
            moveName = "Judgment Strike"
            damage = 27 + (vars.Evidence or 0) * 0.05
        elseif id == "Takaba" then
            moveName = "Comedian"
            damage = 20 + ((vars.ComedyContext or 0) >= 70 and 14 or 0)
        elseif id == "Uraume" then
            moveName = "Ice Formation"
            damage = 25 + (vars.Frost or 0) * 0.06
        elseif id == "Yorozu" then
            moveName = "Liquid Metal"
            damage = 26 + (vars.Construction or 0) * 0.05
        elseif id == "Ryu" then
            moveName = "Granite Shot"
            damage = 33 + (vars.OutputCharge or 0) * 0.08
            range = 30
        elseif id == "Uro" then
            moveName = "Sky Strike"
            damage = 26 + (vars.SkyDistortion or 0) * 0.06
            range = 18
        elseif id == "Kusakabe" then
            moveName = "New Shadow Slash"
            damage = 28 * (vars.SimpleDomain and 1.12 or 1)
        end

        announce(ctx, player, id, "Special", moveName, 1.25)

        if id == "Dagon"
            or id == "Jogo"
            or id == "Hanami"
            or id == "Uraume" then
            return pulse(
                ctx,
                player,
                math.max(radius, 11),
                damage,
                moveName:gsub("%W", ""),
                stun + 0.08,
                knockback + 6
            )
        end

        return hit(
            ctx,
            player,
            front(ctx, player, range, 9, 8),
            damage,
            moveName:gsub("%W", ""),
            stun + 0.08,
            knockback + 6
        )
    end

    function M.OnIncomingDamage(player: Player, ctx: any, amount: number): number
        local vars = ctx.getState(player).Vars

        if id == "Gojo" and vars.Infinity then
            return 0
        end

        if id == "Mahito" then
            vars.SoulIntegrity = math.max(
                0,
                (vars.SoulIntegrity or 100) - amount * 0.25
            )
            return amount * 0.92
        end

        if id == "Maki" or id == "Toji" then
            return amount * 0.88
        end

        if id == "Hakari"
            and vars.Jackpot
            and vars.JackpotUntil > os.clock() then
            return math.max(0, amount - 4)
        end

        if id == "Kusakabe" and vars.SimpleDomain then
            return amount * 0.72
        end

        return amount
    end

    return M
end

return CharacterKit