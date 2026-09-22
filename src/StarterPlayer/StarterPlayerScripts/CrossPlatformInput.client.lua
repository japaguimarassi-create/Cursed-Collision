local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remotes then
    return
end

local combatAction = remotes:WaitForChild("CombatAction", 15)
if not combatAction then
    return
end

local function menuOpen()
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function fire(action: string, payload: any)
    if menuOpen() then
        return
    end
    combatAction:FireServer(action, payload)
end

local function bind(name: string, action: string, keyCodes: {Enum.KeyCode})
    ContextActionService:BindAction(name, function(_, state)
        if state == Enum.UserInputState.Begin then
            fire(action)
        end
        return Enum.ContextActionResult.Pass
    end, false, table.unpack(keyCodes))
end

bind("CC_Gamepad_M1", "M1", {Enum.KeyCode.ButtonR2})
bind("CC_Gamepad_Dash", "Dash", {Enum.KeyCode.ButtonA})
bind("CC_Gamepad_Special", "Special", {Enum.KeyCode.ButtonX})
bind("CC_Gamepad_Skill1", "Skill1", {Enum.KeyCode.ButtonR1})
bind("CC_Gamepad_Skill2", "Skill2", {Enum.KeyCode.ButtonY})
bind("CC_Gamepad_Skill3", "Skill3", {Enum.KeyCode.DPadUp})
bind("CC_Gamepad_Skill4", "Skill4", {Enum.KeyCode.DPadDown})

ContextActionService:BindAction("CC_Gamepad_Block", function(_, state)
    if state == Enum.UserInputState.Begin then
        fire("BlockStart")
    elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
        fire("BlockEnd")
    end
    return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.ButtonL2)
