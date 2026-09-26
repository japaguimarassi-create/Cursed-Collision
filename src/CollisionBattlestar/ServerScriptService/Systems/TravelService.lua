--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Service = {}

local ZoneService
local State: RemoteEvent
local Travel: RemoteEvent

local function teleport(player: Player, zone: string)
    if player:GetAttribute("DataReady") ~= true then
        return
    end

    local character = player.Character
    if not character then
        return
    end

    local position
    if zone == "PvP" then
        position = ZoneService:GetPvPSpawn()
    else
        zone = "PvE"
        position = ZoneService:GetMainSpawn()
    end

    player:SetAttribute("Zone", zone)
    player:SetAttribute("ServerTeleportAt", os.clock())

    character:PivotTo(CFrame.new(position))
    State:FireClient(player, "Zone", zone)
end

function Service:Init(config, zoneService)
    ZoneService = zoneService

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    State = remotes:WaitForChild("State") :: RemoteEvent
    Travel = remotes:WaitForChild("Travel") :: RemoteEvent

    Players.PlayerAdded:Connect(function(player)
        player:SetAttribute("Zone", "PvE")

        player.CharacterAdded:Connect(function(character)
            task.delay(0.3, function()
                if character.Parent and player:GetAttribute("DataReady") == true then
                    local zone = player:GetAttribute("Zone") or "PvE"
                    if zone == "PvP" then
                        player:SetAttribute("ServerTeleportAt", os.clock())
                        character:PivotTo(CFrame.new(ZoneService:GetPvPSpawn()))
                    end
                    State:FireClient(player, "Zone", zone)
                end
            end)
        end)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("Zone") == nil then
            player:SetAttribute("Zone", "PvE")
        end
    end

    Travel.OnServerEvent:Connect(function(player, destination: string)
        if destination ~= "PvP" and destination ~= "PvE" then
            return
        end

        local lastTravel = player:GetAttribute("LastTravelAt") or 0
        if os.clock() - lastTravel < 1 then
            return
        end

        player:SetAttribute("LastTravelAt", os.clock())

        local current = player:GetAttribute("Zone") or "PvE"
        if destination == current then
            return
        end

        teleport(player, destination)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        player:SetAttribute("Zone", player:GetAttribute("Zone") or "PvE")
    end
end

return Service
