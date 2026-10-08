--!strict

local Registry = {}
Registry.__index = Registry

function Registry.new()
    return setmetatable({
        services = {},
    }, Registry)
end

function Registry:Register(name: string, service: any)
    assert(type(name) == "string" and name ~= "", "service name required")
    assert(self.services[name] == nil, "service already registered: " .. name)
    self.services[name] = service
    return service
end

function Registry:Get(name: string)
    local service = self.services[name]
    assert(service ~= nil, "service not registered: " .. name)
    return service
end

function Registry:StartAll()
    for name, service in pairs(self.services) do
        if type(service.Start) == "function" then
            local ok, err = pcall(function()
                service:Start()
            end)
            if not ok then
                error(("service start failed [%s]: %s"):format(name, tostring(err)))
            end
        end
    end
end

return Registry
