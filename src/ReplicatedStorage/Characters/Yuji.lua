local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Yuji = {}

function Yuji.Init(player, ctx)
    ctx.setAttribute(player, "CharacterTitle", "Black Flash Momentum")
    ctx.setAttribute(player, "Momentum", 0)
end

function Yuji.Special(player, ctx)
    if not ctx.spendCE(player, Config.CE.Costs.Special) then
        return false
    end

    local target = ctx.hitbox:NearestTargetInFront(player, 8, 6, 5)
    if not target then
        return false
    end

    ctx.damage(player, target.humanoid, 11, {
        stun = 0.42,
        knockback = 22,
        tag = "DivergentFist"
    })

    task.delay(0.16, function()
        if target.humanoid and target.humanoid.Health > 0 then
            ctx.damage(player, target.humanoid, 7, {
                stun = 0.25,
                tag = "DelayedImpact"
            })
        end
    end)

    ctx.fx("YujiDivergent", target.root.Position)
    return true
end

function Yuji.Skill(player, ctx)
    local state = ctx.getState(player)
    if state.BlackFlashWindow and os.clock() <= state.BlackFlashWindow then
        state.BlackFlashWindow = nil
        state.Momentum = math.min(8, (state.Momentum or 0) + 1)
        ctx.setAttribute(player, "Momentum", state.Momentum)
        local target = ctx.hitbox:NearestTargetInFront(player, 9, 6, 6)
        if not target then
            return false
        end
        ctx.damage(player, target.humanoid, 18 + state.Momentum * 1.5, {
            stun = 0.7,
            knockback = 58,
            tag = "BlackFlash",
            blackFlash = true
        })
        ctx.fx("BlackFlash", target.root.Position)
        return true
    end

    local target = ctx.hitbox:NearestTargetInFront(player, 8, 6, 5)
    if not target then
        return false
    end

    ctx.damage(player, target.humanoid, 9, {
        stun = 0.35,
        tag = "BlackFlashTiming"
    })
    return true
end

function Yuji.Awaken(player, ctx)
    local state = ctx.getState(player)
    state.Momentum = math.max(state.Momentum or 0, 2)
    ctx.setAttribute(player, "Momentum", state.Momentum)
    ctx.fx("YujiAwakening", ctx.rootPosition(player))
end

function Yuji.Domain(player, ctx)
    return ctx.domain:start(player, "YujiDomain", "Yuji", 34, 18)
end

function Yuji.OneTime(player, ctx)
    local pos = ctx.rootPosition(player)
    local targets = ctx.hitbox:AreaTargets(player, pos, 14)
    for _, target in ipairs(targets) do
        ctx.damage(player, target.humanoid, 42, {
            stun = 1.2,
            knockback = 72,
            tag = "YujiPerfectImpact",
            blackFlash = true
        })
    end
    ctx.fx("YujiOneTime", pos)
    return true
end

return Yuji
