--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local CustomMovesets = require(ReplicatedStorage.Characters.CustomMovesets)
local InputController = require(script.Parent.Parent.Controllers.InputController)
local InputManager = require(script.Parent.Parent.Controllers.InputManager)
local Util = require(script.Parent.Util)

local player = Players.LocalPlayer
local M = {}

local started = false
local gui: ScreenGui
local root: Frame
local identityName: TextLabel
local identityTitle: TextLabel
local healthFill: Frame
local healthText: TextLabel
local stateText: TextLabel
local meterFill: Frame
local meterText: TextLabel
local ultimateButton: TextButton
local awakeningButton: TextButton
local specialButton: TextButton
local sprintButton: TextButton
local blockButton: TextButton
local dashButton: TextButton
local m1Button: TextButton
local skillButtons: {[number]: TextButton} = {}
local skillCooldowns: {[number]: TextLabel} = {}
local skillOverlays: {[number]: Frame} = {}
local localCooldowns: {[string]: number} = {}
local blockActive = false
local sprintActive = false

local function menuBlocked(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function cooldownFor(action: string): number
    if action == "M1" then
        return Config.Combat.M1.Cooldown
    elseif action == "Dash" then
        return Config.Combat.Dash.Cooldown
    elseif action == "Special" then
        return Config.Combat.Special.Cooldown
    end

    local slot = tonumber(string.match(action, "^Skill(%d)$"))
    if slot then
        local id = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
        local move = CustomMovesets.GetMove(id, slot)
        return math.clamp(tonumber(move and move.Cooldown) or 1, Config.Combat.Skill.MinCooldown, Config.Combat.Skill.MaxCooldown)
    end

    return 0
end

local function ready(action: string): boolean
    return os.clock() >= (localCooldowns[action] or 0)
end

local function fire(action: string, payload: any?)
    if menuBlocked() then
        return
    end

    if action ~= "BlockStart" and action ~= "BlockEnd" and not ready(action) then
        return
    end

    local duration = cooldownFor(action)
    if duration > 0 then
        localCooldowns[action] = os.clock() + duration
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local combatAction = remotes and remotes:FindFirstChild("CombatAction")
    if combatAction and combatAction:IsA("RemoteEvent") then
        combatAction:FireServer(action, payload)
    end
end

local function updateCharacter()
    local id = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
    local profile = Definitions[id]

    identityName.Text = profile and tostring(profile.Name) or id
    identityTitle.Text = profile and tostring(profile.Subtitle or "") or ""

    local moves = CustomMovesets.Get(id)
    for slot = 1, 4 do
        local move = moves[slot]
        skillButtons[slot].Text = tostring(slot) .. "\n" .. tostring(move and move.Name or ("Skill " .. slot))
    end

    specialButton.Text = tostring(player:GetAttribute("SpecialName") or "SPECIAL") .. "\nR"
    localCooldowns = {}
end

local function updateHealth()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
    healthFill.Size = UDim2.fromScale(ratio, 1)
    healthText.Text = string.format(
        "%d / %d",
        math.floor(math.max(0, humanoid.Health) + 0.5),
        math.floor(math.max(1, humanoid.MaxHealth) + 0.5)
    )
end

local function bindHealth()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    humanoid.HealthChanged:Connect(updateHealth)
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
    updateHealth()
end

local function updatePower()
    local ultimate = math.clamp((tonumber(player:GetAttribute("UltimateMeter")) or 0) / 100, 0, 1)
    local awakening = math.clamp((tonumber(player:GetAttribute("AwakeningMeter")) or 0) / 100, 0, 1)
    local value = math.max(ultimate, awakening)

    meterFill.Size = UDim2.fromScale(value, 1)
    meterFill.BackgroundColor3 = awakening > ultimate
        and Util.Colors.Accent
        or Util.Colors.Accent2

    meterText.Text = awakening > ultimate
        and string.format("AWAKENING %d%%", math.floor(awakening * 100))
        or string.format("ULTIMATE %d%%", math.floor(ultimate * 100))

    ultimateButton.Text = player:GetAttribute("UltimateReady") == true
        and "ULTIMATE\nREADY"
        or "ULTIMATE\nR3"

    awakeningButton.Text = player:GetAttribute("AwakeningReady") == true
        and "AWAKEN\nREADY"
        or "AWAKEN\nG"

    ultimateButton.Active = player:GetAttribute("UltimateReady") == true
    awakeningButton.Active = player:GetAttribute("AwakeningReady") == true
end

local function updateState()
    local state = tostring(player:GetAttribute("CombatState") or "Idle")
    stateText.Text = ({
        Attacking = "ATTACK",
        UsingAbility = "SKILL",
        Blocking = "BLOCK",
        Stunned = "STUNNED",
        Ragdolled = "DOWN",
        Dashing = "DASH",
        Ultimate = "ULTIMATE",
        Awakening = "AWAKEN"
    })[state] or "READY"

    if state == "Stunned" or state == "Ragdolled" then
        stateText.TextColor3 = Util.Colors.Danger
    else
        stateText.TextColor3 = Util.Colors.Text
    end
end

local function setBlock(active: boolean)
    blockActive = active
    blockButton.Text = active and "◉\nBLOCK" or "◉\nBLOCK"
    player:SetAttribute("LocalBlocking", active)
    fire(active and "BlockStart" or "BlockEnd")

    if not active then
        blockButton.BackgroundColor3 = Util.Colors.Panel
    else
        blockButton.BackgroundColor3 = Util.Colors.PanelSoft
    end
end

local function setSprint(active: boolean)
    sprintActive = active
    player:SetAttribute("LocalSprinting", active)

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local movement = remotes and remotes:FindFirstChild("MovementRemote")
    if movement and movement:IsA("RemoteEvent") then
        movement:FireServer(active and "SprintStart" or "SprintEnd")
    end

    sprintButton.Text = active and "◆\nSPRINT" or "◇\nSPRINT"
end

local function updateCooldowns()
    for slot = 1, 4 do
        local action = "Skill" .. tostring(slot)
        local remaining = math.max(0, (localCooldowns[action] or 0) - os.clock())
        local duration = cooldownFor(action)

        if remaining <= 0 then
            skillCooldowns[slot].Text = "READY"
            skillOverlays[slot].Size = UDim2.fromScale(1, 0)
            skillButtons[slot].BackgroundTransparency = 0.06
        else
            skillCooldowns[slot].Text = string.format("%.1f", remaining)
            local ratio = math.clamp(remaining / math.max(0.01, duration), 0, 1)
            skillOverlays[slot].Size = UDim2.fromScale(1, ratio)
            skillButtons[slot].BackgroundTransparency = 0.20
        end
    end

    local cooldownActions = {
        {m1Button, "M1"},
        {dashButton, "Dash"},
        {specialButton, "Special"}
    }

    for _, entry in ipairs(cooldownActions) do
        local button = entry[1] :: TextButton
        local action = entry[2] :: string
        local remaining = math.max(0, (localCooldowns[action] or 0) - os.clock())
        if remaining > 0 then
            button.TextTransparency = 0.30
        else
            button.TextTransparency = 0
        end
    end
end

local function setVisible()
    local hidden = menuBlocked()
    root.Visible = not hidden

    if hidden then
        if sprintActive then
            setSprint(false)
        end
        if blockActive then
            setBlock(false)
        end
    end
end

local function makeSkillCell(parent: Instance, slot: number)
    local cell = Instance.new("Frame")
    cell.Name = "SkillCell" .. slot
    cell.Size = UDim2.fromScale(0.235, 1)
    cell.BackgroundTransparency = 1
    cell.LayoutOrder = slot
    cell.Parent = parent

    local button = Util.button(cell, "Skill" .. slot, tostring(slot), UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), true)
    local key = Util.label(button, tostring(slot), UDim2.fromScale(0.23, 0.18), UDim2.fromScale(0.07, 0.05), 8, Enum.Font.GothamBlack)
    key.TextXAlignment = Enum.TextXAlignment.Left
    key.TextColor3 = Util.Colors.Muted

    local cooldown = Util.label(button, "READY", UDim2.fromScale(0.86, 0.20), UDim2.fromScale(0.07, 0.73), 7)
    cooldown.TextColor3 = Util.Colors.Muted

    local overlay = Instance.new("Frame")
    overlay.Name = "Cooldown"
    overlay.Size = UDim2.fromScale(1, 0)
    overlay.Position = UDim2.fromScale(0, 1)
    overlay.AnchorPoint = Vector2.new(0, 1)
    overlay.BackgroundColor3 = Util.Colors.Black
    overlay.BackgroundTransparency = 0.34
    overlay.BorderSizePixel = 0
    overlay.ZIndex = button.ZIndex + 1
    overlay.Parent = button
    Util.corner(overlay, 10)

    skillButtons[slot] = button
    skillCooldowns[slot] = cooldown
    skillOverlays[slot] = overlay

    button.Activated:Connect(function()
        fire("Skill" .. slot)
    end)
