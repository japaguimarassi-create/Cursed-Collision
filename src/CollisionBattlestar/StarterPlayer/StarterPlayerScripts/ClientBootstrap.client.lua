--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientBootstrap = require(script.Parent.ClientRemotes)
local HUD = require(script.Parent.HUD.Root)
local InputService = require(script.Parent.Input.Service)
local CombatFX = require(script.Parent.CombatFX.Service)
local CameraService = require(script.Parent.Camera.Service)
local AdvancedPanels = require(script.Parent.HUD.AdvancedPanels)
local SocialInvite = require(script.Parent.SocialInvite.Service)

local remotes = ClientBootstrap.WaitForRemotes()

if not remotes then
    warn("Collision Battlestar remotes unavailable")
    return
end

local hud = HUD.new(remotes)
local input = InputService.new(remotes, hud)
local combatFX = CombatFX.new(remotes)
local camera = CameraService.new()
local socialInvite = SocialInvite.new()
local advancedPanels = AdvancedPanels.new(hud, remotes, socialInvite)

camera:Start()
combatFX:Start()
input:Start()
socialInvite:Start()
