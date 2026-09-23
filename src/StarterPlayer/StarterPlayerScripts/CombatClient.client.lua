--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remotes then
    return
end

local combat = remotes:WaitForChild("CombatAction", 15)
local movement = remotes:WaitForChild("MovementRemote", 15)
if not combat or not movement then
    return
end

local function menuOpen(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_SettingsOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function fire(action: string, payload: any?)
    if menuOpen() then
        return
    end
    combat:FireServer(action, payload)
end

local function bind(name: string, action: string, keys: {Enum.KeyCode})
    ContextActionService:BindAction(name, function(_, state)
        if state == Enum.UserInputState.Begin then
            fire(action, action == "Dash" and "Forward" or nil)
        end
        return Enum.ContextActionResult.Pass
    end, false, table.unpack(keys))
end

bind("CC_M1", "M1", {Enum.KeyCode.ButtonR2})
bind("CC_Dash", "Dash", {Enum.KeyCode.Q, Enum.KeyCode.ButtonA})
bind("CC_Special", "Special", {Enum.KeyCode.E, Enum.KeyCode.ButtonX})
bind("CC_Skill1", "Skill1", {Enum.KeyCode.One, Enum.KeyCode.ButtonR1})
bind("CC_Skill2", "Skill2", {Enum.KeyCode.Two, Enum.KeyCode.ButtonY})
bind("CC_Skill3", "Skill3", {Enum.KeyCode.Three, Enum.KeyCode.DPadUp})
bind("CC_Skill4", "Skill4", {Enum.KeyCode.Four, Enum.KeyCode.DPadDown})
bind("CC_Ultimate", "Ultimate", {Enum.KeyCode.R, Enum.KeyCode.ButtonR3})
bind("CC_Awakening", "Awakening", {Enum.KeyCode.G, Enum.KeyCode.ButtonL3})

ContextActionService:BindAction("CC_Block", function(_, state)
    if state == Enum.UserInputState.Begin then
        fire("BlockStart")
    elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
        fire("BlockEnd")
    end
    return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonL2)

ContextActionService:BindAction("CC_Sprint", function(_, state)
    if menuOpen() then
        return Enum.ContextActionResult.Pass
    end

    if state == Enum.UserInputState.Begin then
        movement:FireServer("SprintStart")
    elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
        movement:FireServer("SprintEnd")
    end
    return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL1)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or menuOpen() then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        fire("M1")
    end
end)
