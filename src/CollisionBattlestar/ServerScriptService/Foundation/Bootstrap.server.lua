--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(script.Parent:WaitForChild("Core"):WaitForChild("ServiceRegistry"))
local RuntimeState = require(script.Parent:WaitForChild("Core"):WaitForChild("RuntimeState"))
local PlayerState = require(script.Parent:WaitForChild("Core"):WaitForChild("PlayerState"))
local Security = require(script.Parent:WaitForChild("Security"):WaitForChild("Service"))
local World = require(script.Parent:WaitForChild("World"):WaitForChild("Service"))
local Enemies = require(script.Parent:WaitForChild("Enemies"):WaitForChild("Service"))
local Economy = require(script.Parent:WaitForChild("Economy"):WaitForChild("Service"))
local Combat = require(script.Parent:WaitForChild("Combat"):WaitForChild("Service"))
local Waves = require(script.Parent:WaitForChild("Waves"):WaitForChild("Service"))

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

for _, child in ipairs(remotesFolder:GetChildren()) do
    if child.Name ~= "Combat" and child.Name ~= "State" and child.Name ~= "FX" then
        child:Destroy()
    end
end

local function ensureRemote(name: string): RemoteEvent
    local remote = remotesFolder:FindFirstChild(name)
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    if remote then
        remote:Destroy()
    end
    local created = Instance.new("RemoteEvent")
    created.Name = name
    created.Parent = remotesFolder
    return created
end

local remotes = {
    Combat = ensureRemote("Combat"),
    State = ensureRemote("State"),
    FX = ensureRemote("FX"),
}

local registry = Registry.new()
registry:Register("RuntimeState", RuntimeState.new())
registry:Register("PlayerState", PlayerState.new())
registry:Register("Security", Security.new())
registry:Register("World", World.new())
registry:Register("Economy", Economy.new())
registry:Register("Enemies", Enemies.new())
registry:Register("Combat", Combat.new())
registry:Register("Waves", Waves.new())

registry:Get("World"):Init()
registry:Get("PlayerState"):Start()
registry:Get("Security"):Start()
registry:Get("Economy"):Init(registry, remotes)
registry:Get("Enemies"):Init(registry)
registry:Get("Combat"):Init(registry, remotes)
registry:Get("Waves"):Init(registry, remotes)
registry:Get("World"):Start()
registry:Get("Enemies"):Start()
registry:Get("Waves"):Start()