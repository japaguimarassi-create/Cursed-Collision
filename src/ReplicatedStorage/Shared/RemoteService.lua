local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = {}

local function ensure(parent, className, name)
    local existing = parent:FindFirstChild(name)
    if existing and existing.ClassName == className then
        return existing
    end
    if existing then
        existing:Destroy()
    end
    local object = Instance.new(className)
    object.Name = name
    object.Parent = parent
    return object
end

function RemoteService:Get()
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "Remotes"
        folder.Parent = ReplicatedStorage
    end

    return {
        CombatAction = ensure(folder, "RemoteEvent", "CombatAction"),
        ServerEvent = ensure(folder, "RemoteEvent", "ServerEvent"),
        CombatFX = ensure(folder, "RemoteEvent", "CombatFX"),
        ClashEvent = ensure(folder, "RemoteEvent", "ClashEvent"),
        Selection = ensure(folder, "RemoteEvent", "Selection"),
        AccountAction = ensure(folder, "RemoteEvent", "AccountAction"),
        AccountEvent = ensure(folder, "RemoteEvent", "AccountEvent"),
        AdminAction = ensure(folder, "RemoteEvent", "AdminAction"),
        AbilityRemote = ensure(folder, "RemoteEvent", "AbilityRemote"),
        MovementRemote = ensure(folder, "RemoteEvent", "MovementRemote"),
        StateRemote = ensure(folder, "RemoteEvent", "StateRemote"),
        UltimateAction = ensure(folder, "RemoteEvent", "UltimateAction"),
        UltimateEvent = ensure(folder, "RemoteEvent", "UltimateEvent"),
        EmoteAction = ensure(folder, "RemoteEvent", "EmoteAction"),
        EmoteEvent = ensure(folder, "RemoteEvent", "EmoteEvent"),
        GamePassAction = ensure(folder, "RemoteEvent", "GamePassAction"),
        GamePassEvent = ensure(folder, "RemoteEvent", "GamePassEvent")
    }
end

return RemoteService
