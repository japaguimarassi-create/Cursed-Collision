--!strict

local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Registry=require(script.Parent:WaitForChild("Core"):WaitForChild("ServiceRegistry"))
local RuntimeState=require(script.Parent:WaitForChild("Core"):WaitForChild("RuntimeState"))
local Persistence=require(script.Parent:WaitForChild("Persistence"):WaitForChild("Service"))
local PlayerState=require(script.Parent:WaitForChild("Core"):WaitForChild("PlayerState"))
local Security=require(script.Parent:WaitForChild("Security"):WaitForChild("Service"))
local World=require(script.Parent:WaitForChild("World"):WaitForChild("Service"))
local Enemies=require(script.Parent:WaitForChild("Enemies"):WaitForChild("Service"))
local Economy=require(script.Parent:WaitForChild("Economy"):WaitForChild("Service"))
local Friends=require(script.Parent:WaitForChild("Friends"):WaitForChild("Service"))
local Shop=require(script.Parent:WaitForChild("Shop"):WaitForChild("Service"))
local Companions=require(script.Parent:WaitForChild("Companions"):WaitForChild("Service"))
local Combat=require(script.Parent:WaitForChild("Combat"):WaitForChild("Service"))
local Waves=require(script.Parent:WaitForChild("Waves"):WaitForChild("Service"))
local TestLab=require(script.Parent:WaitForChild("Admin"):WaitForChild("TestLabService"))

local remotesFolder=ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder=Instance.new("Folder")
    remotesFolder.Name="Remotes"
    remotesFolder.Parent=ReplicatedStorage
end

local function ensureRemote(name:string):RemoteEvent
    local remote=remotesFolder:FindFirstChild(name)
    if remote and remote:IsA("RemoteEvent") then return remote end
    if remote then remote:Destroy() end
    local created=Instance.new("RemoteEvent")
    created.Name=name
    created.Parent=remotesFolder
    return created
end

local remotes={
    Combat=ensureRemote("Combat"),
    State=ensureRemote("State"),
    FX=ensureRemote("FX"),
    Commerce=ensureRemote("Commerce"),
    Companion=ensureRemote("Companion"),
    TestLab=ensureRemote("TestLab"),
}

local registry=Registry.new()
registry:Register("RuntimeState",RuntimeState.new())
registry:Register("Persistence",Persistence.new())
registry:Register("PlayerState",PlayerState.new())
registry:Register("Security",Security.new())
registry:Register("World",World.new())
registry:Register("Economy",Economy.new())
registry:Register("Enemies",Enemies.new())
registry:Register("Friends",Friends.new())
registry:Register("Shop",Shop.new())
registry:Register("Companions",Companions.new())
registry:Register("Combat",Combat.new())
registry:Register("Waves",Waves.new())
registry:Register("TestLab",TestLab.new())

registry:Get("World"):Init()
registry:Get("Persistence"):Init()
registry:Get("PlayerState"):Init(registry)
registry:Get("PlayerState"):Start()
registry:Get("Security"):Start()
registry:Get("Economy"):Init(registry,remotes)
registry:Get("Enemies"):Init(registry)
registry:Get("Friends"):Start()
registry:Get("Shop"):Init(registry,remotes)
registry:Get("Companions"):Init(registry,remotes)
registry:Get("Combat"):Init(registry,remotes)
registry:Get("Waves"):Init(registry,remotes)
registry:Get("TestLab"):Init(registry,remotes)
registry:Get("World"):Start()
registry:Get("Enemies"):Start()
registry:Get("Waves"):Start()
