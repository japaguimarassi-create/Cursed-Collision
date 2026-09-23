--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local HUDController = {}
HUDController.__index = HUDController

type HUD = {
    Gui: ScreenGui,
    Root: Frame,
    IdentityName: TextLabel,
    IdentityTitle: TextLabel,
    HealthFill: Frame,
    HealthText: TextLabel,
    StateText: TextLabel,
    MeterFill: Frame,
    MeterText: TextLabel,
    UltimateButton: TextButton,
    AwakeningButton: TextButton,
    SkillButtons: {[number]: TextButton},
    SkillCooldowns: {[number]: TextLabel},
    SkillOverlays: {[number]: Frame},
    M1Button: TextButton,
    DashButton: TextButton,
    BlockButton: TextButton,
    SprintButton: TextButton,
    SpecialButton: TextButton,
}

local function corner(object: GuiObject, radius: number)
    local ui = Instance.new("UICorner")
    ui.CornerRadius = UDim.new(0, radius)
    ui.Parent = object
end

local function stroke(object: GuiObject, transparency: number)
    local ui = Instance.new("UIStroke")
    ui.Thickness = 1
    ui.Transparency = transparency
    ui.Parent = object
end

local function label(parent: Instance, textValue: string, size: UDim2, position: UDim2, textSize: number): TextLabel
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Size = size
    object.Position = position
    object.Text = textValue
    object.Font = Enum.Font.GothamBold
    object.TextSize = textSize
    object.TextColor3 = Color3.fromRGB(235, 237, 245)
    object.TextWrapped = true
    object.TextXAlignment = Enum.TextXAlignment.Center
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.Parent = parent
    return object
end

local function button(parent: Instance, name: string, textValue: string): TextButton
    local object = Instance.new("TextButton")
    object.Name = name
    object.Size = UDim2.fromScale(1, 1)
    object.Text = textValue
    object.Font = Enum.Font.GothamBlack
    object.TextSize = 11
    object.TextColor3 = Color3.fromRGB(241, 242, 247)
    object.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
    object.BackgroundTransparency = 0.10
    object.BorderSizePixel = 0
    object.AutoButtonColor = false
    object.Active = true
    object.Selectable = true
    object.Parent = parent
    corner(object, 12)
    stroke(object, 0.58)
    return object
end

local function aspect(object: GuiObject, ratio: number)
    local constraint = Instance.new("UIAspectRatioConstraint")
    constraint.AspectRatio = ratio
    constraint.Parent = object
end

local function pressTween(object: GuiButton)
    object.MouseButton1Down:Connect(function()
        TweenService:Create(object, TweenInfo.new(0.07), {
            BackgroundTransparency = 0
        }):Play()
    end)
    object.MouseButton1Up:Connect(function()
        TweenService:Create(object, TweenInfo.new(0.09), {
            BackgroundTransparency = 0.10
        }):Play()
    end)
end

