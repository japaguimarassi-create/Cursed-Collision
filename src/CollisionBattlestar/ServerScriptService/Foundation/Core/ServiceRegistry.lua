--!strict

local Registry = {}
Registry.__index = Registry

function Registry.new()
    return setmetatable({services = {}}, Registry)
end

function Registry:Register(name: string, service)
    self.services[name] = service
end

function Registry:Get(name: string)
    local service = self.services[name]
    assert(service ~= nil, "Service unavailable: " .. name)
    return service
end

return Registry