--!strict

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local version = 0

local HUDMenuRouter = {}

local function request(command: string)
    version += 1
    player:SetAttribute("CCHUD_Command", command)
    player:SetAttribute("CCHUD_CommandVersion", version)
end

function HUDMenuRouter:Character()
    request("Characters")
end

function HUDMenuRouter:Emotes()
    request("Emotes")
end

function HUDMenuRouter:Menu()
    request("Menu")
end

function HUDMenuRouter:Owner()
    request("Owner")
end

function HUDMenuRouter:CloseAll()
    request("CloseAll")
end

return HUDMenuRouter