function HUDController.new()
    local old = player:WaitForChild("PlayerGui"):FindFirstChild("CursedCollisionCombatHUD")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CursedCollisionCombatHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 5
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = player.PlayerGui

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = gui

    local scale = Instance.new("UIScale")
    scale.Parent = root

    local function refreshScale()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local shortAxis = math.min(viewport.X, viewport.Y)
        scale.Scale = math.clamp(shortAxis / 720, 0.72, 1.05)
    end

    refreshScale()

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refreshScale)
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
    end

    local top = Instance.new("Frame")
    top.Name = "TopIdentity"
    top.Size = UDim2.fromScale(0.36, 0.082)
    top.Position = UDim2.fromScale(0.50, 0.025)
    top.AnchorPoint = Vector2.new(0.5, 0)
    top.BackgroundColor3 = Color3.fromRGB(10, 12, 17)
    top.BackgroundTransparency = 0.18
    top.BorderSizePixel = 0
    top.Parent = root
    corner(top, 13)
    stroke(top, 0.72)

    local identityName = label(top, "Potential Man", UDim2.fromScale(0.94, 0.48), UDim2.fromScale(0.03, 0.04), 15)
    local identityTitle = label(top, "Shadow Potential", UDim2.fromScale(0.94, 0.27), UDim2.fromScale(0.03, 0.57), 8)
    identityTitle.TextColor3 = Color3.fromRGB(154, 158, 176)

    local health = Instance.new("Frame")
    health.Name = "Health"
    health.Size = UDim2.fromScale(0.32, 0.046)
    health.Position = UDim2.fromScale(0.018, 0.112)
    health.BackgroundColor3 = Color3.fromRGB(34, 37, 47)
    health.BorderSizePixel = 0
    health.Parent = root
    corner(health, 8)
    stroke(health, 0.74)

    local healthFill = Instance.new("Frame")
    healthFill.Name = "Fill"
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = Color3.fromRGB(216, 72, 88)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = health
    corner(healthFill, 8)

    local healthText = label(health, "100 / 100", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 9)

    local state = Instance.new("Frame")
    state.Name = "State"
    state.Size = UDim2.fromScale(0.20, 0.042)
    state.Position = UDim2.fromScale(0.50, 0.116)
    state.AnchorPoint = Vector2.new(0.5, 0)
    state.BackgroundColor3 = Color3.fromRGB(10, 12, 17)
    state.BackgroundTransparency = 0.25
    state.Parent = root
    corner(state, 8)
    stroke(state, 0.78)

    local stateText = label(state, "READY", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 8)

    local skillFrame = Instance.new("Frame")
    skillFrame.Name = "Skills"
    skillFrame.Size = UDim2.fromScale(0.76, 0.145)
    skillFrame.Position = UDim2.fromScale(0.50, 0.785)
    skillFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    skillFrame.BackgroundTransparency = 1
    skillFrame.Parent = root

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.235, 0, 0.91, 0)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 0)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = skillFrame

    local skillButtons: {[number]: TextButton} = {}
    local skillCooldowns: {[number]: TextLabel} = {}
    local skillOverlays: {[number]: Frame} = {}

    for slot = 1, 4 do
        local cell = Instance.new("Frame")
        cell.Name = "SkillCell" .. tostring(slot)
        cell.BackgroundTransparency = 1
        cell.LayoutOrder = slot
        cell.Parent = skillFrame

        local skill = button(cell, "Skill" .. tostring(slot), tostring(slot))
        skill.TextSize = 11
        aspect(skill, 1.45)
        skillButtons[slot] = skill
        pressTween(skill)

        local keyHint = label(skill, tostring(slot), UDim2.fromScale(0.24, 0.22), UDim2.fromScale(0.07, 0.06), 8)
        keyHint.TextXAlignment = Enum.TextXAlignment.Left
        keyHint.TextColor3 = Color3.fromRGB(160, 164, 182)

        local cooldown = label(skill, "READY", UDim2.fromScale(0.88, 0.20), UDim2.fromScale(0.06, 0.76), 7)
        cooldown.TextColor3 = Color3.fromRGB(160, 164, 182)
        skillCooldowns[slot] = cooldown

        local overlay = Instance.new("Frame")
        overlay.Name = "Cooldown"
        overlay.Size = UDim2.fromScale(1, 0)
        overlay.Position = UDim2.fromScale(0, 1)
        overlay.AnchorPoint = Vector2.new(0, 1)
        overlay.BackgroundColor3 = Color3.fromRGB(5, 6, 9)
        overlay.BackgroundTransparency = 0.28
        overlay.BorderSizePixel = 0
        overlay.ZIndex = skill.ZIndex + 1
        overlay.Parent = skill
        corner(overlay, 12)
        skillOverlays[slot] = overlay
    end

    local meter = Instance.new("Frame")
    meter.Name = "PowerMeter"
    meter.Size = UDim2.fromScale(0.58, 0.038)
    meter.Position = UDim2.fromScale(0.50, 0.707)
    meter.AnchorPoint = Vector2.new(0.5, 0.5)
    meter.BackgroundColor3 = Color3.fromRGB(34, 37, 47)
    meter.BorderSizePixel = 0
    meter.Parent = root
    corner(meter, 7)
    stroke(meter, 0.75)

    local meterFill = Instance.new("Frame")
    meterFill.Name = "Fill"
    meterFill.Size = UDim2.fromScale(0, 1)
    meterFill.BackgroundColor3 = Color3.fromRGB(157, 117, 255)
    meterFill.BorderSizePixel = 0
    meterFill.Parent = meter
    corner(meterFill, 7)

    local meterText = label(meter, "ULTIMATE 0%", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 8)

    local actionArea = Instance.new("Frame")
    actionArea.Name = "Actions"
    actionArea.Size = UDim2.fromScale(0.31, 0.30)
    actionArea.Position = UDim2.fromScale(0.73, 0.54)
    actionArea.BackgroundTransparency = 1
    actionArea.Parent = root

    local m1Holder = Instance.new("Frame")
    m1Holder.Size = UDim2.fromScale(0.54, 0.54)
    m1Holder.Position = UDim2.fromScale(0.50, 0.53)
    m1Holder.AnchorPoint = Vector2.new(0.5, 0.5)
    m1Holder.BackgroundTransparency = 1
    m1Holder.Parent = actionArea

    local m1 = button(m1Holder, "M1", "M1")
    m1.TextSize = 22
    aspect(m1, 1)

    local dashHolder = Instance.new("Frame")
    dashHolder.Size = UDim2.fromScale(0.34, 0.20)
    dashHolder.Position = UDim2.fromScale(0.14, 0.63)
    dashHolder.BackgroundTransparency = 1
    dashHolder.Parent = actionArea
    local dash = button(dashHolder, "Dash", "DASH")
    pressTween(dash)

    local blockHolder = Instance.new("Frame")
    blockHolder.Size = UDim2.fromScale(0.34, 0.20)
    blockHolder.Position = UDim2.fromScale(0.14, 0.34)
    blockHolder.BackgroundTransparency = 1
    blockHolder.Parent = actionArea
    local block = button(blockHolder, "Block", "BLOCK")
    pressTween(block)

    local sprintHolder = Instance.new("Frame")
    sprintHolder.Size = UDim2.fromScale(0.34, 0.20)
    sprintHolder.Position = UDim2.fromScale(0.14, 0.07)
    sprintHolder.BackgroundTransparency = 1
    sprintHolder.Parent = actionArea
    local sprint = button(sprintHolder, "Sprint", "SPRINT")
    pressTween(sprint)

    local special = button(root, "Special", "SPECIAL")
    special.Size = UDim2.fromScale(0.18, 0.060)
    special.Position = UDim2.fromScale(0.50, 0.925)
    special.AnchorPoint = Vector2.new(0.5, 0.5)
    pressTween(special)

    local ultimate = button(root, "Ultimate", "ULTIMATE")
    ultimate.Size = UDim2.fromScale(0.15, 0.060)
    ultimate.Position = UDim2.fromScale(0.385, 0.925)
    ultimate.AnchorPoint = Vector2.new(0.5, 0.5)
    pressTween(ultimate)

    local awakening = button(root, "Awakening", "AWAKEN")
    awakening.Size = UDim2.fromScale(0.15, 0.060)
    awakening.Position = UDim2.fromScale(0.615, 0.925)
    awakening.AnchorPoint = Vector2.new(0.5, 0.5)
    pressTween(awakening)

    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
    end

    UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
        if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
            GuiService.GuiNavigationEnabled = true
        end
    end)

    return setmetatable({
        Gui = gui,
        Root = root,
        IdentityName = identityName,
        IdentityTitle = identityTitle,
        HealthFill = healthFill,
        HealthText = healthText,
        StateText = stateText,
        MeterFill = meterFill,
        MeterText = meterText,
        UltimateButton = ultimate,
        AwakeningButton = awakening,
        SkillButtons = skillButtons,
        SkillCooldowns = skillCooldowns,
        SkillOverlays = skillOverlays,
        M1Button = m1,
        DashButton = dash,
        BlockButton = block,
        SprintButton = sprint,
        SpecialButton = special
    }, HUDController)
