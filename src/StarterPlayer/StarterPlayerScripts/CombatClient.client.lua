--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local blocked = {
    CCHUD_MenuOpen = true,
    CCHUD_CharacterMenuOpen = true,
    CCHUD_EmoteWheelOpen = true,
    CCHUD_OwnerPanelOpen = true
}

local function menuOpen(): boolean
    for attribute in pairs(blocked) do
        if player:GetAttribute(attribute) == true then
            return true
        end
    end
    return false
end

local function fire(action: string, payload: any?)
    if menuOpen() then
        return
    end
    combatAction:FireServer(action, payload)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or menuOpen() then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        fire("M1")
    elseif input.KeyCode == Enum.KeyCode.Q then
        fire("Dash", "Forward")
    elseif input.KeyCode == Enum.KeyCode.E then
        fire("Special")
    elseif input.KeyCode == Enum.KeyCode.One then
        fire("Skill1")
    elseif input.KeyCode == Enum.KeyCode.Two then
        fire("Skill2")
    elseif input.KeyCode == Enum.KeyCode.Three then
        fire("Skill3")
    elseif input.KeyCode == Enum.KeyCode.Four then
        fire("Skill4")
    elseif input.KeyCode == Enum.KeyCode.R then
        fire("Ultimate")
    elseif input.KeyCode == Enum.KeyCode.G then
        fire("Awakening")
    elseif input.KeyCode == Enum.KeyCode.F then
        fire("BlockStart")
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        movementRemote:FireServer("SprintStart")
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        fire("BlockEnd")
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        movementRemote:FireServer("SprintEnd")
    end
end)
