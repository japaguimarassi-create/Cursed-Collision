local HitRegistry = {}

local store: {[Player]: {[string]: {[Model]: number}}} = setmetatable({}, {__mode="k"}) :: any

function HitRegistry:Begin(attacker: Player, attackId: string)
    local buckets=store[attacker]
    if not buckets then
        buckets={}
        store[attacker]=buckets
    end
    local registry={}
    buckets[attackId]=registry
    return registry
end

function HitRegistry:Has(attacker: Player, attackId: string, target: Model): boolean
    local registry=store[attacker] and store[attacker][attackId]
    return registry~=nil and registry[target]~=nil
end

function HitRegistry:Add(attacker: Player, attackId: string, target: Model)
    local registry=store[attacker] and store[attacker][attackId]
    if registry then registry[target]=os.clock() end
end

function HitRegistry:End(attacker: Player, attackId: string)
    local buckets=store[attacker]
    if buckets then buckets[attackId]=nil end
end

function HitRegistry:Clear(attacker: Player)
    store[attacker]=nil
end

return HitRegistry
