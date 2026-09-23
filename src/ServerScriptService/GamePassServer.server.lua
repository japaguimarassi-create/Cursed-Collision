local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local GamePassService = require(ReplicatedStorage.Monetization.GamePassService)
local ShopDefinitions = require(ReplicatedStorage.Economy.ShopDefinitions)
local DataService = require(ReplicatedStorage.Economy.DataService)
local CosmeticService = require(ReplicatedStorage.Economy.CosmeticService)

local remotes = RemoteService:Get()

local function validSkin(player: Player, id: any)
    if type(id) ~= "string" or #id > 96 then
        return nil
    end

    local skin = ShopDefinitions.Skins[id]
    local data = DataService:Get(player)

    if not skin or not data or data.OwnedSkins[id] ~= true then
        return nil
    end

    if skin.Character ~= (player:GetAttribute("CharacterId") or "") then
        return nil
    end

    return skin
end

local function setUltimateSkin(player: Player, id: any)
    if player:GetAttribute("GP_UltimateSkin") ~= true then
        return false, "PASS_REQUIRED"
    end

    local skin = validSkin(player, id)
    if not skin then
        return false, "INVALID_SKIN"
    end

    local data = DataService:Get(player)
    if not data then
        return false, "DATA_NOT_READY"
    end

    data.UltimateSkin = skin.Id
    player:SetAttribute("UltimateSkin", skin.Id)
    DataService:MarkDirty(player)

    return true, "ULTIMATE_SKIN_SET"
end

local function applyInstantSkin(player: Player, id: any)
    if player:GetAttribute("GP_InstantSkin") ~= true then
        return false, "PASS_REQUIRED"
    end

    local skin = validSkin(player, id)
    if not skin then
        return false, "INVALID_SKIN"
    end

    if not CosmeticService:ApplySkin(player, skin) then
        return false, "APPLY_FAILED"
    end

    local data = DataService:Get(player)
    if data then
        data.EquippedSkin = skin.Id
        player:SetAttribute("EquippedSkin", skin.Id)
        DataService:MarkDirty(player)
    end

    return true, "SKIN_APPLIED"
end

local function applyUltimateSkin(player: Player)
    if player:GetAttribute("GP_UltimateSkin") ~= true
        or player:GetAttribute("AwakeningActive") ~= true then
        return
    end

    local skin = validSkin(player, player:GetAttribute("UltimateSkin") or "")
    if skin then
        CosmeticService:ApplySkin(player, skin)
    end
end

local function setup(player: Player)
    task.spawn(function()
        GamePassService:Sync(player)
    end)

    player:GetAttributeChangedSignal("AwakeningActive"):Connect(function()
        applyUltimateSkin(player)
    end)
end

Players.PlayerAdded:Connect(setup)

Players.PlayerRemoving:Connect(function()
end)

for _, player in ipairs(Players:GetPlayers()) do
    setup(player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
    if purchased then
        GamePassService:Sync(player)
    end
end)

remotes.GamePassAction.OnServerEvent:Connect(function(player, action, payload)
    if type(action) ~= "string" or #action > 32 or type(payload) ~= "table" then
        return
    end

    if action == "Sync" then
        GamePassService:Sync(player)
        return
    end

    if action == "SetUltimateSkin" then
        local ok, reason = setUltimateSkin(player, payload.skinId)
        if ok then
            DataService:Save(player)
        end

        remotes.GamePassEvent:FireClient(player, "Result", {
            Action = action,
            Success = ok,
            Reason = reason
        })
        return
    end

    if action == "ApplyInstantSkin" then
        local ok, reason = applyInstantSkin(player, payload.skinId)
        if ok then
            DataService:Save(player)
        end

        remotes.GamePassEvent:FireClient(player, "Result", {
            Action = action,
            Success = ok,
            Reason = reason
        })
    end
end)

return nil
