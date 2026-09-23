--!strict

-- Entrada independente do componente Menu do HUD.
local success = pcall(function()
    local module = require(script.Parent.HUD.Menu)
    if type(module.Start) ~= "function" then
        error("HUD module Menu has no Start()")
    end
    module.Start()
end)

if not success then
    warn("[CursedCollision][HUD:Menu] component failed to start")
end
