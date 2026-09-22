local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local DataService = require(ReplicatedStorage.Economy.DataService)
local ShopService = require(ReplicatedStorage.Economy.ShopService)
local QuestService = require(ReplicatedStorage.Economy.QuestService)
local ShopDefinitions = require(ReplicatedStorage.Economy.ShopDefinitions)
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
    if equipped and equipped ~= "" and data.OwnedSkins[equipped] then
        if not CosmeticService:ApplySkin(player, equipped) then
            data.EquippedSkin = ""
            CosmeticService:ClearSkin(player)
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
    player:SetAttribute("EquippedEmote", DataService:Get(player).EquippedEmote or "emote_001")
    player:SetAttribute("EquippedSkin", DataService:Get(player).EquippedSkin or "")

    if not loaded then
        notice(player, "Persistent data is temporarily unavailable. Purchases are disabled until the profile loads.", false)
    end

    player.CharacterAdded:Connect(function()
        task.delay(0.4, function()
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

    if action == "SyncOwner" then
        if AdminService:IsOwner(player) then
            sendAdminPlayers()
        end
        return
    end

    if action == "Buy" then
        local category = type(payload.category) == "string" and payload.category or ""
        local itemId = type(payload.id) == "string" and payload.id or ""
        if #category > 16 or #itemId > 96 then
            return
        end

        local ok, reason = ShopService:Buy(player, category, itemId)
        if ok then
            notice(player, reason == "ALREADY_OWNED" and "You already own this item." or "Purchase complete.", true)
            safeSync(player)
        else
            local messages = {
                DATA_NOT_READY = "Your profile is not ready yet.",
                UNKNOWN_ITEM = "That item does not exist.",
                NOT_ENOUGH_CREDITS = "Not enough Credits."
            }
            notice(player, messages[reason] or "Purchase failed.", false)
        end
        return
    end

    if action == "Equip" then
        local category = type(payload.category) == "string" and payload.category or ""
        local itemId = type(payload.id) == "string" and payload.id or ""
        if #category > 16 or #itemId > 96 then
            return
        end

        local ok, reason = ShopService:Equip(player, category, itemId)
        if ok then
            notice(player, "Equipped.", true)
            safeSync(player)
        else
            local messages = {
                DATA_NOT_READY = "Your profile is not ready yet.",
                UNKNOWN_ITEM = "That item does not exist.",
                NOT_OWNED = "You do not own that item.",
                WRONG_CHARACTER = "This skin belongs to another character.",
                SKIN_APPLY_FAILED = "Could not apply that skin."
            }
            notice(player, messages[reason] or "Equip failed.", false)
        end
        return
    end

    if action == "PlayEmote" then
        local id = type(payload.id) == "string" and payload.id or ""
        local data = DataService:Get(player)
        local emote = ShopDefinitions.Emotes[id]
        if not data or not emote or not data.OwnedEmotes[id] then
            notice(player, "Emote is not owned.", false)
            return
        end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            return
        end

        if player:GetAttribute("InClash") or player:GetAttribute("AwakeningActive") then
            notice(player, "You cannot emote during combat lock.", false)
            return
        end

        data.EquippedEmote = id
        player:SetAttribute("EquippedEmote", id)
        DataService:MarkDirty(player)

        remotes.AccountEvent:FireClient(player, "PlayEmote", {
            Id = id,
            Name = emote.Name,
            Animation = emote.Animation,
            AnimationId = emote.AnimationId or 0,
            Accent = emote.Accent,
            Rarity = emote.Rarity
        })
        QuestService:Record(player, "Emote", 1, player:GetAttribute("CharacterId"))
        return
    end
end)

remotes.AdminAction.OnServerEvent:Connect(function(player, action, payload)
    if type(action) ~= "string" or #action > 32 or type(payload) ~= "table" then
        return
    end

    local ok, message = AdminService:Execute(player, action, payload, function(target, text)
        if target then
            notice(target, text, true)
        else
            remotes.AccountEvent:FireAllClients("Notice", {
                Message = text,
                Success = true
            })
        end
    end)

    if ok then
        notice(player, message, true)
    else
        notice(player, message, false)
    end

    if ok and player.Parent then
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

        for _, owner in ipairs(Players:GetPlayers()) do
            if AdminService:IsOwner(owner) then
                safeSync(owner)
                sendAdminPlayers()
            end
        end
    end
end)
