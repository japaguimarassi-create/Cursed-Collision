--!strict

-- Entrada independente do componente Combat do HUD.
local success = pcall(function()
    local module = require(script.Parent.HUD.Combat)
    if type(module.Start) ~= "function" then
        error("HUD module Combat has no Start()")
    end
    module.Start()
end)

if not success then
    warn("[CursedCollision][HUD:Combat] component failed to start")
end