end

function HUDController:SetVisible(self: HUD, visible: boolean)
    self.Root.Visible = visible
end

function HUDController:UpdateCharacter(self: HUD, name: string, subtitle: string, moves: {[number]: any})
    self.IdentityName.Text = name
    self.IdentityTitle.Text = subtitle

    for slot = 1, 4 do
        local move = moves[slot]
        self.SkillButtons[slot].Text = tostring(slot) .. "\n" .. (move and move.Name or ("Skill " .. tostring(slot)))
    end
end

function HUDController:UpdateHealth(self: HUD, health: number, maxHealth: number)
    local ratio = math.clamp(health / math.max(1, maxHealth), 0, 1)
    self.HealthFill.Size = UDim2.fromScale(ratio, 1)
    self.HealthText.Text = string.format("%d / %d", math.floor(math.max(0, health) + 0.5), math.floor(math.max(1, maxHealth) + 0.5))
end

function HUDController:UpdateState(self: HUD, state: string)
    local display = ({
        Attacking = "ATTACK",
        UsingAbility = "SKILL",
        Blocking = "BLOCK",
        Stunned = "STUNNED",
        Ragdolled = "DOWN",
        Dashing = "DASH",
        Ultimate = "ULTIMATE",
        Awakening = "AWAKEN"
    })[state] or "READY"

    self.StateText.Text = display
end

function HUDController:UpdatePower(self: HUD, ultimate: number, awakening: number, ultimateReady: boolean, awakeningReady: boolean)
    local value = math.max(ultimate, awakening)
    self.MeterFill.Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1)

    local labelText = if awakening > ultimate
        then string.format("AWAKENING %d%%", math.floor(awakening))
        else string.format("ULTIMATE %d%%", math.floor(ultimate))
    self.MeterText.Text = labelText

    self.UltimateButton.Text = ultimateReady and "ULTIMATE\nREADY" or "ULTIMATE"
    self.AwakeningButton.Text = awakeningReady and "AWAKEN\nREADY" or "AWAKEN"
end

function HUDController:SetCooldown(self: HUD, slot: number, remaining: number, total: number)
    local buttonObject = self.SkillButtons[slot]
    local cooldown = self.SkillCooldowns[slot]
    local overlay = self.SkillOverlays[slot]

    if remaining <= 0 then
        cooldown.Text = "READY"
        overlay.Size = UDim2.fromScale(1, 0)
        buttonObject.BackgroundTransparency = 0.10
        return
    end

    cooldown.Text = string.format("%.1fs", remaining)
    local ratio = math.clamp(remaining / math.max(0.01, total), 0, 1)
    overlay.Size = UDim2.fromScale(1, ratio)
    buttonObject.BackgroundTransparency = 0.22
end

return HUDController
