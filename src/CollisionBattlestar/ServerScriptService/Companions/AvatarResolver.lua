--!strict

local Players = game:GetService("Players")

local AvatarResolver = {}

function AvatarResolver.Resolve(userId: number)
    local success, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserIdAsync(userId)
    end)

    if not success or not description then
        return nil
    end

    local modelSuccess, model = pcall(function()
        return Players:CreateHumanoidModelFromDescriptionAsync(
            description,
            Enum.HumanoidRigType.R15
        )
    end)

    if not modelSuccess or not model then
        description:Destroy()
        return nil
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or not root:IsA("BasePart") then
        model:Destroy()
        description:Destroy()
        return nil
    end

    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.NameDisplayDistance = 0
    root.Anchored = false

    description:Destroy()

    return model
end

return AvatarResolver
