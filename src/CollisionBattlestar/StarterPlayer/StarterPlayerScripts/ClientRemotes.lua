--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientBootstrap = {}

local DEFAULTS = {
    RemotesFolder = "CollisionBattlestarRemotes",
    CombatRemote = "Combat",
    StateRemote = "State",
    FXRemote = "FX",
    CommerceRemote = "Commerce",
    CompanionRemote = "Companion",
    PvPRemote = "PvP",
    MissionRemote = "Mission",
    AdminRemote = "Admin",
}

local function getNames()
    local ok, constants = pcall(function()
        return require(ReplicatedStorage.Shared.Constants)
    end)

    if ok and type(constants) == "table" then
        return {
            RemotesFolder = constants.RemotesFolder or DEFAULTS.RemotesFolder,
            CombatRemote = constants.CombatRemote or DEFAULTS.CombatRemote,
            StateRemote = constants.StateRemote or DEFAULTS.StateRemote,
            FXRemote = constants.FXRemote or DEFAULTS.FXRemote,
            CommerceRemote = constants.CommerceRemote or DEFAULTS.CommerceRemote,
            CompanionRemote = constants.CompanionRemote or DEFAULTS.CompanionRemote,
            PvPRemote = constants.PvPRemote or DEFAULTS.PvPRemote,
            MissionRemote = constants.MissionRemote or DEFAULTS.MissionRemote,
            AdminRemote = constants.AdminRemote or DEFAULTS.AdminRemote,
        }
    end

    return DEFAULTS
end

local function waitForRemote(folder: Instance, name: string, timeout: number)
    local remote = folder:WaitForChild(name, timeout)
    if not remote or not remote:IsA("RemoteEvent") then
        return nil
    end
    return remote
end

function ClientBootstrap.WaitForRemotes()
    local names = getNames()
    local folder = ReplicatedStorage:WaitForChild(names.RemotesFolder, 8)
    if not folder then
        return nil
    end

    local remotes = {
        Combat = waitForRemote(folder, names.CombatRemote, 2),
        State = waitForRemote(folder, names.StateRemote, 2),
        FX = waitForRemote(folder, names.FXRemote, 2),
        Commerce = waitForRemote(folder, names.CommerceRemote, 2),
        Companion = waitForRemote(folder, names.CompanionRemote, 2),
        PvP = waitForRemote(folder, names.PvPRemote, 2),
        Mission = waitForRemote(folder, names.MissionRemote, 2),
        Admin = waitForRemote(folder, names.AdminRemote, 2),
    }

    for _, remote in pairs(remotes) do
        if not remote then
            return nil
        end
    end

    return remotes
end

return ClientBootstrap
