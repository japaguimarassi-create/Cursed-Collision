--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Service = {}
local Config
local DataService
local State: RemoteEvent
local passes = {}
local products = {}

local function setPassAttribute(player: Player, key: string, owned: boolean)
    player:SetAttribute("Pass_" .. key, owned)
end

local function refreshPass(player: Player, pass)
    if pass.Id <= 0 then
        setPassAttribute(player, pass.Key, false)
        return
    end

    local success, owned = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
    end)

    setPassAttribute(player, "Pass_" .. pass.Key, success and owned == true)
end

local function promptPass(player: Player, key: string)
    local pass = passes[key]
    if not pass or pass.Id <= 0 then
        State:FireClient(player, "ShopMessage", "PASS NOT CONFIGURED")
        return
    end

    if player:GetAttribute("Pass_" .. key) == true then
        State:FireClient(player, "ShopMessage", "PASS ALREADY OWNED")
        return
    end

    MarketplaceService:PromptGamePassPurchase(player, pass.Id)
end

function Service:Init(config, dataService)
    Config = config
    DataService = dataService

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    State = remotes:WaitForChild("State") :: RemoteEvent

    for _, pass in ipairs(Config.GamePasses) do
        passes[pass.Key] = pass
    end

    for _, product in ipairs(Config.Shop.DeveloperProducts) do
        if product.Id and product.Id > 0 then
            products[product.Id] = product
        end
    end

    Players.PlayerAdded:Connect(function(player)
        for _, pass in ipairs(Config.GamePasses) do
            task.spawn(refreshPass, player, pass)
        end
    end)

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
        if not purchased then
            return
        end

        for _, pass in ipairs(Config.GamePasses) do
            if pass.Id == gamePassId then
                task.spawn(refreshPass, player, pass)
                break
            end
        end
    end)

    MarketplaceService.ProcessReceipt = function(receiptInfo)
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if not player then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        local product = products[receiptInfo.ProductId]
        if not product then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        if not DataService:GrantDeveloperProduct(player, product, tostring(receiptInfo.PurchaseId)) then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        if product.Kind == "SpeedMultiplier" and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local stats = DataService:GetCombatStats(player)
            if humanoid and stats then
                humanoid.WalkSpeed = stats.WalkSpeed
            end
        end

        DataService:Save(player)
        State:FireClient(player, "ProductGranted", product.Key, product.Kind)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    for _, player in ipairs(Players:GetPlayers()) do
        for _, pass in ipairs(Config.GamePasses) do
            task.spawn(refreshPass, player, pass)
        end
    end
end

function Service:Prompt(player: Player, key: string)
    promptPass(player, key)
end

return Service
