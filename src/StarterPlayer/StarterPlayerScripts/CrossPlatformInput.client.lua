local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatAction = remotes:WaitForChild("CombatAction")

local function combatMenuOpen()
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local accountGui = playerGui and playerGui:FindFirstChild("CursedCollisionAccountUI")
    local accountPanel = accountGui and accountGui:FindFirstChild("AccountPanel")
    return accountPanel and accountPanel.Visible == true
end

local function fire(action)
    if combatMenuOpen() then
        return
    end
    combatAction:FireServer(action)
end

local function bind(name, action, keys)
    ContextActionService:BindAction(name, function(_, state)
        if state == Enum.UserInputState.Begin then
            fire(action)
        end
        return Enum.ContextActionResult.Pass
    end, false, table.unpack(keys))
end

bind("CC_Gamepad_M1", "M1", {Enum.KeyCode.ButtonR2})
bind("CC_Gamepad_Heavy", "Heavy", {Enum.KeyCode.ButtonR1})
bind("CC_Gamepad_Dash", "Dash", {Enum.KeyCode.ButtonA})
bind("CC_Gamepad_Dodge", "Dodge", {Enum.KeyCode.ButtonB})
bind("CC_Gamepad_Grab", "Grab", {Enum.KeyCode.ButtonL1})
bind("CC_Gamepad_Special", "Special", {Enum.KeyCode.ButtonX})
bind("CC_Gamepad_Skill", "Skill", {Enum.KeyCode.ButtonY})
bind("CC_Gamepad_Awaken", "Awaken", {Enum.KeyCode.DPadUp})
bind("CC_Gamepad_Domain", "Domain", {Enum.KeyCode.DPadDown})
bind("CC_Gamepad_OneTime", "OneTime", {Enum.KeyCode.DPadLeft})

ContextActionService:BindAction("CC_Gamepad_Block", function(_, state)
    if state == Enum.UserInputState.Begin then
        fire("BlockStart")
    elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
        fire("BlockEnd")
    end
    return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.ButtonL2)

