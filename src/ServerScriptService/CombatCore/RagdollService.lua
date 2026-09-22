--!strict

local RagdollService = {}

local active = setmetatable({}, {__mode = "k"})

function RagdollService:Apply(character: Model, duration: number, reason: string?)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    local token = (active[character] or 0) + 1
    active[character] = token

    character:SetAttribute("Ragdolled", true)
    character:SetAttribute("RagdollReason", reason or "Impact")
    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
    humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)

    task.delay(math.max(0.08, duration), function()
        if active[character] ~= token or not character.Parent then
            return
        end

        active[character] = nil
        character:SetAttribute("Ragdolled", false)
        character:SetAttribute("RagdollReason", nil)
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true

        if humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)

    return true
end

function RagdollService:Cancel(character: Model)
    if active[character] then
        active[character] += 1
    end
end

return RagdollService
