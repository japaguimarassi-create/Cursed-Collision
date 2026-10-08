--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local HUD = require(script.Parent.HUD.Root)
local InputService = require(script.Parent.Input.Service)
local CombatFX = require(script.Parent.CombatFX.Service)
local CameraService = require(script.Parent.Camera.Service)

local function waitForRemotes()
    local folder = ReplicatedStorage:WaitForChild(Constants.RemotesFolder, 12)
    if not folder then
        return nil
    end

    local combat = folder:WaitForChild(Constants.CombatRemote, 6)
    local state = folder:WaitForChild(Constants.StateRemote, 6)
    local fx = folder:WaitForChild(Constants.FXRemote, 6)

    if not combat or not state or not fx then
        return nil
    end

    if not combat:IsA("RemoteEvent") or not state:IsA("RemoteEvent") or not fx:IsA("RemoteEvent") then
        return nil
    end

    return {
        Combat = combat,
        State = state,
        FX = fx,
    }
end

local remotes = waitForRemotes()

if not remotes then
    warn("Collision Battlestar remotes unavailable")
    return
end

local hud = HUD.new(remotes)
local input = InputService.new(remotes, hud)
local combatFX = CombatFX.new(remotes)
local camera = CameraService.new()

camera:Start()
combatFX:Start()
input:Start()
