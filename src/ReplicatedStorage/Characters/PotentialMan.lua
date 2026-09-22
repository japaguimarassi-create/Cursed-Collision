--!strict

local PotentialMan = {}

local function rootOf(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function front(ctx: any, player: Player, range: number, width: number, height: number)
    return ctx.hitbox:NearestTargetInFront(player, range, width, height)
end

local function announce(ctx: any, player: Player, action: string, move: string)
    local root = rootOf(player)
    if root then
        ctx.fx("CharacterMove", root.Position, {
            character = "PotentialMan",
            action = action,
            move = move,
            power = 1,
            direction = root.CFrame.LookVector,
            actor = player.Character
        })
    end
end

function PotentialMan.Init(player: Player, _ctx)
    player:SetAttribute("SpecialName", "Shadow Potential")
    player:SetAttribute("SpecialReady", true)
    player:SetAttribute("UniqueState", "Shadow Potential")
end

function PotentialMan.GetMoves()
    return {
        {Name="Shadow Jab", Type="Melee", Range=8, Damage=14, Stun=0.34, Knockback=24, Cooldown=0.55, Tag="ShadowJab"},
        {Name="Shade Step", Type="Mobility", Range=10, Damage=16, Stun=0.35, Knockback=34, Cooldown=1.2, Tag="ShadeStep"},
        {Name="Shadow Bind", Type="Control", Range=13, Damage=12, Stun=0.85, Knockback=0, Cooldown=2.4, Tag="ShadowBind"},
        {Name="Shadow Burst", Type="Burst", Radius=11, Damage=30, Stun=0.72, Knockback=68, Cooldown=5.0, Tag="ShadowBurst"}
    }
end

function PotentialMan.GetCooldown(action: string, slot: number?): number
    if action == "Skill" and slot then
        local move = PotentialMan.GetMoves()[slot]
        return math.clamp(
            tonumber(move and move.Cooldown) or 1,
            0.25,
            10
        )
    end

    return 4.0
end

function PotentialMan.SkillSlot(player: Player, ctx: any, slot: number): boolean
    local move = PotentialMan.GetMoves()[slot]
    if not move then
        return false
    end

    announce(ctx, player, "Skill" .. tostring(slot), move.Name)

    if move.Type == "Burst" then
        local success = false

        for _, target in ipairs(ctx.hitbox:TargetsInRadius(player, move.Radius)) do
            if ctx.damage(
                player,
                target.humanoid,
                move.Damage,
                {
                    stun=move.Stun,
                    knockback=move.Knockback,
                    reaction="Skill",
                    tag=move.Tag
                }
            ) then
                success = true
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
    end

    local target = front(
        ctx,
        player,
        move.Range,
        8,
        8
    )

    return target ~= nil
        and ctx.damage(
            player,
            target.humanoid,
            move.Damage,
            {
                stun=move.Stun,
                knockback=move.Knockback,
                reaction="Skill",
                tag=move.Tag
            }
        )
end

function PotentialMan.Special(player: Player, ctx): boolean
    local root = rootOf(player)
    if not root then
        return false
    end

    announce(ctx, player, "Special", "Shadow Potential")

    local target = front(ctx, player, 11.5, 7, 7)
    if not target then
        ctx.fx("SpecialWhiff", root.Position, {
            character="PotentialMan",
            actor=player.Character,
            move="Shadow Potential"
        })
        return false
    end

    local success = ctx.damage(
        player,
        target.humanoid,
        26,
        {
            stun=0.65,
            knockback=68,
            lift=14,
            direction=root.CFrame.LookVector,
            guardBreak=true,
            reaction="Special",
            tag="ShadowPotential"
        }
    )

    if success then
        ctx.fx("SpecialImpact", target.root.Position, {
            character="PotentialMan",
            actor=player.Character,
            target=target.model,
            move="Shadow Potential"
        })
    end

    return success
end

return PotentialMan