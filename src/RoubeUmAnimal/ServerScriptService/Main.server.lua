local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = script.Parent:WaitForChild("Services")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local WorldBuilder = require(Services:WaitForChild("WorldBuilder"))
local ProfileService = require(Services:WaitForChild("ProfileService"))
local AnimalService = require(Services:WaitForChild("AnimalService"))
local TrainingService = require(Services:WaitForChild("TrainingService"))
local ShopService = require(Services:WaitForChild("ShopService"))
local PassService = require(Services:WaitForChild("PassService"))
local GuardianService = require(Services:WaitForChild("GuardianService"))

local function folder(parent, name)
    local object = parent:FindFirstChild(name)

    if object then
        assert(object:IsA("Folder"), name .. " precisa ser uma Folder")
        return object
    end

    object = Instance.new("Folder")
    object.Name = name
    object.Parent = parent
    return object
end

local function remote(parent, name)
    local object = parent:FindFirstChild(name)

    if object then
        assert(object:IsA("RemoteEvent"), name .. " precisa ser um RemoteEvent")
        return object
    end

    object = Instance.new("RemoteEvent")
    object.Name = name
    object.Parent = parent
    return object
end

local remotes = folder(ReplicatedStorage, "RoubeAnimalRemotes")
local notifyRemote = remote(remotes, "Notify")
local upgradeRemote = remote(remotes, "RequestUpgrade")
local passRequestRemote = remote(remotes, "RequestGamepass")
local passPromptRemote = remote(remotes, "PromptGamepass")

local function notify(player, message, messageType)
    if not player or player.Parent ~= Players then
        return
    end

    pcall(function()
        notifyRemote:FireClient(player, tostring(message), tostring(messageType or "Info"))
    end)
end

WorldBuilder.Build()

AnimalService.Start(
    ProfileService,
    WorldBuilder,
    PassService,
    remotes,
    notify
)

ShopService.Start(
    ProfileService,
    AnimalService,
    upgradeRemote,
    notify
)

PassService.Start(
    passRequestRemote,
    passPromptRemote,
    notify,
    AnimalService.ApplyMovement
)

TrainingService.Start(
    ProfileService,
    WorldBuilder,
    AnimalService,
    notify
)

GuardianService.Start(
    WorldBuilder,
    AnimalService,
    notify
)

ProfileService.StartAutosave()

local deathConnections = {}

local function characterAdded(player, character)
    local humanoid = character:WaitForChild("Humanoid", 15)

    if not humanoid then
        return
    end

    if deathConnections[player] then
        deathConnections[player]:Disconnect()
        deathConnections[player] = nil
    end

    deathConnections[player] = humanoid.Died:Connect(function()
        AnimalService.Lose(player, "Você foi derrotado e perdeu o animal carregado.")
    end)

    task.spawn(function()
        local deadline = os.clock() + 35

        while player.Parent == Players
            and not ProfileService.IsLoaded(player)
            and os.clock() < deadline do
            task.wait(0.25)
        end

        if player.Parent ~= Players or not ProfileService.IsLoaded(player) then
            return
        end

        if not WorldBuilder.GetOwnedBase(player) then
            WorldBuilder.AssignBase(player)
        end

        WorldBuilder.TeleportToBase(player)
        task.wait(0.1)
        AnimalService.ApplyMovement(player)
    end)
end

local function playerAdded(player)
    player:SetAttribute("DataLoaded", false)
    player:SetAttribute("CarryingAnimal", false)

    player.CharacterAdded:Connect(function(character)
        task.spawn(characterAdded, player, character)
    end)

    if player.Character then
        task.spawn(characterAdded, player, player.Character)
    end

    task.spawn(function()
        local success = ProfileService.Load(player)

        if not success then
            if player.Parent == Players then
                player:Kick("Não foi possível carregar seus dados com segurança. Entre novamente.")
            end
            return
        end

        if player.Parent ~= Players then
            ProfileService.Save(player, true)
            ProfileService.Remove(player)
            return
        end

        local base = WorldBuilder.AssignBase(player)

        if not base then
            notify(player, "Todos os currais estão ocupados. Este servidor está cheio.", "Error")
            player:Kick("Todos os currais estão ocupados. Entre em outro servidor.")
            return
        end

        task.spawn(function()
            local successPasses, passError = pcall(PassService.Load, player)

            if not successPasses then
                warn("RoubeUmAnimal: falha ao carregar gamepasses: " .. tostring(passError))
            end
        end)

        notify(player, "Bem-vindo! Treine, roube animais e volte ao seu curral.", "Success")
    end)
end

Players.PlayerAdded:Connect(playerAdded)

Players.PlayerRemoving:Connect(function(player)
    ProfileService.MarkLeaving(player)
    AnimalService.RemovePlayer(player)
    TrainingService.RemovePlayer(player)
    ShopService.RemovePlayer(player)
    PassService.RemovePlayer(player)
    WorldBuilder.ReleaseBase(player)

    if deathConnections[player] then
        deathConnections[player]:Disconnect()
        deathConnections[player] = nil
    end

    ProfileService.Save(player, true)
    ProfileService.Remove(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(playerAdded, player)
end

game:BindToClose(function()
    local pending = 0

    for _, player in ipairs(Players:GetPlayers()) do
        pending += 1

        task.spawn(function()
            ProfileService.Save(player, true)
            pending -= 1
        end)
    end

    local deadline = os.clock() + 25

    while pending > 0 and os.clock() < deadline do
        task.wait(0.1)
    end
end)

print(Config.GameName .. " iniciado com sucesso.")
