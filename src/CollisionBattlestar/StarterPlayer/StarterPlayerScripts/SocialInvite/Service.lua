--!strict

local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")

local SocialInvite = {}
SocialInvite.__index = SocialInvite

function SocialInvite.new()
    return setmetatable({
        player = Players.LocalPlayer,
    }, SocialInvite)
end

function SocialInvite:CanInvite()
    local success, result = pcall(function()
        return SocialService:CanSendGameInviteAsync(self.player)
    end)

    return success and result == true
end

function SocialInvite:Prompt()
    if not self:CanInvite() then
        return false, "invite_unavailable"
    end

    local success, err = pcall(function()
        SocialService:PromptGameInvite(self.player)
    end)

    if not success then
        return false, tostring(err)
    end

    return true, "prompted"
end

function SocialInvite:Start()
end

return SocialInvite
