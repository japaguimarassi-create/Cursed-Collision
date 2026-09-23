--!strict

local Players = game:GetService("Players")
local StateManager = require(script.Parent.StateManager)

local RagdollService = {}

type Active = {
    token: number,
    duration: number
}

local active: {[Player]: Active} = {}

function RagdollService:Apply(player: Player, duration: number, reason: string?): boolean
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not character or not humanoid or humanoid.Health <= 0 then
        return false
    end

    local state = StateManager:Get(player)
    if not state then
        return false
    end

    local token = (active[player] and active[player].token or 0) + 1
    active[player] = {
        token = token,
        duration = math.max(0.08, duration)
    }

    StateManager:BeginRagdoll(player, duration, os.clock())

    character:SetAttribute("RagdollReason", reason or "Impact")
    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    task.delay(math.max(0.08, duration), function()
        local current = active[player]
        if not current or current.token ~= token or not player.Parent then
            return
        end

        active[player] = nil

        local latestCharacter = player.Character
        local latestHumanoid = latestCharacter and latestCharacter:FindFirstChildOfClass("Humanoid")

        if latestHumanoid then
            latestHumanoid.PlatformStand = false
            latestHumanoid.AutoRotate = true

            if latestHumanoid.Health > 0 then
                latestHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end

        if latestCharacter then
            latestCharacter:SetAttribute("RagdollReason", nil)
        end

        StateManager:ClearStunWhenReady(player, os.clock())
    end)

    return true
end

function RagdollService:Cancel(player: Player)
    local current = active[player]
    if not current then
        return
    end

    current.token += 1
    active[player] = nil

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
    end

    StateManager:ClearStunWhenReady(player, os.clock())
end

Players.PlayerRemoving:Connect(function(player)
    active[player] = nil
end)

return RagdollService
