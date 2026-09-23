local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local DataService = require(ReplicatedStorage.Economy.DataService)
local ShopService = require(ReplicatedStorage.Economy.ShopService)
local QuestService = require(ReplicatedStorage.Economy.QuestService)
local CosmeticService = require(ReplicatedStorage.Economy.CosmeticService)
local AdminService = require(ReplicatedStorage.Admin.AdminService)

local remotes = RemoteService:Get()

local function safeSync(player)
    if not player or not player.Parent then
        return
    end

    remotes.AccountEvent:FireClient(player, "Sync", {
        Economy = ShopService:Snapshot(player),
        Quests = QuestService:Snapshot(player),
        IsOwner = AdminService:IsOwner(player)
    })
end

local function notice(player, message, success)
    if player and player.Parent then
        remotes.AccountEvent:FireClient(player, "Notice", {
            Message = message,
            Success = success == true
        })
    end
end

local function sendAdminPlayers()
    for _, owner in ipairs(Players:GetPlayers()) do
        if AdminService:IsOwner(owner) then
            local list = {}

            for _, player in ipairs(Players:GetPlayers()) do
                table.insert(list, {
                    UserId = player.UserId,
                    Name = player.Name,
                    DisplayName = player.DisplayName
                })
            end

            table.sort(list, function(a, b)
                return a.Name < b.Name
            end)

            remotes.AccountEvent:FireClient(owner, "AdminPlayers", list)
        end
    end
end

local function applyEquippedSkin(player)
    local data = DataService:Get(player)

    if not data then
        return
    end

    local equipped = data.EquippedSkin

    if equipped ~= "" and data.OwnedSkins[equipped] then
        local skin = ShopService:GetSkin(equipped)

        if not skin or skin.Character ~= (player:GetAttribute("CharacterId") or "") then
            data.EquippedSkin = ""
            player:SetAttribute("EquippedSkin", "")
            DataService:MarkDirty(player)
            return
        end

        if not CosmeticService:ApplySkin(player, skin) then
            data.EquippedSkin = ""
            player:SetAttribute("EquippedSkin", "")
            DataService:MarkDirty(player)
        end
    else
        CosmeticService:ClearSkin(player)
    end
end

local function setupPlayer(player)
    local loaded = DataService:Initialize(player)
    QuestService:Initialize(player)

    player:SetAttribute("IsGameOwner", AdminService:IsOwner(player))

    if not loaded then
        notice(player, "Persistent data is temporarily unavailable. Purchases are disabled until the profile loads.", false)
    end

    player.CharacterAdded:Connect(function()
        task.delay(0.45, function()
            if player.Parent then
                applyEquippedSkin(player)
            end
        end)
    end)

    player:GetAttributeChangedSignal("CharacterId"):Connect(function()
        task.defer(function()
            if player.Parent then
                applyEquippedSkin(player)
            end
        end)
        safeSync(player)
    end)

    player.CharacterAppearanceLoaded:Connect(function()
        applyEquippedSkin(player)
    end)

    safeSync(player)
    sendAdminPlayers()
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
    DataService:PlayerRemoving(player)
    sendAdminPlayers()
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(setupPlayer, player)
end

remotes.AccountAction.OnServerEvent:Connect(function(player, action, payload)
    if type(action) ~= "string" or #action > 32 or type(payload) ~= "table" then
        return
    end

    if action == "Sync" then
        safeSync(player)
        return
    end

    if action == "Buy" then
        local category = type(payload.category) == "string" and payload.category or ""
        local itemId = type(payload.id) == "string" and payload.id or ""

        if #category > 16 or #itemId > 96 or category ~= "Skins" then
            return
        end

        local ok, reason = ShopService:Buy(player, category, itemId)

        if ok then
            notice(player, reason == "ALREADY_OWNED" and "You already own this skin." or "Skin purchased.", true)
            safeSync(player)
        else
            local messages = {
                DATA_NOT_READY = "Your profile is not ready yet.",
                UNKNOWN_ITEM = "That skin does not exist.",
                UNKNOWN_CATEGORY = "Invalid shop category.",
                NOT_ENOUGH_CREDITS = "Not enough Credits."
            }

            notice(player, messages[reason] or "Purchase failed.", false)
        end

        return
    end

    if action == "Equip" then
        local category = type(payload.category) == "string" and payload.category or ""
        local itemId = type(payload.id) == "string" and payload.id or ""

        if #category > 16 or #itemId > 96 or category ~= "Skins" then
            return
        end

        local ok, reason = ShopService:Equip(player, category, itemId)

        if ok then
            notice(player, "Skin equipped.", true)
            safeSync(player)
        else
            local messages = {
                DATA_NOT_READY = "Your profile is not ready yet.",
                UNKNOWN_ITEM = "That skin does not exist.",
                NOT_OWNED = "You do not own that skin.",
                WRONG_CHARACTER = "That skin belongs to another character.",
                SKIN_APPLY_FAILED = "Could not apply that skin."
            }

            notice(player, messages[reason] or "Equip failed.", false)
        end

        return
    end
end)

remotes.AdminAction.OnServerEvent:Connect(function(player, action, payload)
    if type(action) ~= "string" or #action > 32 or type(payload) ~= "table" then
        return
    end

    local ok, message = AdminService:Execute(player, action, payload, function(target, textValue)
        if target then
            notice(target, textValue, true)
        else
            remotes.AccountEvent:FireAllClients("Notice", {
                Message = textValue,
                Success = true
            })
        end
    end)

    notice(player, message, ok)
    if ok then
        safeSync(player)
    end

    sendAdminPlayers()
end)

game:BindToClose(function()
    DataService:Shutdown()
end)

task.spawn(function()
    while true do
        task.wait(45)

        for _, player in ipairs(Players:GetPlayers()) do
            QuestService:Initialize(player)
        end

        sendAdminPlayers()
    end
end)
