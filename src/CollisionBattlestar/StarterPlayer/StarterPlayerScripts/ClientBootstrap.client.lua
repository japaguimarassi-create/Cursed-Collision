--!strict

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function showBoot(message: string)
    local old = playerGui:FindFirstChild("CollisionBattlestarBoot")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CollisionBattlestarBoot"
    gui.DisplayOrder = 100
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(8, 11, 17)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 44)
    title.Position = UDim2.new(0, 20, 0.45, -22)
    title.BackgroundTransparency = 1
    title.Text = "COLLISION BATTLESTAR"
    title.TextColor3 = Color3.fromRGB(240, 242, 248)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 26
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -40, 0, 32)
    status.Position = UDim2.new(0, 20, 0.45, 28)
    status.BackgroundTransparency = 1
    status.Text = message
    status.TextColor3 = Color3.fromRGB(180, 190, 210)
    status.Font = Enum.Font.Gotham
    status.TextSize = 15
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.Parent = frame

    return gui, status
end

local bootGui, bootStatus = showBoot("INITIALIZING...")

local ClientBootstrap = require(script.Parent.ClientRemotes)

local remotes = nil
for attempt = 1, 15 do
    bootStatus.Text = ("CONNECTING TO SERVER... %d/15"):format(attempt)
    local ok, result = pcall(ClientBootstrap.WaitForRemotes)
    if ok and result then
        remotes = result
        break
    end
    task.wait(1)
end

if not remotes then
    bootStatus.Text = "SERVER RUNTIME DID NOT START"
    return
end

local hudModuleOk, HUD = pcall(function()
    return require(script.Parent.HUD.Root)
end)

if not hudModuleOk then
    bootStatus.Text = "HUD MODULE FAILED TO LOAD"
    warn("Collision Battlestar HUD load failed:", HUD)
    return
end

local hudOk, hud = pcall(function()
    return HUD.new(remotes)
end)

if not hudOk then
    bootStatus.Text = "HUD INITIALIZATION FAILED"
    warn("Collision Battlestar HUD init failed:", hud)
    return
end

bootGui:Destroy()

remotes.State.OnClientEvent:Connect(function(kind)
    if kind == "RuntimeReloadStarted" then
        hud:SetControlsEnabled(false)
    elseif kind == "RuntimeReloaded" then
        hud:SetControlsEnabled(true)
        remotes.State:FireServer({
            action = "RequestState",
        })
    end
end)

local function startOptional(modulePath: Instance, constructorName: string, ...)
    local ok, module = pcall(require, modulePath)
    if not ok then
        warn(("Collision Battlestar client module failed [%s]: %s"):format(constructorName, tostring(module)))
        return nil
    end

    local ctor = module[constructorName]
    if type(ctor) ~= "function" then
        warn(("Collision Battlestar client module has no constructor [%s]"):format(constructorName))
        return nil
    end

    local createdOk, instance = pcall(function()
        return ctor(...)
    end)
    if not createdOk then
        warn(("Collision Battlestar client module init failed [%s]: %s"):format(constructorName, tostring(instance)))
        return nil
    end

    return instance
end

local input = startOptional(script.Parent.Input.Service, "new", remotes, hud)
local combatFX = startOptional(script.Parent.CombatFX.Service, "new", remotes)
local camera = startOptional(script.Parent.Camera.Service, "new")
local socialInvite = startOptional(script.Parent.SocialInvite.Service, "new")
if not socialInvite then
    socialInvite = {
        Prompt = function()
            return false, "invite_unavailable"
        end,
    }
end

if camera then
    pcall(function()
        camera:Start()
    end)
end

if combatFX then
    pcall(function()
        combatFX:Start()
    end)
end

if input then
    pcall(function()
        input:Start()
    end)
end

if socialInvite then
    pcall(function()
        socialInvite:Start()
    end)
end

local advancedOk, AdvancedPanels = pcall(function()
    return require(script.Parent.HUD.AdvancedPanels)
end)

if advancedOk then
    local panelsOk, panels = pcall(function()
        return AdvancedPanels.new(hud, remotes, socialInvite)
    end)

    if not panelsOk then
        warn("Collision Battlestar advanced HUD failed:", panels)
    end
else
    warn("Collision Battlestar advanced HUD module failed:", AdvancedPanels)
end
