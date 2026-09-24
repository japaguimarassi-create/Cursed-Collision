--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputManager = require(script.Parent.Controllers.InputManager)
local InputController = require(script.Parent.Controllers.InputController)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)

if not remotes then
    return
end

local combatAction = remotes:WaitForChild("CombatAction", 15)
local movementRemote = remotes:WaitForChild("MovementRemote", 15)

if not combatAction or not movementRemote then
    return
end

local function menuOpen(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_SettingsOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function combatBlocked(): boolean
    return menuOpen()
        or player:GetAttribute("Stunned") == true
        or player:GetAttribute("Ragdolled") == true
end

local function fire(action: string, payload: any?)
    if combatBlocked() then
        return
    end

    combatAction:FireServer(action, payload)
end

local function setBlock(active: boolean)
    if active and combatBlocked() then
        return
    end

    player:SetAttribute("LocalBlocking", active)
    combatAction:FireServer(active and "BlockStart" or "BlockEnd")
end

local function setSprint(active: boolean)
    if active and combatBlocked() then
        return
    end

    player:SetAttribute("LocalSprinting", active)
    movementRemote:FireServer(active and "SprintStart" or "SprintEnd")
end

InputManager:BindAction(
    "CC_M1",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("M1")
        end
    end,
    {Enum.KeyCode.ButtonB},
    false
)

InputManager:BindAction(
    "CC_Dash",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Dash", InputController:GetDashDirection())
        end
    end,
    {Enum.KeyCode.Q, Enum.KeyCode.ButtonY},
    false
)

InputManager:BindAction(
    "CC_Special",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Special")
        end
    end,
    {Enum.KeyCode.R, Enum.KeyCode.DPadLeft},
    false
)

InputManager:BindAction(
    "CC_Skill1",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill1")
        end
    end,
    {Enum.KeyCode.One, Enum.KeyCode.ButtonL1},
    false
)

InputManager:BindAction(
    "CC_Skill2",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill2")
        end
    end,
    {Enum.KeyCode.Two, Enum.KeyCode.ButtonL2},
    false
)

InputManager:BindAction(
    "CC_Skill3",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill3")
        end
    end,
    {Enum.KeyCode.Three, Enum.KeyCode.ButtonR1},
    false
)

InputManager:BindAction(
    "CC_Skill4",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill4")
        end
    end,
    {Enum.KeyCode.Four, Enum.KeyCode.ButtonR2},
    false
)

InputManager:BindAction(
    "CC_Block",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            setBlock(true)
        elseif state == Enum.UserInputState.End
            or state == Enum.UserInputState.Cancel then
            setBlock(false)
        end
    end,
    {Enum.KeyCode.F, Enum.KeyCode.ButtonX},
    false
)

InputManager:BindAction(
    "CC_Sprint",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            setSprint(true)
        elseif state == Enum.UserInputState.End
            or state == Enum.UserInputState.Cancel then
            setSprint(false)
        end
    end,
    {Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3},
    false
)

InputManager:BindAction(
    "CC_Ultimate",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Awakening")
        end
    end,
    {Enum.KeyCode.T, Enum.KeyCode.DPadRight},
    false
)

InputManager:BindAction(
    "CC_Awakening",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Awakening")
        end
    end,
    {Enum.KeyCode.G, Enum.KeyCode.DPadUp},
    false
)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        fire("M1")
    end
end)

player.CharacterAdded:Connect(function()
    player:SetAttribute("LocalBlocking", false)
    player:SetAttribute("LocalSprinting", false)
end)
