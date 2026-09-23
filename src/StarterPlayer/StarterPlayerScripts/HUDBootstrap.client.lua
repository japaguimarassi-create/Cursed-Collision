--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Limpa interfaces antigas de versões anteriores durante a atualização.
for _, name in ipairs({
    "CursedCollisionCombatHUD",
    "CursedCollisionAccountUI",
    "CursedCollisionCharacterUI",
    "CursedCollisionOwnerUI",
    "CursedCollisionEmoteUI"
}) do
    local legacy = playerGui:FindFirstChild(name)
    if legacy then
        legacy:Destroy()
    end
end

for _, attribute in ipairs({
    "CCHUD_MenuOpen",
    "CCHUD_CharacterMenuOpen",
    "CCHUD_EmoteWheelOpen",
    "CCHUD_SettingsOpen",
    "CCHUD_OwnerPanelOpen"
}) do
    player:SetAttribute(attribute, false)
end

player:SetAttribute("CC_HUD_Input", tostring(UserInputService.PreferredInput))

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
    player:SetAttribute("CC_HUD_Input", tostring(UserInputService.PreferredInput))
end)
