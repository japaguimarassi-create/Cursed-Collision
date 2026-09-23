local Timeline = {}

local defaults = {
    Melee={Startup=0.08,Active=0.05,Recovery=0.18},
    Projectile={Startup=0.16,Active=0.03,Recovery=0.28},
    Area={Startup=0.20,Active=0.07,Recovery=0.35},
    Burst={Startup=0.22,Active=0.08,Recovery=0.42},
    Control={Startup=0.18,Active=0.05,Recovery=0.30},
    Mobility={Startup=0.10,Active=0.08,Recovery=0.25},
    Utility={Startup=0.12,Active=0.05,Recovery=0.22}
}

function Timeline:Get(move)
    local base = defaults[move.Type] or defaults.Melee
    local result = {
        Startup=tonumber(move.Startup) or base.Startup,
        Active=tonumber(move.ActiveTime) or base.Active,
        Recovery=tonumber(move.Recovery) or base.Recovery
    }
    result.Total=result.Startup+result.Active+result.Recovery
    return result
end

function Timeline:Markers(move)
    local phase=self:Get(move)
    return {
        Startup=0,
        Windup=phase.Startup*0.5,
        HitFrame=phase.Startup,
        Impact=phase.Startup+phase.Active*0.5,
        Recovery=phase.Startup+phase.Active,
        End=phase.Total
    }
end

return Timeline
