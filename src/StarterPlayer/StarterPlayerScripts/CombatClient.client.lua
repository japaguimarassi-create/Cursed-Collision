--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)

if not remotes then
    return
end

local combatAction = remotes:WaitForChild("CombatAction", 15)
if not combatAction or not combatAction:IsA("RemoteEvent") then
    return
end

local Config = require(ReplicatedStorage.Shared.Config)
local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)
local InputManager: any = require(script.Parent.Controllers.InputManager)
local InputController: any = require(script.Parent.Controllers.InputController)
local HUDController = require(script.Parent.Controllers.HUDController)
local HUD: any = HUDController.new()

type LocalCooldown = {
    ReadyAt: number,
    Duration: number
}

local predicted: {[string]: LocalCooldown} = {}

local function now(): number
    return os.clock()
end

local function blockedByUI(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function serverRemaining(action: string): number
    local untilValue = tonumber(player:GetAttribute("CooldownUntil_" .. action)) or 0
    return math.max(0, untilValue - now())
end

local function moveDuration(action: string): number
    if action == "M1" then
        return Config.Combat.M1.Cooldown
    elseif action == "Dash" then
        return Config.Combat.Dash.Cooldown
    elseif action == "Special" then
        return math.clamp(
            tonumber(player:GetAttribute("SpecialCooldown")) or 4,
            0.25,
            20
        )
    end

    local slot = tonumber(string.match(action, "^Skill(%d)$"))
    local characterId = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
    local move = slot and Movesets.GetMove(characterId, slot)

    return math.clamp(
        tonumber(move and move.Cooldown) or 1,
        Config.Combat.Skill.MinCooldown,
        Config.Combat.Skill.MaxCooldown
    )
end

local function ready(action: string): boolean
    local localState = predicted[action]
    local localRemaining = localState and math.max(0, localState.ReadyAt - now()) or 0
    return math.max(localRemaining, serverRemaining(action)) <= 0
end

local function predict(action: string, duration: number)
    if duration > 0 then
        predicted[action] = {
            ReadyAt = now() + duration,
            Duration = duration
        }
    end
end

local function fire(action: string, payload: any?)
    if blockedByUI() then
        return
    end

    if action ~= "BlockStart"
        and action ~= "BlockEnd"
        and not ready(action) then
        return
    end

    local duration = if action == "BlockStart" or action == "BlockEnd"
        then 0
        else moveDuration(action)

    predict(action, duration)
    combatAction:FireServer(action, payload)
end

local function setBlocking(active: boolean)
    player:SetAttribute("LocalBlocking", active)
    HUD:SetActionState("Block", active)

    fire(active and "BlockStart" or "BlockEnd")
end

local function setSprinting(active: boolean)
    player:SetAttribute("LocalSprinting", active)
    HUD:SetActionState("Sprint", active)

    local movementRemote = remotes:FindFirstChild("MovementRemote")
    if not movementRemote or not movementRemote:IsA("RemoteEvent") then
        return
    end

    movementRemote:FireServer(active and "SprintStart" or "SprintEnd")
end

local function activatePower(action: string)
    if blockedByUI() then
        return
    end

    combatAction:FireServer(action)
end

HUD.M1Button.Activated:Connect(function()
    fire("M1")
end)

HUD.DashButton.Activated:Connect(function()
    fire("Dash", InputController:GetDashDirection())
end)

HUD.BlockButton.Activated:Connect(function()
    setBlocking(player:GetAttribute("LocalBlocking") ~= true)
end)

HUD.SprintButton.Activated:Connect(function()
    setSprinting(player:GetAttribute("LocalSprinting") ~= true)
end)

HUD.SpecialButton.Activated:Connect(function()
    fire("Special")
end)

HUD.UltimateButton.Activated:Connect(function()
    activatePower("Ultimate")
end)

HUD.AwakeningButton.Activated:Connect(function()
    activatePower("Awakening")
end)

for slot = 1, 4 do
    local button = HUD.SkillButtons[slot]
    button.Activated:Connect(function()
        fire("Skill" .. tostring(slot))
    end)
end

InputManager:BindAction(
    "CC_M1",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("M1")
        end
    end,
    {Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2},
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

local function refreshCharacter()
    local id = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
    local definition = Definitions[id]
    local moves = Movesets.Get(id)

    if definition then
        HUD:UpdateCharacter(
            tostring(definition.Name),
            tostring(definition.Subtitle or ""),
            moves
        )
    end
end

local function bindHealth(character: Model)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local function update()
        HUD:UpdateHealth(humanoid.Health, humanoid.MaxHealth)
    end

    humanoid.HealthChanged:Connect(update)
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
    update()
end

local function refreshState()
    HUD:UpdateState(tostring(player:GetAttribute("CombatState") or "Idle"))
    HUD:SetActionState("Block", player:GetAttribute("Blocking") == true)
    HUD:SetActionState("Sprint", player:GetAttribute("LocalSprinting") == true)
end

local function refreshPower()
    HUD:UpdatePower(
        tonumber(player:GetAttribute("UltimateMeter")) or 0,
        tonumber(player:GetAttribute("AwakeningMeter")) or 0,
        player:GetAttribute("UltimateReady") == true,
        player:GetAttribute("AwakeningReady") == true
    )
end

local function refreshCooldowns()
    for slot = 1, 4 do
        local action = "Skill" .. tostring(slot)
        local remaining = serverRemaining(action)
        local predictedState = predicted[action]
        if predictedState then
            remaining = math.max(
                remaining,
                predictedState.ReadyAt - now()
            )
        end

        HUD:SetCooldown(
            slot,
            math.max(0, remaining),
            moveDuration(action)
        )
    end
end

for _, attribute in ipairs({
    "CharacterId",
    "CharacterName",
    "CharacterTitle",
    "SpecialName"
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refreshCharacter)
end

for _, attribute in ipairs({
    "CombatState",
    "Blocking",
    "CombatStunned",
    "Ragdolled"
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refreshState)
end

for _, attribute in ipairs({
    "UltimateMeter",
    "AwakeningMeter",
    "UltimateReady",
    "AwakeningReady"
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refreshPower)
end

for slot = 1, 4 do
    player:GetAttributeChangedSignal("CooldownUntil_Skill" .. tostring(slot)):Connect(refreshCooldowns)
end

player.CharacterAdded:Connect(function(character)
    bindHealth(character)
end)

refreshCharacter()
refreshState()
refreshPower()
refreshCooldowns()

local function updateLoop()
    if HUD.Root.Visible then
        refreshCooldowns()
    end
end

task.spawn(function()
    while HUD.Gui.Parent do
        updateLoop()
        task.wait(0.08)
    end
end)

for _, character in ipairs(workspace:GetChildren()) do
    if character:IsA("Model") and character == player.Character then
        bindHealth(character)
    end
end

return nil
