--!strict

-- Entrada independente do componente Owner do HUD.
local success = pcall(function()
    local module = require(script.Parent.HUD.Owner)
    if type(module.Start) ~= "function" then
        error("HUD module Owner has no Start()")
    end
    module.Start()
end)

if not success then
    warn("[CursedCollision][HUD:Owner] component failed to start")
end
