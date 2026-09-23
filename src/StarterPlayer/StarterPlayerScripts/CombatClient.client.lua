--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)

local InputController = require(script.Parent.Controllers.InputController)
local InputManager = require(script.Parent.Controllers.InputManager)
local HUDActionBus = require(script.Parent.Controllers.HUDActionBus)
local HUDRegistry = require(script.Parent.Controllers.HUDRegistry)

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

local hud: any = HUDRegistry:Wait()

local localCooldowns: {[string]: number} = {}
local cooldownTotals: {[number]: number} = {}

local function now(): number
    return os.clock()
end

local function menuOpen(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function moveCooldown(action: string): number
    if action == "M1" then
        return Config.Combat.M1.Cooldown
    end

    if action == "Dash" then
        return Config.Combat.Dash.Cooldown
    end

    if action == "Special" then
        local id = player:GetAttribute("CharacterId") or "Yuji"
        local definition = Definitions[id]
        return math.clamp(
            tonumber(definition and definition.SpecialCooldown) or Config.Combat.Special.Cooldown,
            0.25,
            20
        )
    end

    local slot = tonumber(string.match(action, "^Skill(%d)$") or "")
    if slot then
        local id = player:GetAttribute("CharacterId") or "Yuji"
        local move = Movesets.GetMove(id, slot)
        return math.clamp(
            tonumber(move and move.Cooldown) or 1,
            Config.Combat.Skill.MinCooldown,
            Config.Combat.Skill.MaxCooldown
        )
    end

    return 0
end

local function armCooldown(action: string): boolean
    local duration = moveCooldown(action)
    if duration <= 0 then
        return true
    end

    local current = localCooldowns[action] or 0
    if current > now() then
        return false
    end

    localCooldowns[action] = now() + duration

    local slot = tonumber(string.match(action, "^Skill(%d)$") or "")
    if slot then
        cooldownTotals[slot] = duration
    end

    return true
end

local function send(action: string, payload: any?)
    if menuOpen() then
        return
    end

    if action ~= "BlockStart"
        and action ~= "BlockEnd"
        and not armCooldown(action) then
        return
    end

    combatAction:FireServer(action, payload)
end

local function toggleBlock()
    if menuOpen() then
        return
    end

    local active = player:GetAttribute("LocalBlocking") == true

    if active then
        player:SetAttribute("LocalBlocking", false)
        combatAction:FireServer("BlockEnd")
        return
    end

    player:SetAttribute("LocalBlocking", true)
    combatAction:FireServer("BlockStart")
end

local function toggleSprint()
    if menuOpen() then
        return
    end

    local active = player:GetAttribute("LocalSprinting") == true
    player:SetAttribute("LocalSprinting", not active)
    movementRemote:FireServer(active and "SprintEnd" or "SprintStart")
end

local function activate(action: string)
    if action == "BlockToggle" then
        toggleBlock()
        return
    end

    if action == "SprintToggle" then
        toggleSprint()
        return
    end

    if action == "Dash" then
        send("Dash", InputController:GetDashDirection())
        return
    end

    send(action)
end

HUDActionBus:Connect(activate)

InputManager:BindAction(
    "CC_M1",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activate("M1")
        end
    end,
    {Enum.KeyCode.ButtonB, Enum.UserInputType.MouseButton1},
    false
)

InputManager:BindAction(
    "CC_Dash",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activate("Dash")
        end
    end,
    {Enum.KeyCode.Q, Enum.KeyCode.ButtonY},
    false
)

InputManager:BindAction(
    "CC_Special",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activate("Special")
        end
    end,
    {Enum.KeyCode.R, Enum.KeyCode.DPadLeft},
    false
)

InputManager:BindAction(
    "CC_Skill1",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activate("Skill1")
        end
    end,
    {Enum.KeyCode.One, Enum.KeyCode.ButtonL1},
    false
)

InputManager:BindAction(
    "CC_Skill2",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activate("Skill2")
        end
    end,
    {Enum.KeyCode.Two, Enum.KeyCode.ButtonL2},
    false
)

InputManager:BindAction(
    "CC_Skill3",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activate("Skill3")
        end
    end,
    {Enum.KeyCode.Three, Enum.KeyCode.ButtonR2},
    false
)

InputManager:BindAction(
    "CC_Skill4",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activate("Skill4")
        end
    end,
    {Enum.KeyCode.Four, Enum.KeyCode.ButtonR1},
    false
)

InputManager:BindAction(
    "CC_Block",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            if player:GetAttribute("LocalBlocking") ~= true then
                toggleBlock()
            end
        elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
            if player:GetAttribute("LocalBlocking") == true then
                toggleBlock()
            end
        end
    end,
    {Enum.KeyCode.F, Enum.KeyCode.ButtonX},
    false
)

InputManager:BindAction(
    "CC_Sprint",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            toggleSprint()
        elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
            if player:GetAttribute("LocalSprinting") == true then
                toggleSprint()
            end
        end
    end,
    {Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3},
    false
)

InputManager:BindAction(
    "CC_Ultimate",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activate("Ultimate")
        end
    end,
    {Enum.KeyCode.G, Enum.KeyCode.DPadUp},
    false
)

InputManager:BindAction(
    "CC_Awakening",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activate("Awakening")
        end
    end,
    {Enum.KeyCode.H, Enum.KeyCode.ButtonR3},
    false
)

local function bindHealth(character: Model)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = character:WaitForChild("Humanoid", 10)
    end

    if not humanoid or not humanoid:IsA("Humanoid") then
        return
    end

    local update = function()
        hud:UpdateHealth(humanoid.Health, humanoid.MaxHealth)
    end

    humanoid.HealthChanged:Connect(update)
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
    update()
end

local function refreshCharacter()
    local id = player:GetAttribute("CharacterId") or "Yuji"
    local profile = Definitions[id]
    local moves = Movesets.Get(
        id,
        player:GetAttribute("AwakeningActive") == true
            or player:GetAttribute("UltimateActive") == true
    )

    hud:UpdateCharacter(
        profile and profile.Name or id,
        profile and profile.Subtitle or "",
        moves
    )

    localCooldowns = {}
    cooldownTotals = {}
end

local function readState()
    hud:UpdateState(tostring(player:GetAttribute("CombatState") or "Idle"))
end

local function readPower()
    hud:UpdatePower(
        tonumber(player:GetAttribute("UltimateMeter")) or 0,
        tonumber(player:GetAttribute("AwakeningMeter")) or 0,
        player:GetAttribute("UltimateReady") == true,
        player:GetAttribute("AwakeningReady") == true
    )
end

local function updateVisibility()
    hud:SetVisible(not menuOpen())
end

player:GetAttributeChangedSignal("CharacterId"):Connect(refreshCharacter)
player:GetAttributeChangedSignal("CombatState"):Connect(readState)
player:GetAttributeChangedSignal("UltimateMeter"):Connect(readPower)
player:GetAttributeChangedSignal("AwakeningMeter"):Connect(readPower)
player:GetAttributeChangedSignal("UltimateReady"):Connect(readPower)
player:GetAttributeChangedSignal("AwakeningReady"):Connect(readPower)

for _, attribute in ipairs({
    "CCHUD_MenuOpen",
    "CCHUD_CharacterMenuOpen",
    "CCHUD_EmoteWheelOpen",
    "CCHUD_OwnerPanelOpen"
}) do
    player:GetAttributeChangedSignal(attribute):Connect(updateVisibility)
end

player.CharacterAdded:Connect(function(character)
    localCooldowns = {}
    cooldownTotals = {}
    task.defer(function()
        bindHealth(character)
        refreshCharacter()
    end)
end)

refreshCharacter()
readState()
readPower()
updateVisibility()

RunService.RenderStepped:Connect(function()
    local t = now()

    for slot = 1, 4 do
        local action = "Skill" .. tostring(slot)
        local remaining = math.max(0, (localCooldowns[action] or 0) - t)
        hud:SetCooldown(slot, remaining, cooldownTotals[slot] or 1)
    end

    if menuOpen() then
        if player:GetAttribute("LocalBlocking") == true then
            player:SetAttribute("LocalBlocking", false)
            combatAction:FireServer("BlockEnd")
        end

        if player:GetAttribute("LocalSprinting") == true then
            player:SetAttribute("LocalSprinting", false)
            movementRemote:FireServer("SprintEnd")
        end
    end
end)

return nil
