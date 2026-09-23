--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local CustomMovesets = require(ReplicatedStorage.Characters.CustomMovesets)
local InputController = require(script.Parent.Controllers.InputController)
local InputManager = require(script.Parent.Controllers.InputManager)
local HUDController = require(script.Parent.Controllers.HUDController)

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

local hud: any = HUDController.new()

local localCooldowns: {[string]: number} = {}
local healthConnection: RBXScriptConnection?
local maxHealthConnection: RBXScriptConnection?

local function menuOpen(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function remaining(action: string): number
    return math.max(0, (localCooldowns[action] or 0) - os.clock())
end

local function moveCooldown(action: string): number
    if action == "M1" then
        return Config.Combat.M1.Cooldown
    elseif action == "Dash" then
        return Config.Combat.Dash.Cooldown
    elseif action == "Special" then
        return Config.Combat.Special.Cooldown
    end

    local slot = tonumber(string.match(action, "^Skill(%d)$") or "")
    local id = player:GetAttribute("CharacterId") or "PotentialMan"
    local move = slot and CustomMovesets.GetMove(id, slot)

    return math.clamp(
        tonumber(move and move.Cooldown) or 1,
        Config.Combat.Skill.MinCooldown,
        Config.Combat.Skill.MaxCooldown
    )
end

local function fire(action: string, payload: any?)
    if menuOpen()
        and action ~= "BlockEnd" then
        return
    end

    local isBlockAction = action == "BlockStart" or action == "BlockEnd"

    if not isBlockAction and remaining(action) > 0 then
        return
    end

    local cooldown = if isBlockAction then 0 else moveCooldown(action)

    if cooldown > 0 then
        localCooldowns[action] = os.clock() + cooldown
    end

    combatAction:FireServer(action, payload)
end

local function setBlocking(active: boolean)
    player:SetAttribute("LocalBlocking", active)
    hud.BlockButton.Text = active and "BLOCKING" or "BLOCK"
    fire(active and "BlockStart" or "BlockEnd")
end

local function setSprinting(active: boolean)
    player:SetAttribute("LocalSprinting", active)
    hud.SprintButton.Text = active and "SPRINTING" or "SPRINT"
    movementRemote:FireServer(active and "SprintStart" or "SprintEnd")
end

local function activatePower(action: "Ultimate" | "Awakening")
    if menuOpen() then
        return
    end

    combatAction:FireServer(action)
end

local function refreshCharacter()
    local id = player:GetAttribute("CharacterId") or "PotentialMan"
    local profile = Definitions[id]
    local moves = CustomMovesets.Get(id)

    hud:UpdateCharacter(
        profile and profile.Name or id,
        profile and profile.Subtitle or "",
        moves
    )

    localCooldowns = {}
end

local function refreshHealth()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return
    end

    hud:UpdateHealth(humanoid.Health, humanoid.MaxHealth)
end

local function bindHealth(character: Model)
    if healthConnection then
        healthConnection:Disconnect()
        healthConnection = nil
    end

    if maxHealthConnection then
        maxHealthConnection:Disconnect()
        maxHealthConnection = nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    healthConnection = humanoid.HealthChanged:Connect(function()
        hud:UpdateHealth(humanoid.Health, humanoid.MaxHealth)
    end)

    maxHealthConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        hud:UpdateHealth(humanoid.Health, humanoid.MaxHealth)
    end)

    refreshHealth()
end

local function refreshState()
    hud:UpdateState(tostring(player:GetAttribute("CombatState") or "Idle"))
end

local function refreshPower()
    local ultimate = tonumber(player:GetAttribute("UltimateMeter")) or 0
    local awakening = tonumber(player:GetAttribute("AwakeningMeter")) or 0

    hud:UpdatePower(
        ultimate,
        awakening,
        player:GetAttribute("UltimateReady") == true,
        player:GetAttribute("AwakeningReady") == true
    )
end

local function syncVisibility()
    hud:SetVisible(not menuOpen())

    if menuOpen() then
        if player:GetAttribute("LocalBlocking") == true then
            player:SetAttribute("LocalBlocking", false)
            hud.BlockButton.Text = "BLOCK"
            combatAction:FireServer("BlockEnd")
        end

        if player:GetAttribute("LocalSprinting") == true then
            player:SetAttribute("LocalSprinting", false)
            hud.SprintButton.Text = "SPRINT"
            movementRemote:FireServer("SprintEnd")
        end
    end
