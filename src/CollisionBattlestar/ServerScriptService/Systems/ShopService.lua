--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Service = {}
local Config
local DataService
local MonetizationService
local State: RemoteEvent
local ShopRemote: RemoteEvent
local requestAt: {[Player]: number} = {}

local function costFor(base: number, growth: number, level: number): number
    return math.floor(base * growth ^ level)
end

local function priceMultiplier(player: Player): number
    return if player:GetAttribute("Pass_ShopDiscount") == true then 0.85 else 1
end

local function notify(player: Player, message: string)
    State:FireClient(player, "ShopMessage", message)
end

local function findSkin(key: string)
    for _, skin in ipairs(Config.Shop.Skins) do
        if skin.Key == key then
            return skin
        end
    end
    return nil
end

local function findCompanion(key: string)
    for _, companion in ipairs(Config.Shop.Companions) do
        if companion.Key == key then
            return companion
        end
    end
    return nil
end

local function applySkin(player: Player, skinKey: string)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end

    local description
    if skinKey == "Default" then
        local ok, result = pcall(function()
            return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
        end)
        if not ok or not result then
            return false
        end
        description = result
    else
        local skin = findSkin(skinKey)
        if not skin then
            return false
        end

        local ok, result = pcall(function()
            return humanoid:GetAppliedDescription()
        end)
        description = if ok and result then result else Instance.new("HumanoidDescription")
        description.Shirt = skin.Shirt or 0
        description.Pants = skin.Pants or 0
        description.HairAccessory = if skin.Hair and skin.Hair > 0 then tostring(skin.Hair) else ""
        description.HatAccessory = if skin.Horns and skin.Horns > 0 then tostring(skin.Horns) else ""
        description.HeadColor = skin.Color
        description.TorsoColor = skin.Color
        description.LeftArmColor = skin.Color
        description.RightArmColor = skin.Color
        description.LeftLegColor = skin.Color
        description.RightLegColor = skin.Color
        description.BodyTypeScale = 0.25
        description.ProportionScale = 0.35
        description.WidthScale = 0.9
        description.DepthScale = 0.86
        description.HeightScale = 1.02
        description.HeadScale = 0.98
    end

    return pcall(function()
        humanoid:ApplyDescriptionResetAsync(description)
    end)
end

local function buySkin(player: Player, key: string)
    local skin = findSkin(key)
    if not skin then
        notify(player, "SKIN INVALID")
        return
    end

    local cost = math.floor((tonumber(skin.Cost) or 0) * priceMultiplier(player))
    local success, reason = DataService:BuySkin(player, key, cost)
    if not success then
        notify(player, reason == "OWNED" and "SKIN ALREADY OWNED" or "INSUFFICIENT CREDITS")
        return
    end

    applySkin(player, key)
    DataService:Save(player)
    notify(player, ("%s UNLOCKED"):format(skin.DisplayName))
end

local function equipSkin(player: Player, key: string)
    if key ~= "Default" and not findSkin(key) then
        notify(player, "SKIN INVALID")
        return
    end

    if not DataService:EquipSkin(player, key) then
        notify(player, "SKIN LOCKED")
        return
    end

    applySkin(player, key)
    DataService:Save(player)
    notify(player, "SKIN EQUIPPED")
end

local function buyCompanion(player: Player, key: string)
    local definition = findCompanion(key)
    if not definition then
        notify(player, "COMPANION INVALID")
        return
    end

    local current = player:GetAttribute("Companion_" .. key) or 0
    if current >= 2 then
        notify(player, "COMPANION MAXED")
        return
    end

    local cost = math.floor(definition.Cost * priceMultiplier(player))
    if not DataService:SpendCredits(player, cost) then
        notify(player, "INSUFFICIENT CREDITS")
        return
    end

    if not DataService:AddCompanion(player, key) then
        DataService:AddCredits(player, cost, false)
        notify(player, "PURCHASE CANCELLED")
        return
    end

    DataService:Save(player)
    notify(player, ("%s UNLOCKED"):format(definition.DisplayName))
end

local function upgrade(player: Player, kind: string)
    local profile = DataService:Get(player)
    local definition = Config.Shop[kind]
    if not profile or not definition then
        return
    end

    local levelName = kind .. "Level"
    local level = profile[levelName]
    if type(level) ~= "number" or level >= definition.MaxLevel then
        notify(player, "MAX LEVEL")
        return
    end

    local cost = math.floor(costFor(definition.BaseCost, definition.Growth, level) * priceMultiplier(player))
    if not DataService:SpendCredits(player, cost) then
        notify(player, "INSUFFICIENT CREDITS")
        return
    end

    if not DataService:IncreaseLevel(player, kind) then
        DataService:AddCredits(player, cost, false)
        notify(player, "UPGRADE CANCELLED")
        return
    end

    if kind == "Speed" and player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        local stats = DataService:GetCombatStats(player)
        if humanoid and stats then
            humanoid.WalkSpeed = stats.WalkSpeed
        end
    end

    DataService:Save(player)
    notify(player, ("%s +1"):format(kind:upper()))
end

local function handleRequest(player: Player, action: string, key: string?)
    local now = os.clock()
    if now - (requestAt[player] or 0) < 0.25 then
        return
    end
    requestAt[player] = now

    if action == "PurchaseSkin" and key then
        buySkin(player, key)
    elseif action == "EquipSkin" and key then
        equipSkin(player, key)
    elseif action == "PurchaseCompanion" and key then
        buyCompanion(player, key)
    elseif action == "Upgrade" and key and (key == "Damage" or key == "Defense" or key == "Speed") then
        upgrade(player, key)
    elseif action == "PromptPass" and key then
        MonetizationService:Prompt(player, key)
    end
end

function Service:Init(config, dataService, monetizationService)
    Config = config
    DataService = dataService
    MonetizationService = monetizationService

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    State = remotes:WaitForChild("State") :: RemoteEvent

    local existing = remotes:FindFirstChild("Shop")
    if existing then
        existing:Destroy()
    end

    ShopRemote = Instance.new("RemoteEvent")
    ShopRemote.Name = "Shop"
    ShopRemote.Parent = remotes

    ShopRemote.OnServerEvent:Connect(function(player, action, key)
        if type(action) ~= "string" or #action > 24 then
            return
        end
        handleRequest(player, action, if type(key) == "string" and #key <= 40 then key else nil)
    end)

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.delay(0.6, function()
                if not player.Parent then
                    return
                end
                local skin = player:GetAttribute("EquippedSkin") or "Default"
                if skin ~= "Default" then
                    applySkin(player, skin)
                end
            end)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        requestAt[player] = nil
    end)
end

return Service
