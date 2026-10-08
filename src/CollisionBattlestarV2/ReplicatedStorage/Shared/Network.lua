--!strict

local Network = {}

Network.Remotes = {
    Combat = "Combat",
    State = "State",
    Shop = "Shop",
    Echo = "Echo",
    PvP = "PvP",
}

function Network.ensure()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local folder = ReplicatedStorage:FindFirstChild("CBS2_Remotes")

    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CBS2_Remotes"
        folder.Parent = ReplicatedStorage
    end

    local remotes = {}
    for _, name in pairs(Network.Remotes) do
        local remote = folder:FindFirstChild(name)
        if not remote then
            remote = Instance.new("RemoteEvent")
            remote.Name = name
            remote.Parent = folder
        end
        if not remote:IsA("RemoteEvent") then
            remote:Destroy()
            remote = Instance.new("RemoteEvent")
            remote.Name = name
            remote.Parent = folder
        end
        remotes[name] = remote
    end

    return remotes
end

return Network
