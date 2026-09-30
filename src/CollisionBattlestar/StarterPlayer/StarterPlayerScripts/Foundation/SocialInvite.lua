--!strict

local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")

local Invite = {}

function Invite.CanInvite(player: Player): boolean
    local ok, result = pcall(function()
        return SocialService:CanSendGameInviteAsync(player)
    end)
    return ok and result == true
end

function Invite.PromptInvite(player: Player): boolean
    if not Invite.CanInvite(player) then
        return false
    end
    local ok = pcall(function()
        SocialService:PromptGameInvite(player)
    end)
    return ok
end

function Invite.PromptCurrentPlayer(): boolean
    local player = Players.LocalPlayer
    return Invite.PromptInvite(player)
end

return Invite
