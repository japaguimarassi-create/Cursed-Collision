local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local Config = require(ReplicatedStorage.Monetization.GamePassConfig)

local remotes = RemoteService:Get()

local GamePassService = {}

local keys = {
    "UltimateSkin",
    "KillSound",
    "InstantSkin"
}

local function validPass(pass)
    return pass and type(pass.Id) == "number" and pass.Id > 0
end

function GamePassService:Owns(player: Player, key: string): boolean
    local pass = Config[key]

    if not validPass(pass) then
        return false
    end

    local success, result = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
    end)

    return success and result == true
end

function GamePassService:Sync(player: Player)
    if not player.Parent then
        return
    end

    local result = {}

    for _, key in ipairs(keys) do
        local pass = Config[key]
        local owned = self:Owns(player, key)
        player:SetAttribute(pass.Attribute, owned)
        result[key] = owned
    end

    remotes.GamePassEvent:FireClient(player, "Sync", result)
end

function GamePassService:NotifyKill(player: Player)
    if player:GetAttribute("GP_KillSound") ~= true then
        return
    end

    if type(Config.KillSoundId) ~= "string" or Config.KillSoundId == "" then
        return
    end

    remotes.GamePassEvent:FireClient(player, "KillSound", {
        SoundId = Config.KillSoundId,
        Volume = tonumber(Config.KillSoundVolume) or 1
    })
end

return GamePassService
