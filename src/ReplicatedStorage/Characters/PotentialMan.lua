--!strict

local PotentialMan = {}

type Move = {
    Name: string,
    Type: string,
    Range: number?,
    Radius: number?,
    Damage: number,
    Stun: number,
    Knockback: number,
    Cooldown: number,
    Tag: string
}

local MOVES: {Move} = {
    {
        Name="Shadow Jab", Type="Melee", Range=8, Damage=14,
        Stun=0.34, Knockback=24, Cooldown=0.55, Tag="ShadowJab"
    },
    {
        Name="Shade Step", Type="Mobility", Range=10, Damage=16,
        Stun=0.35, Knockback=34, Cooldown=1.2, Tag="ShadeStep"
    },
    {
        Name="Shadow Bind", Type="Control", Range=13, Damage=12,
        Stun=0.85, Knockback=0, Cooldown=2.4, Tag="ShadowBind"
    },
    {
        Name="Shadow Burst", Type="Burst", Radius=11, Damage=30,
        Stun=0.72, Knockback=68, Cooldown=5.0, Tag="ShadowBurst"
    }
}

local function rootOf(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function front(ctx: any, player: Player, move: Move)
    return ctx.hitbox:NearestTargetInFront(
        player,
        move.Range or 9,
        8,
        8
    )
end

local function announce(ctx: any, player: Player, action: string, move: Move)
    local root = rootOf(player)

    if root then
        ctx.fx("CharacterMove", root.Position, {
            character="PotentialMan",
            action=action,
            move=move.Name,
            power=1,
            direction=root.CFrame.LookVector,
            actor=player.Character
        })
    end
end

function PotentialMan.Init(player: Player, _ctx: any)
    player:SetAttribute("SpecialName", "Shadow Potential")
    player:SetAttribute("SpecialReady", true)
    player:SetAttribute("UniqueState", "Shadow Potential")
end

function PotentialMan.GetMoves(): {Move}
    return MOVES
end

function PotentialMan.GetCooldown(action: string, slot: number?): number
    if action == "Skill" and slot then
        return math.clamp(
            MOVES[slot].Cooldown,
            0.25,
            10
        )
    end

    return 4.0
end

function PotentialMan.SkillSlot(
    player: Player,
    ctx: any,
    slot: number
): boolean
    local move = MOVES[slot]

    if not move then
        return false
    end

    announce(ctx, player, "Skill" .. tostring(slot), move)

    if move.Type == "Mobility" then
        local root = rootOf(player)

        if root then
            root.AssemblyLinearVelocity =
                root.CFrame.LookVector * 66
                + Vector3.new(0, 7, 0)
        end
    elseif move.Type == "Burst" then
        local success = false

        for _, target in ipairs(
            ctx.hitbox:TargetsInRadius(player, move.Radius or 10)
        ) do
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

    local target = front(ctx, player, move)

    if not target then
        return false
    end

    return ctx.damage(
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

function PotentialMan.Special(player: Player, ctx: any): boolean
    local root = rootOf(player)

    if not root then
        return false
    end

    local specialMove: Move = {
        Name="Shadow Potential",
        Type="Melee",
        Range=11.5,
        Damage=26,
        Stun=0.65,
        Knockback=68,
        Cooldown=4.0,
        Tag="ShadowPotential"
    }

    announce(ctx, player, "Special", specialMove)

    local target = ctx.hitbox:NearestTargetInFront(
        player,
        specialMove.Range or 11,
        7,
        7
    )

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
        specialMove.Damage,
        {
            stun=specialMove.Stun,
            knockback=specialMove.Knockback,
            lift=14,
            direction=root.CFrame.LookVector,
            guardBreak=true,
            reaction="Special",
            tag=specialMove.Tag
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