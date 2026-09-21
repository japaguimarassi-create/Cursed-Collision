local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Sukuna = {}

function Sukuna.Init(player, ctx)
    local state = ctx.getState(player)
    state.SlashAdaptation = "Neutral"
    ctx.setAttribute(player, "CharacterTitle", "Slash Adaptation")
    ctx.setAttribute(player, "SlashState", "Neutral")
end

function Sukuna.Special(player, ctx)
    if not ctx.spendCE(player, Config.CE.Costs.Special) then
        return false
    end

    local target = ctx.hitbox:NearestTargetInFront(player, 14, 7, 7)
    if not target then
        return false
    end

    local state = ctx.getState(player)
    local distance = (target.root.Position - ctx.rootPosition(player)).Magnitude
    local damage = state.SlashAdaptation == "Cleave" and 20 or 14

    if distance <= 6 then
        damage += 5
    elseif distance >= 11 then
        damage -= 2
    end

    ctx.damage(player, target.humanoid, damage, {
        stun = 0.42,
        knockback = 34,
        tag = "DismantleCleave"
    })
    ctx.fx("SukunaSlash", target.root.Position, state.SlashAdaptation, distance)
    return true
end

function Sukuna.Skill(player, ctx)
    local state = ctx.getState(player)
    if state.SlashAdaptation == "Cleave" then
        state.SlashAdaptation = "Fire"
    elseif state.SlashAdaptation == "Fire" then
        state.SlashAdaptation = "Dismantle"
    else
        state.SlashAdaptation = "Cleave"
    end
    ctx.setAttribute(player, "SlashState", state.SlashAdaptation)

    if state.SlashAdaptation == "Fire" then
        if not ctx.spendCE(player, 20) then
            return false
        end
        local pos = ctx.rootPosition(player)
        local targets = ctx.hitbox:AreaTargets(player, pos, 10)
        for _, target in ipairs(targets) do
            ctx.damage(player, target.humanoid, 18, {
                stun = 0.6,
                knockback = 62,
                tag = "FireArrow"
            })
        end
        ctx.fx("SukunaFire", pos)
    end

    return true
end

function Sukuna.Awaken(player, ctx)
    local state = ctx.getState(player)
    state.SlashAdaptation = "Cleave"
    ctx.setAttribute(player, "SlashState", "Cleave")
    ctx.fx("SukunaAwakening", ctx.rootPosition(player))
end

function Sukuna.Domain(player, ctx)
    return ctx.domain:start(player, "MalevolentShrine", "Sukuna", 40, 18)
end

function Sukuna.OneTime(player, ctx)
    local pos = ctx.rootPosition(player)
    local targets = ctx.hitbox:AreaTargets(player, pos, 18)
    for _, target in ipairs(targets) do
        local distance = (target.root.Position - pos).Magnitude
        local damage = 44 + math.max(0, 12 - distance)
        ctx.damage(player, target.humanoid, damage, {
            stun = 1.15,
            knockback = 90,
            tag = "ShrineExecution"
        })
    end
    ctx.fx("SukunaOneTime", pos)
    return true
end

return Sukuna