end

function M.Start()
    if started then
        return
    end
    started = true

    gui = Util.makeGui("CursedCollisionCombatHUD", 5)
    root = Util.makeRoot(gui)

    local platform = Util.platform()
    if platform == "Console" then
        GuiService.GuiNavigationEnabled = true
    end

    local top = Instance.new("Frame")
    top.Name = "Identity"
    top.Size = UDim2.fromScale(0.30, 0.075)
    top.Position = UDim2.fromScale(0.50, 0.026)
    top.AnchorPoint = Vector2.new(0.5, 0)
    top.BackgroundColor3 = Util.Colors.Background
    top.BackgroundTransparency = 0.13
    top.Parent = root
    Util.corner(top, 10)
    Util.stroke(top, Color3.fromRGB(73, 77, 96), 0.62)

    identityName = Util.label(top, "Potential Man", UDim2.fromScale(0.94, 0.48), UDim2.fromScale(0.03, 0.05), 14, Enum.Font.GothamBlack)
    identityTitle = Util.label(top, "Shadow Potential", UDim2.fromScale(0.94, 0.28), UDim2.fromScale(0.03, 0.60), 8)
    identityTitle.TextColor3 = Util.Colors.Muted

    local health = Instance.new("Frame")
    health.Name = "Health"
    if platform == "Mobile" then
        health.Size = UDim2.fromScale(0.47, 0.040)
        health.Position = UDim2.fromScale(0.50, 0.135)
        health.AnchorPoint = Vector2.new(0.5, 0)
    else
        health.Size = UDim2.fromScale(0.30, 0.040)
        health.Position = UDim2.fromScale(0.018, 0.125)
    end
    health.BackgroundColor3 = Color3.fromRGB(38, 40, 50)
    health.BorderSizePixel = 0
    health.Parent = root
    Util.corner(health, 8)
    Util.stroke(health, Color3.fromRGB(70, 74, 92), 0.72)

    healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = Util.Colors.Danger
    healthFill.BorderSizePixel = 0
    healthFill.Parent = health
    Util.corner(healthFill, 8)

    healthText = Util.label(health, "100 / 100", UDim2.fromScale(1, 1), UDim2.new(), 8)
    healthText.ZIndex = health.ZIndex + 1

    local state = Instance.new("Frame")
    state.Size = UDim2.fromScale(0.18, 0.036)
    state.Position = UDim2.fromScale(0.50, 0.185)
    state.AnchorPoint = Vector2.new(0.5, 0)
    state.BackgroundColor3 = Util.Colors.Background
    state.BackgroundTransparency = 0.24
    state.Parent = root
    Util.corner(state, 7)
    Util.stroke(state, Color3.fromRGB(70, 74, 92), 0.76)
    stateText = Util.label(state, "READY", UDim2.fromScale(1, 1), UDim2.new(), 8, Enum.Font.GothamBlack)

    meterText = nil

    local meter = Instance.new("Frame")
    meter.Name = "AwakeningMeter"
    meter.Size = UDim2.fromScale(platform == "Mobile" and 0.54 or 0.58, 0.034)
    meter.Position = UDim2.fromScale(0.50, 0.690)
    meter.AnchorPoint = Vector2.new(0.5, 0.5)
    meter.BackgroundColor3 = Color3.fromRGB(38, 40, 50)
    meter.BorderSizePixel = 0
    meter.Parent = root
    Util.corner(meter, 7)
    Util.stroke(meter, Color3.fromRGB(70, 74, 92), 0.74)

    meterFill = Instance.new("Frame")
    meterFill.Size = UDim2.fromScale(0, 1)
    meterFill.BackgroundColor3 = Util.Colors.Accent2
    meterFill.BorderSizePixel = 0
    meterFill.Parent = meter
    Util.corner(meterFill, 7)

    meterText = Util.label(meter, "ULTIMATE 0%", UDim2.fromScale(1, 1), UDim2.new(), 8, Enum.Font.GothamBlack)

    local skillFrame = Instance.new("Frame")
    skillFrame.Name = "Skills"
    skillFrame.Size = UDim2.fromScale(platform == "Mobile" and 0.68 or 0.76, 0.118)
    skillFrame.Position = UDim2.fromScale(0.50, 0.785)
    skillFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    skillFrame.BackgroundTransparency = 1
    skillFrame.Parent = root

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.235, 0, 0.92, 0)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 0)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = skillFrame

    for slot = 1, 4 do
        makeSkillCell(skillFrame, slot)
    end

    local actions = Instance.new("Frame")
    actions.Name = "Actions"
    if platform == "Mobile" then
        actions.Size = UDim2.fromScale(0.27, 0.34)
        actions.Position = UDim2.fromScale(0.795, 0.56)
    elseif platform == "Console" then
        actions.Size = UDim2.fromScale(0.28, 0.30)
        actions.Position = UDim2.fromScale(0.74, 0.54)
    else
        actions.Size = UDim2.fromScale(0.28, 0.30)
        actions.Position = UDim2.fromScale(0.73, 0.54)
    end
    actions.BackgroundTransparency = 1
    actions.Parent = root

    if platform == "Mobile" then
        m1Button = Util.button(actions, "M1", "✊", UDim2.fromScale(0.52, 0.52), UDim2.fromScale(0.58, 0.43))
        m1Button.AnchorPoint = Vector2.new(0.5, 0.5)
        m1Button.TextSize = 30

        blockButton = Util.button(actions, "Block", "◉", UDim2.fromScale(0.31, 0.31), UDim2.fromScale(0.16, 0.23))
        blockButton.AnchorPoint = Vector2.new(0.5, 0.5)
        blockButton.TextSize = 20

        dashButton = Util.button(actions, "Dash", "➤", UDim2.fromScale(0.31, 0.31), UDim2.fromScale(0.16, 0.74))
        dashButton.AnchorPoint = Vector2.new(0.5, 0.5)
        dashButton.TextSize = 20
    else
        m1Button = Util.button(actions, "M1", "M1", UDim2.fromScale(0.52, 0.52), UDim2.fromScale(0.60, 0.52))
        m1Button.AnchorPoint = Vector2.new(0.5, 0.5)
        m1Button.TextSize = 22

        blockButton = Util.button(actions, "Block", "BLOCK\nF", UDim2.fromScale(0.32, 0.20), UDim2.fromScale(0.14, 0.34), true)
        dashButton = Util.button(actions, "Dash", "DASH\nQ", UDim2.fromScale(0.32, 0.20), UDim2.fromScale(0.14, 0.66), true)
    end

    sprintButton = Util.button(
        actions,
        "Sprint",
        platform == "Mobile" and "◇" or "SPRINT",
        UDim2.fromScale(0.33, 0.19),
        UDim2.fromScale(0.14, 0.07),
        true
    )

    specialButton = Util.button(
        root,
        "Special",
        "SPECIAL\nR",
        UDim2.fromScale(platform == "Mobile" and 0.19 or 0.17, 0.060),
        UDim2.fromScale(0.50, 0.925),
        true
    )
    specialButton.AnchorPoint = Vector2.new(0.5, 0.5)

    ultimateButton = Util.button(
        root,
        "Ultimate",
        "ULTIMATE",
        UDim2.fromScale(0.14, 0.060),
        UDim2.fromScale(0.39, 0.925),
        true
    )
    ultimateButton.AnchorPoint = Vector2.new(0.5, 0.5)

    awakeningButton = Util.button(
        root,
        "Awakening",
        "AWAKEN",
        UDim2.fromScale(0.14, 0.060),
        UDim2.fromScale(0.61, 0.925),
        true
    )
    awakeningButton.AnchorPoint = Vector2.new(0.5, 0.5)

    m1Button.Activated:Connect(function()
        fire("M1")
    end)

    dashButton.Activated:Connect(function()
        fire("Dash", InputController:GetDashDirection())
    end)

    blockButton.Activated:Connect(function()
        setBlock(not blockActive)
    end)

    sprintButton.Activated:Connect(function()
        setSprint(not sprintActive)
    end)

    specialButton.Activated:Connect(function()
        fire("Special")
    end)

    ultimateButton.Activated:Connect(function()
        fire("Ultimate")
    end)

    awakeningButton.Activated:Connect(function()
        fire("Awakening")
    end)

    InputManager:BindAction("CC_HUD_M1", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            fire("M1")
        end
    end, {Enum.KeyCode.ButtonR2}, false)

    InputManager:BindAction("CC_HUD_Dash", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            fire("Dash", InputController:GetDashDirection())
        end
    end, {Enum.KeyCode.Q, Enum.KeyCode.ButtonY}, false)

    InputManager:BindAction("CC_HUD_Block", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            if not blockActive then
                setBlock(true)
            end
        elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
            if blockActive then
                setBlock(false)
            end
        end
    end, {Enum.KeyCode.F, Enum.KeyCode.ButtonX}, false)

    InputManager:BindAction("CC_HUD_Special", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            fire("Special")
        end
    end, {Enum.KeyCode.R, Enum.KeyCode.DPadLeft}, false)

    InputManager:BindAction("CC_HUD_Ultimate", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            fire("Ultimate")
        end
    end, {Enum.KeyCode.G, Enum.KeyCode.DPadUp}, false)

    InputManager:BindAction("CC_HUD_Skill1", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            fire("Skill1")
        end
    end, {Enum.KeyCode.One, Enum.KeyCode.ButtonL1}, false)

    InputManager:BindAction("CC_HUD_Skill2", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            fire("Skill2")
        end
    end, {Enum.KeyCode.Two, Enum.KeyCode.ButtonR1}, false)

    InputManager:BindAction("CC_HUD_Skill3", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            fire("Skill3")
        end
    end, {Enum.KeyCode.Three, Enum.KeyCode.ButtonL2}, false)

    InputManager:BindAction("CC_HUD_Skill4", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            fire("Skill4")
        end
    end, {Enum.KeyCode.Four, Enum.KeyCode.ButtonR2}, false)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            fire("M1")
        end
    end)

    for _, name in ipairs({
        "CCHUD_MenuOpen",
        "CCHUD_CharacterMenuOpen",
        "CCHUD_EmoteWheelOpen",
        "CCHUD_OwnerPanelOpen"
    }) do
        player:GetAttributeChangedSignal(name):Connect(setVisible)
    end

    player:GetAttributeChangedSignal("CharacterId"):Connect(updateCharacter)
    player:GetAttributeChangedSignal("UltimateMeter"):Connect(updatePower)
    player:GetAttributeChangedSignal("AwakeningMeter"):Connect(updatePower)
    player:GetAttributeChangedSignal("UltimateReady"):Connect(updatePower)
    player:GetAttributeChangedSignal("AwakeningReady"):Connect(updatePower)
    player:GetAttributeChangedSignal("CombatState"):Connect(updateState)

    player.CharacterAdded:Connect(function()
        blockActive = false
        sprintActive = false
        player:SetAttribute("LocalBlocking", false)
        player:SetAttribute("LocalSprinting", false)
        bindHealth()
    end)

    RunService.RenderStepped:Connect(updateCooldowns)

    updateCharacter()
    updateHealth()
    updatePower()
    updateState()
end

return M
