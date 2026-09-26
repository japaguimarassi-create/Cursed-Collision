--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Service = {}

local Config
local State: RemoteEvent

local passes = {}

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

    setPassAttribute(player, pass.Key, success and owned == true)
end

local function prompt(player: Player, key: string)
    local pass = passes[key]
    if not pass or pass.Id <= 0 then
        State:FireClient(player, "ShopMessage", "PASS AINDA NÃO CONFIGURADO")
        return
    end

    local owned = player:GetAttribute("Pass_" .. key) == true
    if owned then
        State:FireClient(player, "ShopMessage", "VOCÊ JÁ POSSUI ESTE PASS")
        return
    end

    MarketplaceService:PromptGamePassPurchase(player, pass.Id)
end

function Service:Init(config)
    Config = config

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    State = remotes:WaitForChild("State") :: RemoteEvent

    for _, pass in ipairs(Config.GamePasses) do
        passes[pass.Key] = pass
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

    for _, player in ipairs(Players:GetPlayers()) do
        for _, pass in ipairs(Config.GamePasses) do
            task.spawn(refreshPass, player, pass)
        end
    end
end

function Service:Prompt(player: Player, key: string)
    prompt(player, key)
end

return Service
