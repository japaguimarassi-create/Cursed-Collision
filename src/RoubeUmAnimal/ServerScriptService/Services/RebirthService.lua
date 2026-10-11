local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local RebirthService = {}
local profiles
local animalService
local requestRemote
local notify
local cooldowns = {}
local started = false

function RebirthService.Start(profileService, animals, remote, notifyFunction)
    if started then
        return
    end
    started = true
    profiles = profileService
    animalService = animals
    requestRemote = remote
    notify = notifyFunction

    requestRemote.OnServerEvent:Connect(function(player)
        if player.Parent ~= Players or not profiles.IsLoaded(player) or player:GetAttribute("RebirthInProgress") then
            return
        end
        local now = os.clock()
        if now - (cooldowns[player] or 0) < 2 then
            return
        end
        cooldowns[player] = now
        if animalService.GetCarried(player) then
            notify(player, "Store your carried animal before rebirthing.", "Warning")
            return
        end
        player:SetAttribute("RebirthInProgress", true)
        local ok, success, result = pcall(profiles.PerformRebirth, player)
        player:SetAttribute("RebirthInProgress", false)
        if not ok then
            warn("StealAnAnimal: rebirth error: " .. tostring(success))
            notify(player, "Rebirth was cancelled safely; your saved data was not reset.", "Error")
            return
        end
        if not success then
            local messages = {
                requirements = "Reach Speed " .. tostring(Config.MaxSpeedLevel) .. " and save at least " .. tostring(Config.RebirthCoinsRequired) .. " coins first.",
                ["carrying-animal"] = "Store your carried animal before rebirthing.",
                ["max-rebirths"] = "You reached the rebirth limit.",
                ["profile-not-loaded"] = "Your profile is still loading.",
                ["profile-busy"] = "Your profile is saving. Try again shortly.",
                ["datastore-error"] = "Rebirth could not be saved. Nothing was reset.",
                ["session-lock"] = "Your session lost its profile lock. Rejoin to protect your data.",
            }
            notify(player, messages[result] or "Rebirth is unavailable right now.", "Warning")
            return
        end
        animalService.ApplyMovement(player)
        notify(player, "Rebirth " .. tostring(result) .. " complete. Your barn income bonus increased by 10%.", "Success")
    end)
end

function RebirthService.RemovePlayer(player)
    cooldowns[player] = nil
    player:SetAttribute("RebirthInProgress", false)
end

return RebirthService
