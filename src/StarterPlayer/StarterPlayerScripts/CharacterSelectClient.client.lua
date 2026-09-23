--!strict

-- Entrada independente do componente Characters do HUD.
local success = pcall(function()
    local module = require(script.Parent.HUD.Characters)
    if type(module.Start) ~= "function" then
        error("HUD module Characters has no Start()")
    end
    module.Start()
end)

if not success then
    warn("[CursedCollision][HUD:Characters] component failed to start")
end
