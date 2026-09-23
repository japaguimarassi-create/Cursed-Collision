local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local GamePassConfig = require(ReplicatedStorage.Monetization.GamePassConfig)
local ShopDefinitions = require(ReplicatedStorage.Economy.ShopDefinitions)
local DataService = require(ReplicatedStorage.Economy.DataService)
local CosmeticService = require(ReplicatedStorage.Economy.CosmeticService)

local remotes = RemoteService:Get()

local PASS_KEYS = {
    "UltimateSkin",
    "KillSound",
    "InstantSkin"
}

local function configured(pass)
    return type(pass.Id) == "number" and pass.Id > 0
end

local function owns(player, key)
    local pass = GamePassConfig[key]

    if not pass or not configured(pass) then
        return false
    end

    local success, result = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
    end)

    return success and result == true
end

local function sync(player)
    if not player.Parent then
        return
    end

    local owned = {}

    for _, key in ipairs(PASS_KEYS) do
        local pass = GamePassConfig[key]
        local value = owns(player, key)

        player:SetAttribute(pass.Attribute, value)
        owned[key] = value
    end

    remotes.GamePassEvent:FireClient(player, "Sync", owned)
end

local function validSkinForPlayer(player, skinId)
    if type(skinId) ~= "string" or #skinId > 96 then
        return nil
    end

    local skin = ShopDefinitions.Skins[skinId]

    if not skin then
        return nil
    end

    if skin.Character ~= (player:GetAttribute("CharacterId") or "") then
        return nil
    end

    local data = DataService:Get(player)

    if not data or not data.OwnedSkins[skinId] then
        return nil
    end

    return skin
end

local function applyInstant(player, skinId)
    if player:GetAttribute("GP_InstantSkin") ~= true then
        return false, "PASS_REQUIRED"
    end

    local skin = validSkinForPlayer(player, skinId)

    if not skin then
        return false, "INVALID_SKIN"
    end

    if not CosmeticService:ApplySkin(player, skin) then
        return false, "APPLY_FAILED"
    end

    local data = DataService:Get(player)

    if data then
        data.EquippedSkin = skinId
        DataService:MarkDirty(player)
        DataService:Save(player)
    end

    return true, "SKIN_APPLIED"
end

local function setUltimateSkin(player, skinId)
    if player:GetAttribute("GP_UltimateSkin") ~= true then
        return false, "PASS_REQUIRED"
    end

    local skin = validSkinForPlayer(player, skinId)

    if not skin then
        return false, "INVALID_SKIN"
    end

    if not DataService:SetUltimateSkin(player, skinId) then
        return false, "SAVE_FAILED"
    end

    return true, "ULTIMATE_SKIN_SET"
end

local function applyUltimateSkin(player)
    if player:GetAttribute("GP_UltimateSkin") ~= true then
        return
    end

    if player:GetAttribute("AwakeningActive") ~= true then
        return
    end

    local skinId = player:GetAttribute("UltimateSkin") or ""
    if skinId == "" then
        return
    end

    local skin = validSkinForPlayer(player, skinId)
    if skin then
        CosmeticService:ApplySkin(player, skin)
    end
end

local function setupPlayer(player)
    task.spawn(function()
        sync(player)
    end)

    player:GetAttributeChangedSignal("AwakeningActive"):Connect(function()
        applyUltimateSkin(player)
    end)
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, purchasedPassId, wasPurchased)
    if not wasPurchased then
        return
    end

    for _, key in ipairs(PASS_KEYS) do
        local pass = GamePassConfig[key]

        if configured(pass) and pass.Id == purchasedPassId then
            sync(player)
            return
        end
    end
end)

remotes.GamePassAction.OnServerEvent:Connect(function(player, action, payload)
    if type(action) ~= "string" or #action > 32 or type(payload) ~= "table" then
        return
    end

    if action == "Sync" then
        sync(player)
        return
    end

    if action == "ApplyInstantSkin" then
        local ok, reason = applyInstant(player, payload.skinId)

        remotes.GamePassEvent:FireClient(player, "Result", {
            Action = action,
            Success = ok,
            Reason = reason
        })
        return
    end

    if action == "SetUltimateSkin" then
        local ok, reason = setUltimateSkin(player, payload.skinId)

        remotes.GamePassEvent:FireClient(player, "Result", {
            Action = action,
            Success = ok,
            Reason = reason
        })
        return
    end
end)

return nil
