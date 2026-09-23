--!strict

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local controllers = script.Parent.Controllers

local function safeRequire(name: string)
    local ok, result = pcall(function()
        return require(controllers:WaitForChild(name, 15))
    end)
    return if ok then result else nil
end

local HUDCore = safeRequire("HUDCore")
if not HUDCore then
    return
end

local okCore, core = pcall(function()
    return HUDCore.new()
end)

if not okCore or not core then
    return
end

local function safeStart(name: string, callback: (any) -> ())
    local module = safeRequire(name)
    if not module then
        return
    end
    task.spawn(function()
        pcall(function()
            callback(module)
        end)
    end)
end

local menus: any
local emotes: any

safeStart("HUDMenus", function(Module)
    menus = Module.new(core)
end)

safeStart("HUDCombatPanel", function(Module)
    Module.new(core)
end)

safeStart("HUDNavigation", function(Module)
    Module.new(core, function(section: string)
        if section == "Emotes" and emotes then
            emotes:Toggle()
            return
        end
        if menus then
            menus:Open(section)
        end
    end)
end)

safeStart("HUDEmoteWheel", function(Module)
    emotes = Module.new(core)
end)

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
    end
end)

if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
    GuiService.GuiNavigationEnabled = true
end
