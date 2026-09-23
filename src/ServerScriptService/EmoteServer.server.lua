--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local EmoteService = require(script.Parent.CombatCore.EmoteService)

local remotes = RemoteService:Get()

local function setup(player: Player)
    player.CharacterAdded:Connect(function()
        EmoteService:Clear(player)
    end)
end

Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(player)
    EmoteService:Clear(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    setup(player)
end

remotes.EmoteAction.OnServerEvent:Connect(function(
    player: Player,
    action: any,
    payload: any
)
    if type(action) ~= "string"
        or #action > 24
        or type(payload) ~= "table" then
        return
    end

    if action == "Start" then
        local id = type(payload.Id) == "string" and payload.Id or ""
        if #id > 64 then
            return
        end

        EmoteService:Start(player, id)
    elseif action == "Stop" then
        EmoteService:Stop(player)
    elseif action == "SetWheel" then
        local ids = type(payload.Ids) == "table" and payload.Ids or nil
        if not ids then
            return
        end

        EmoteService:SetWheel(player, ids)
    end
end)

return nil
