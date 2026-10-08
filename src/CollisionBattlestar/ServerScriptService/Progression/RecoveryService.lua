--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = require(ReplicatedStorage.Shared.ProgressionRules)

local RecoveryService = {}
RecoveryService.__index = RecoveryService

function RecoveryService.new(playerState)
    return setmetatable({
        playerState = playerState,
        running = false,
    }, RecoveryService)
end

function RecoveryService:Start()
    if self.running then
        return
    end

    self.running = true

    task.spawn(function()
        while self.running do
            for _, player in ipairs(Players:GetPlayers()) do
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
                    local bonus = Rules.recoveryBonus(
                        self.playerState:GetUpgradeLevel(player, "Recovery")
                    )

                    if bonus > 0 then
                        humanoid.Health = math.min(
                            humanoid.MaxHealth,
                            humanoid.Health + bonus
                        )
                    end
                end
            end

            task.wait(1)
        end
    end)
end

function RecoveryService:Stop()
    self.running = false
end

return RecoveryService
