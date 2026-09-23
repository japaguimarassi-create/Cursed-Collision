--!strict

local Players = game:GetService("Players")

local Controller = require(script.Parent.Controllers.HUDController)
local Registry = require(script.Parent.Controllers.HUDRegistry)

local player = Players.LocalPlayer

local ok, hud = pcall(function()
    return Controller.new()
end)

if not ok then
    warn("[CursedCollisionHUD] initialization failed", hud)
    return
end

Registry:Set(hud)

player:GetAttributeChangedSignal("CCHUD_MenuOpen"):Connect(function()
    hud:SetVisible(player:GetAttribute("CCHUD_MenuOpen") ~= true)
end)

return nil