end

for slot = 1, 4 do
    hud.SkillButtons[slot].Activated:Connect(function()
        fire("Skill" .. tostring(slot))
    end)
end

hud.M1Button.Activated:Connect(function()
    fire("M1")
end)

hud.DashButton.Activated:Connect(function()
    fire("Dash", InputController:GetDashDirection())
end)

hud.BlockButton.Activated:Connect(function()
    setBlocking(player:GetAttribute("LocalBlocking") ~= true)
end)

hud.SprintButton.Activated:Connect(function()
    setSprinting(player:GetAttribute("LocalSprinting") ~= true)
end)

hud.SpecialButton.Activated:Connect(function()
    fire("Special")
end)

hud.UltimateButton.Activated:Connect(function()
    activatePower("Ultimate")
end)

hud.AwakeningButton.Activated:Connect(function()
    activatePower("Awakening")
end)

InputManager:BindAction(
    "CC_M1",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("M1")
        end
    end,
    {Enum.KeyCode.ButtonR2},
    false
)

InputManager:BindAction(
    "CC_Dash",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Dash", InputController:GetDashDirection())
        end
    end,
    {Enum.KeyCode.Q, Enum.KeyCode.ButtonA},
    false
)

InputManager:BindAction(
    "CC_Special",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Special")
        end
    end,
    {Enum.KeyCode.E, Enum.KeyCode.ButtonX},
    false
)

InputManager:BindAction(
    "CC_Skill1",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill1")
        end
    end,
    {Enum.KeyCode.One, Enum.KeyCode.ButtonR1},
    false
)

InputManager:BindAction(
    "CC_Skill2",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill2")
        end
    end,
    {Enum.KeyCode.Two, Enum.KeyCode.ButtonY},
    false
)

InputManager:BindAction(
    "CC_Skill3",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill3")
        end
    end,
    {Enum.KeyCode.Three, Enum.KeyCode.DPadUp},
    false
)

InputManager:BindAction(
    "CC_Skill4",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill4")
        end
    end,
    {Enum.KeyCode.Four, Enum.KeyCode.DPadDown},
    false
)

InputManager:BindAction(
    "CC_Block",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            setBlocking(true)
        elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
            setBlocking(false)
        end
    end,
    {Enum.KeyCode.F, Enum.KeyCode.ButtonL2},
    false
)

InputManager:BindAction(
    "CC_Sprint",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            setSprinting(true)
        elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
            setSprinting(false)
        end
    end,
    {Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL1},
    false
)

InputManager:BindAction(
    "CC_Ultimate",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activatePower("Ultimate")
        end
    end,
    {Enum.KeyCode.R, Enum.KeyCode.ButtonR3},
    false
)

InputManager:BindAction(
    "CC_Awakening",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activatePower("Awakening")
        end
    end,
    {Enum.KeyCode.G, Enum.KeyCode.ButtonL3},
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

local menuAttributes = {
    "CCHUD_MenuOpen",
    "CCHUD_CharacterMenuOpen",
    "CCHUD_EmoteWheelOpen",
    "CCHUD_OwnerPanelOpen"
}

for _, attribute in ipairs(menuAttributes) do
    player:GetAttributeChangedSignal(attribute):Connect(syncVisibility)
end

for _, attribute in ipairs({
    "CombatState",
    "UltimateMeter",
    "AwakeningMeter",
    "UltimateReady",
    "AwakeningReady"
}) do
    player:GetAttributeChangedSignal(attribute):Connect(function()
        refreshState()
        refreshPower()
    end)
end

player:GetAttributeChangedSignal("CharacterId"):Connect(refreshCharacter)

player.CharacterAdded:Connect(function(character)
    bindHealth(character)
    refreshCharacter()
    refreshState()
    refreshPower()
    syncVisibility()
end)

if player.Character then
    bindHealth(player.Character)
end

refreshCharacter()
refreshState()
refreshPower()
syncVisibility()

RunService.RenderStepped:Connect(function()
    for slot = 1, 4 do
        local action = "Skill" .. tostring(slot)
        local left = remaining(action)
        hud:SetCooldown(slot, left, moveCooldown(action))
    end

    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
    end
end)

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
    player:SetAttribute("InputDevice", tostring(UserInputService.PreferredInput))

    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = hud.M1Button
    end
end)

if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
    GuiService.GuiNavigationEnabled = true
    GuiService.SelectedObject = hud.M1Button
end
