--!strict

local PotentialMan = {}

function PotentialMan.Init(player: Player, _ctx)
    player:SetAttribute("SpecialName", "Shadow Potential")
    player:SetAttribute("SpecialReady", true)
end

function PotentialMan.Special(player: Player, ctx): boolean
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return false
    end

    local target = ctx.hitbox:NearestTargetInFront(
        player,
        11.5,
        7.0,
        7.0
    )

    if not target then
        ctx.fx("SpecialWhiff", root.Position, {
            character = "PotentialMan",
            actor = player.Character,
            move = "Shadow Potential"
        })
        return false
    end

    local direction = root.CFrame.LookVector

    local success = ctx.damage(
        player,
        target.humanoid,
        26,
        {
            stun = 0.65,
            knockback = 68,
            lift = 14,
            direction = direction,
            guardBreak = true,
            reaction = "Special",
            tag = "ShadowPotential"
        }
    )

    if success then
        ctx.fx("SpecialImpact", target.root.Position, {
            character = "PotentialMan",
            actor = player.Character,
            target = target.model,
            move = "Shadow Potential",
            direction = direction
        })
    end

    return success
end

return PotentialMan