--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Service = {}

local Config
local DataService
local MonetizationService
local State: RemoteEvent
local shopFolder: Folder

local function costFor(base: number, growth: number, level: number): number
    return math.floor(base * growth ^ level)
end

local function priceMultiplier(player: Player): number
    return if player:GetAttribute("Pass_ShopDiscount") == true then 0.85 else 1
end

local function notify(player: Player, message: string)
    State:FireClient(player, "ShopMessage", message)
end

local function createStation(name: string, position: Vector3, objectText: string, actionText: string, callback)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = Vector3.new(9, 3, 9)
    part.Position = position
    part.Anchored = true
    part.Material = Enum.Material.Metal
    part.Color = Config.UI.Surface2
    part.Parent = shopFolder

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = part

    prompt.Triggered:Connect(callback)
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
        notify(player, "NÍVEL MÁXIMO")
        return
    end

    local cost = math.floor(costFor(definition.BaseCost, definition.Growth, level) * priceMultiplier(player))
    if not DataService:SpendCredits(player, cost) then
        notify(player, "DINHEIRO INSUFICIENTE")
        return
    end

    DataService:IncreaseLevel(player, kind)

    if kind == "Speed" and player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        local stats = DataService:GetCombatStats(player)
        if humanoid and stats then
            humanoid.WalkSpeed = stats.WalkSpeed
        end
    end

    notify(player, ("%s +1  •  -%d C"):format(kind:upper(), cost))
end

local function companion(player: Player, index: number)
    local definition = Config.Shop.Companions[index]
    if not definition then
        return
    end

    local key = "Companion_" .. definition.Key
    local current = player:GetAttribute(key) or 0
    if current >= 2 then
        notify(player, "LIMITE DESTE NPC ATINGIDO")
        return
    end

    local cost = math.floor(definition.Cost * priceMultiplier(player))
    if not DataService:SpendCredits(player, cost) then
        notify(player, "DINHEIRO INSUFICIENTE")
        return
    end

    if DataService:AddCompanion(player, definition.Key) then
        notify(player, definition.DisplayName .. " ADQUIRIDO")
    else
        DataService:AddCredits(player, cost)
        notify(player, "COMPRA CANCELADA")
    end
end

function Service:Init(config, dataService, monetizationService)
    Config = config
    DataService = dataService
    MonetizationService = monetizationService

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    State = remotes:WaitForChild("State") :: RemoteEvent

    local old = workspace:FindFirstChild("Shop")
    if old then
        old:Destroy()
    end

    shopFolder = Instance.new("Folder")
    shopFolder.Name = "Shop"
    shopFolder.Parent = workspace

    local hub = Instance.new("Part")
    hub.Name = "ShopHub"
    hub.Size = Vector3.new(80, 2, 56)
    hub.Position = Vector3.new(0, 1, 120)
    hub.Anchored = true
    hub.Material = Enum.Material.Concrete
    hub.Color = Color3.fromRGB(44, 48, 58)
    hub.Parent = shopFolder

    createStation("Damage", Vector3.new(-24, 3, 110), "DANO", "UPGRADE", function(player)
        upgrade(player, "Damage")
    end)

    createStation("Defense", Vector3.new(0, 3, 110), "DEFESA", "UPGRADE", function(player)
        upgrade(player, "Defense")
    end)

    createStation("Speed", Vector3.new(24, 3, 110), "VELOCIDADE", "UPGRADE", function(player)
        upgrade(player, "Speed")
    end)

    for index, data in ipairs(Config.Shop.Companions) do
        createStation(
            "Companion_" .. data.Key,
            Vector3.new(-45 + (index - 1) * 30, 3, 145),
            data.DisplayName,
            ("COMPRAR %d C"):format(data.Cost),
            function(player)
                companion(player, index)
            end
        )
    end

    for index, pass in ipairs(Config.GamePasses) do
        createStation(
            "Pass_" .. pass.Key,
            Vector3.new(-75 + ((index - 1) % 3) * 75, 3, 185 + math.floor((index - 1) / 3) * 24),
            pass.Name,
            "COMPRAR",
            function(player)
                MonetizationService:Prompt(player, pass.Key)
            end
        )
    end
end

return Service
