--!strict

local Players = game:GetService("Players")
local VisualProfile = require(script.Parent:WaitForChild("VisualProfile"))

local Resolver = {}
Resolver.__index = Resolver

function Resolver.new()
    return setmetatable({cache = {}}, Resolver)
end

function Resolver:Resolve(friendUserId: number, classId: string)
    local cached = self.cache[friendUserId]
    if cached and os.clock() - cached.at < 300 then
        return cached.model:Clone(), cached.source
    end

    local ok, model = pcall(function()
        return Players:CreateHumanoidModelFromUserIdAsync(friendUserId)
    end)
    if ok and model then
        if model:IsA("Model") then
            self.cache[friendUserId] = {at = os.clock(), model = model:Clone()}
            return model, "avatar"
        end
        model:Destroy()
    end

    return nil, VisualProfile.fallback(classId, friendUserId)
end

function Resolver:Clear()
    for userId, value in pairs(self.cache) do
        if value.model then
            value.model:Destroy()
        end
        self.cache[userId] = nil
    end
end

return Resolver
