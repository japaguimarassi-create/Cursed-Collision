local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Gojo = {}

function Gojo.Init(player, ctx)
    local state = ctx.getState(player)
    state.Infinity = true
    state.LimitlessState = "Neutral"
    ctx.setAttribute(player, "CharacterTitle", "Infinity Management")
    ctx.setAttribute(player, "Infinity", true)
    ctx.setAttribute(player, "LimitlessState", "Neutral")
end

function Gojo.Special(player, ctx)
    local state = ctx.getState(player)

    if state.LimitlessState == "Red" then
        if not ctx.spendCE(player, Config.CE.Costs.Special) then
            return false
        end
        local target = ctx.hitbox:NearestTargetInFront(player, 15, 10, 8)
        if not target then
            return false
        end
        ctx.damage(player, target.humanoid, 24, {
            stun = 0.55,
            knockback = 92,
            tag = "Red"
        })
        ctx.fx("GojoRed", target.root.Position)
        return true
    end

    if state.LimitlessState == "Purple" then
        if not ctx.spendCE(player, 34) then
            return false
        end
        local target = ctx.hitbox:NearestTargetInFront(player, 22, 8, 8)
        if not target then
            return false
        end
        ctx.damage(player, target.humanoid, 38, {
            stun = 0.9,
            knockback = 120,
            tag = "HollowPurple"
        })
        ctx.fx("GojoPurple", target.root.Position)
        return true
    end

    if not ctx.spendCE(player, Config.CE.Costs.Special) then
        return false
    end

    local target = ctx.hitbox:NearestTargetInFront(player, 14, 8, 7)
    if not target then
        return false
    end

    ctx.damage(player, target.humanoid, 18, {
        stun = 0.4,
        knockback = 55,
        tag = "Blue"
    })
    ctx.fx("GojoBlue", target.root.Position)
    return true
end

function Gojo.Skill(player, ctx)
    local state = ctx.getState(player)
    local nextState = {
        Neutral = "Red",
        Red = "Purple",
        Purple = "Neutral"
    }
    state.LimitlessState = nextState[state.LimitlessState] or "Neutral"
    ctx.setAttribute(player, "LimitlessState", state.LimitlessState)

    if state.LimitlessState == "Neutral" then
        state.Infinity = not state.Infinity
    end

    ctx.setAttribute(player, "Infinity", state.Infinity)
    ctx.fx("GojoState", ctx.rootPosition(player), state.LimitlessState, state.Infinity)
    return true
end

function Gojo.Awaken(player, ctx)
    local state = ctx.getState(player)
    state.Infinity = true
    state.LimitlessState = "Purple"
    ctx.setAttribute(player, "Infinity", true)
    ctx.setAttribute(player, "LimitlessState", "Purple")
    ctx.fx("GojoAwakening", ctx.rootPosition(player))
end

function Gojo.Domain(player, ctx)
    return ctx.domain:start(player, "UnlimitedVoid", "Gojo", 36, 18)
end

function Gojo.OneTime(player, ctx)
    local pos = ctx.rootPosition(player)
    local targets = ctx.hitbox:AreaTargets(player, pos, 16)
    for _, target in ipairs(targets) do
        ctx.damage(player, target.humanoid, 48, {
            stun = 1.3,
            tag = "UnlimitedVoidStrike"
        })
    end
    ctx.fx("GojoOneTime", pos)
    return true
end

function Gojo.OnIncomingDamage(player, ctx, amount)
    local state = ctx.getState(player)
    if state.Infinity and not state.InfinityBypassUntil then
        return 0
    end
    return amount
end

return Gojo
