--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)

local ClientBootstrap = {}

local function waitForRemote(folder: Instance, name: string, timeout: number)
    local remote = folder:WaitForChild(name, timeout)
    if not remote or not remote:IsA("RemoteEvent") then
        return nil
    end
    return remote
end

function ClientBootstrap.WaitForRemotes()
    local folder = ReplicatedStorage:WaitForChild(Constants.RemotesFolder, 12)
    if not folder then
        return nil
    end

    local remotes = {
        Combat = waitForRemote(folder, Constants.CombatRemote, 6),
        State = waitForRemote(folder, Constants.StateRemote, 6),
        FX = waitForRemote(folder, Constants.FXRemote, 6),
        Commerce = waitForRemote(folder, "Commerce", 6),
        Companion = waitForRemote(folder, "Companion", 6),
        PvP = waitForRemote(folder, "PvP", 6),
        Mission = waitForRemote(folder, "Mission", 6),
        Admin = waitForRemote(folder, "Admin", 6),
    }

    for _, remote in pairs(remotes) do
        if not remote then
            return nil
        end
    end

    return remotes
end

return ClientBootstrap
