--!strict

-- Este LocalScript é apenas um ponto de entrada isolado.
-- Uma falha deste componente não impede os demais módulos do HUD de iniciarem.

local ok, moduleOrError = pcall(function()
    return require(script.Parent.HUD.Characters)
end)

if not ok then
    warn("[CursedCollision][HUD:Characters] startup failed:", moduleOrError)
    return
end

local starter = moduleOrError.Start
if type(starter) ~= "function" then
    warn("[CursedCollision][HUD:Characters] module has no Start()")
    return
end

local success, err = xpcall(starter, debug.traceback)
if not success then
    warn("[CursedCollision][HUD:Characters] runtime failed:", err)
end
