--!strict

local Players = game:GetService("Players")

local HUDController = require(script.Parent.Controllers.HUDController)
local HUDInputRouter = require(script.Parent.Controllers.HUDInputRouter)
local HUDMenuRouter = require(script.Parent.Controllers.HUDMenuRouter)
local HUDActionBus = require(script.Parent.Controllers.HUDActionBus)

local player = Players.LocalPlayer
local hud = HUDController.new()

local function action(name: string)
    HUDActionBus:Emit(name :: any)
end

HUDInputRouter.Bind(hud, {
    Action = action,
    Dash = function()
        action("Dash")
    end,
    BlockToggle = function()
        action("BlockToggle")
    end,
    SprintToggle = function()
        action("SprintToggle")
    end,
    CharacterMenu = function()
        HUDMenuRouter:Character()
    end,
    EmoteMenu = function()
        HUDMenuRouter:Emotes()
    end,
    MainMenu = function()
        HUDMenuRouter:Menu()
    end,
    OwnerMenu = function()
        HUDMenuRouter:Owner()
    end
})

player:GetAttributeChangedSignal("IsGameOwner"):Connect(function()
    hud:SetOwnerVisible(player:GetAttribute("IsGameOwner") == true)
end)

hud:SetOwnerVisible(player:GetAttribute("IsGameOwner") == true)

return nil
