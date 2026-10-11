local Players = game:GetService("Players")

local ProgressionService = {}
local profiles
local dailyRemote
local codeRemote
local questRemote
local notify
local cooldowns = {}
local started = false

local CODES = table.freeze({
    FARMFAMILY = 1000,
    WILDSTART = 1500,
    BARNBOOST = 2500,
})

local QUESTS = table.freeze({
    FirstCapture = "FirstCapture",
    FirstBarn = "FirstBarn",
    Collector = "Collector",
    FullBarn = "FullBarn",
})

local MESSAGES = {
    ["already-claimed"] = "You have already claimed today's reward.",
    ["already-redeemed"] = "This code has already been redeemed on your account.",
    ["requirements"] = "Complete the quest requirements before claiming the reward.",
    ["profile-busy"] = "Your data is saving. Try again in a moment.",
    ["profile-not-loaded"] = "Your player data is not ready yet.",
    ["datastore-error"] = "The reward could not be saved. Nothing was claimed.",
}

local function allowed(player, key)
    local now = os.clock()
    cooldowns[player] = cooldowns[player] or {}
    if now - (cooldowns[player][key] or 0) < 1.5 then
        return false
    end
    cooldowns[player][key] = now
    return true
end

function ProgressionService.Start(profileService, dailyRewardRemote, redeemCodeRemote, questClaimRemote, notifyFunction)
    if started then
        return
    end
    started = true
    profiles = profileService
    dailyRemote = dailyRewardRemote
    codeRemote = redeemCodeRemote
    questRemote = questClaimRemote
    notify = notifyFunction

    dailyRemote.OnServerEvent:Connect(function(player)
        if player.Parent ~= Players or not profiles.IsLoaded(player) or not allowed(player, "Daily") then
            return
        end
        local success, reward, streak = profiles.ClaimDailyReward(player)
        if success then
            notify(player, "Daily reward claimed: +" .. tostring(reward) .. " coins. Streak: " .. tostring(streak) .. "/7.", "Success")
        else
            notify(player, MESSAGES[reward] or "Daily reward unavailable.", "Warning")
        end
    end)

    codeRemote.OnServerEvent:Connect(function(player, rawCode)
        if player.Parent ~= Players or not profiles.IsLoaded(player) or not allowed(player, "Code") then
            return
        end
        if type(rawCode) ~= "string" or #rawCode > 48 then
            notify(player, "Enter a valid code.", "Warning")
            return
        end
        local code = string.upper(string.gsub(rawCode, "%s+", ""))
        local reward = CODES[code]
        if not reward then
            notify(player, "Unknown or expired code.", "Warning")
            return
        end
        local success, result = profiles.RedeemCode(player, code, reward)
        if success then
            notify(player, "Code redeemed: +" .. tostring(result) .. " coins.", "Success")
        else
            notify(player, MESSAGES[result] or "Code redemption failed.", "Warning")
        end
    end)

    questRemote.OnServerEvent:Connect(function(player, questId)
        if player.Parent ~= Players or not profiles.IsLoaded(player) or not allowed(player, "Quest") then
            return
        end
        if type(questId) ~= "string" or not QUESTS[questId] then
            return
        end
        local success, result = profiles.ClaimQuest(player, questId)
        if success then
            notify(player, "Quest completed! +" .. tostring(result) .. " coins.", "Success")
        else
            notify(player, MESSAGES[result] or "Quest reward unavailable.", "Warning")
        end
    end)
end

function ProgressionService.RemovePlayer(player)
    cooldowns[player] = nil
end

return ProgressionService
