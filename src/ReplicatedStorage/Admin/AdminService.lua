local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Economy.DataService)
local ShopService = require(ReplicatedStorage.Economy.ShopService)
local QuestService = require(ReplicatedStorage.Economy.QuestService)

local AdminService = {}

function AdminService:IsOwner(player)
    return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

function AdminService:Target(targetUserId)
    local userId = math.floor(tonumber(targetUserId) or 0)
    if userId <= 0 then
        return nil
    end
    return Players:GetPlayerByUserId(userId)
end

function AdminService:Execute(actor, action, payload, announce)
    if not self:IsOwner(actor) then
        return false, "OWNER_ONLY"
    end

    payload = type(payload) == "table" and payload or {}
    local target = self:Target(payload.targetUserId) or actor
    local amount = math.floor(tonumber(payload.amount) or 0)

    if action == "GrantCredits" then
        amount = math.clamp(amount, 1, 1000000000)
        DataService:AddCredits(target, amount)
        DataService:Save(target)
        return true, "Granted " .. tostring(amount) .. " Credits."

    elseif action == "SetCredits" then
        amount = math.clamp(amount, 0, 1000000000)
        DataService:SetCredits(target, amount)
        DataService:Save(target)
        return true, "Credits set to " .. tostring(amount) .. "."

    elseif action == "RemoveCredits" then
        amount = math.clamp(amount, 1, 1000000000)
        DataService:SpendCredits(target, amount)
        DataService:Save(target)
        return true, "Removed " .. tostring(amount) .. " Credits."

    elseif action == "GiveAllEmotes" then
        ShopService:GiveAllEmotes(target)
        DataService:Save(target)
        return true, "All 150 emotes granted."

    elseif action == "GiveAllSkins" then
        ShopService:GiveAllSkins(target)
        DataService:Save(target)
        return true, "All skins for the current character granted."

    elseif action == "ResetQuests" then
        QuestService:ResetAll(target)
        DataService:Save(target)
        announce(target, "Quest progress reset by Owner.")
        return true, "Quest progress reset."

    elseif action == "CompleteQuest" then
        local questId = type(payload.questId) == "string" and payload.questId or ""
        if #questId > 96 then
            return false, "INVALID_QUEST"
        end
        if QuestService:CompleteQuest(target, questId) then
            DataService:Save(target)
            return true, "Quest completed: " .. questId
        end
        return false, "QUEST_NOT_FOUND"

    elseif action == "Heal" then
        local character = target.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            return false, "NO_HUMANOID"
        end
        humanoid.Health = humanoid.MaxHealth
        return true, "Healed " .. target.Name .. "."

    elseif action == "Announce" then
        local message = type(payload.message) == "string" and payload.message or ""
        message = message:sub(1, 180)
        if message == "" then
            return false, "EMPTY_MESSAGE"
        end
        announce(nil, "[OWNER] " .. message)
        return true, "Announcement sent."

    elseif action == "Kick" then
        if target == actor then
            return false, "CANNOT_KICK_SELF"
        end
        local reason = type(payload.reason) == "string" and payload.reason:sub(1, 120) or "Removed by Owner."
        target:Kick(reason)
        return true, "Player kicked."

    elseif action == "SaveAll" then
        for _, player in ipairs(Players:GetPlayers()) do
            DataService:Save(player)
        end
        return true, "All active profiles saved."

    end

    return false, "UNKNOWN_ADMIN_ACTION"
end

return AdminService
