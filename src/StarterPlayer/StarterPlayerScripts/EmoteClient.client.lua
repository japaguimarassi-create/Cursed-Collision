--!strict

-- Entrada independente do componente Emotes do HUD.
local success = pcall(function()
    local module = require(script.Parent.HUD.Emotes)
    if type(module.Start) ~= "function" then
        error("HUD module Emotes has no Start()")
    end
    module.Start()
end)

if not success then
    warn("[CursedCollision][HUD:Emotes] component failed to start")
end
