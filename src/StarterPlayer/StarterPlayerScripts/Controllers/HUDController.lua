--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

export type HUD = {
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
    GetButton: (self: HUD, name: string) -> TextButton?,
    SetVisible: (self: HUD, visible: boolean) -> (),
    UpdateCharacter: (self: HUD, name: string, subtitle: string, moves: {[number]: any}) -> (),
    UpdateHealth: (self: HUD, health: number, maxHealth: number) -> (),
    UpdateState: (self: HUD, state: string) -> (),
    UpdatePower: (self: HUD, ultimate: number, awakening: number, ultimateReady: boolean, awakeningReady: boolean) -> (),
    SetCooldown: (self: HUD, slot: number, remaining: number, total: number) -> (),
    SetActionState: (self: HUD, action: string, active: boolean) -> (),
    RefreshInputHints: (self: HUD) -> ()
}

local HUDController = {}
HUDController.__index = HUDController

local COLORS = {
    Background = Color3.fromRGB(10, 12, 18),
    Button = Color3.fromRGB(20, 23, 31),
    ButtonPressed = Color3.fromRGB(42, 37, 55),
    Text = Color3.fromRGB(238, 239, 245),
    Muted = Color3.fromRGB(155, 158, 176),
    Accent = Color3.fromRGB(155, 112, 255),
    Health = Color3.fromRGB(216, 72, 88),
    Ready = Color3.fromRGB(104, 222, 148),
    Cooldown = Color3.fromRGB(5, 6, 9)
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

local function label(
    parent: Instance,
    textValue: string,
    size: UDim2,
    position: UDim2,
    textSize: number
): TextLabel
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Size = size
    object.Position = position
    object.Text = textValue
    object.Font = Enum.Font.GothamBold
    object.TextSize = textSize
    object.TextColor3 = COLORS.Text
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
    object.TextColor3 = COLORS.Text
    object.BackgroundColor3 = COLORS.Button
    object.BackgroundTransparency = 0.08
    object.BorderSizePixel = 0
    object.AutoButtonColor = false
    object.Active = true
    object.Selectable = true
    object.Parent = parent
    corner(object, 12)
    stroke(object, 0.58)

    object.MouseButton1Down:Connect(function()
        TweenService:Create(object, TweenInfo.new(0.06), {
            BackgroundColor3 = COLORS.ButtonPressed
        }):Play()
    end)

    object.MouseButton1Up:Connect(function()
        TweenService:Create(object, TweenInfo.new(0.08), {
            BackgroundColor3 = COLORS.Button
        }):Play()
    end)

    return object
end

local function sizeConstraint(object: GuiObject, minSize: Vector2, maxSize: Vector2)
    local constraint = Instance.new("UISizeConstraint")
    constraint.MinSize = minSize
    constraint.MaxSize = maxSize
    constraint.Parent = object
end

local function aspect(object: GuiObject, ratio: number)
    local constraint = Instance.new("UIAspectRatioConstraint")
    constraint.AspectRatio = ratio
    constraint.Parent = object
end

local function createInputHint(parent: GuiObject): TextLabel
    local hint = label(parent, "", UDim2.fromScale(0.28, 0.22), UDim2.fromScale(0.06, 0.05), 8)
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.TextColor3 = COLORS.Muted
    return hint
end

function HUDController.new(): HUD
    local playerGui = player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("CursedCollisionCombatHUD")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CursedCollisionCombatHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 5
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = playerGui

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = gui

    local rootScale = Instance.new("UIScale")
    rootScale.Parent = root

    local function refreshScale()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local shortAxis = math.min(viewport.X, viewport.Y)
        rootScale.Scale = math.clamp(shortAxis / 720, 0.72, 1.08)
    end

    refreshScale()

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        refreshScale()
        local camera = workspace.CurrentCamera
        if camera then
            camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
        end
    end)

    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
    end

    local identity = Instance.new("Frame")
    identity.Name = "Identity"
    identity.Size = UDim2.fromScale(0.34, 0.085)
    identity.Position = UDim2.fromScale(0.50, 0.022)
    identity.AnchorPoint = Vector2.new(0.5, 0)
    identity.BackgroundColor3 = COLORS.Background
    identity.BackgroundTransparency = 0.16
    identity.BorderSizePixel = 0
    identity.Parent = root
    corner(identity, 13)
    stroke(identity, 0.72)
    sizeConstraint(identity, Vector2.new(240, 56), Vector2.new(520, 88))

    local identityName = label(identity, "Potential Man", UDim2.fromScale(0.94, 0.50), UDim2.fromScale(0.03, 0.03), 15)
    local identityTitle = label(identity, "Shadow Potential", UDim2.fromScale(0.94, 0.26), UDim2.fromScale(0.03, 0.60), 8)
    identityTitle.TextColor3 = COLORS.Muted

    local health = Instance.new("Frame")
    health.Name = "Health"
    health.Size = UDim2.fromScale(0.32, 0.046)
    health.Position = UDim2.fromScale(0.018, 0.112)
    health.BackgroundColor3 = Color3.fromRGB(34, 37, 47)
    health.BorderSizePixel = 0
    health.Parent = root
    corner(health, 8)
    stroke(health, 0.74)
    sizeConstraint(health, Vector2.new(180, 22), Vector2.new(460, 36))

    local healthFill = Instance.new("Frame")
    healthFill.Name = "Fill"
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = COLORS.Health
    healthFill.BorderSizePixel = 0
    healthFill.Parent = health
    corner(healthFill, 8)

    local healthText = label(health, "100 / 100", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 9)

    local state = Instance.new("Frame")
    state.Name = "State"
    state.Size = UDim2.fromScale(0.20, 0.042)
    state.Position = UDim2.fromScale(0.50, 0.115)
    state.AnchorPoint = Vector2.new(0.5, 0)
    state.BackgroundColor3 = COLORS.Background
    state.BackgroundTransparency = 0.20
    state.BorderSizePixel = 0
    state.Parent = root
    corner(state, 8)
    stroke(state, 0.78)
    local stateText = label(state, "READY", UDim2.fromScale(1, 1), UDim2.new(), 8)

    local meter = Instance.new("Frame")
    meter.Name = "PowerMeter"
    meter.Size = UDim2.fromScale(0.58, 0.038)
    meter.Position = UDim2.fromScale(0.50, 0.705)
    meter.AnchorPoint = Vector2.new(0.5, 0.5)
    meter.BackgroundColor3 = Color3.fromRGB(34, 37, 47)
    meter.BorderSizePixel = 0
    meter.Parent = root
    corner(meter, 7)
    stroke(meter, 0.75)
    sizeConstraint(meter, Vector2.new(240, 20), Vector2.new(780, 34))

    local meterFill = Instance.new("Frame")
    meterFill.Name = "Fill"
    meterFill.Size = UDim2.fromScale(0, 1)
    meterFill.BackgroundColor3 = COLORS.Accent
    meterFill.BorderSizePixel = 0
    meterFill.Parent = meter
    corner(meterFill, 7)

    local meterText = label(meter, "ULTIMATE 0%", UDim2.fromScale(1, 1), UDim2.new(), 8)

    local skillFrame = Instance.new("Frame")
    skillFrame.Name = "Skills"
    skillFrame.Size = UDim2.fromScale(0.76, 0.145)
    skillFrame.Position = UDim2.fromScale(0.50, 0.79)
    skillFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    skillFrame.BackgroundTransparency = 1
    skillFrame.Parent = root
    sizeConstraint(skillFrame, Vector2.new(360, 82), Vector2.new(1040, 150))

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.235, 0, 0.90, 0)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 0)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = skillFrame

    local skillButtons: {[number]: TextButton} = {}
    local skillCooldowns: {[number]: TextLabel} = {}
    local skillOverlays: {[number]: Frame} = {}
    local skillHints: {[number]: TextLabel} = {}

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
        skillHints[slot] = createInputHint(skill)

        local cooldown = label(skill, "READY", UDim2.fromScale(0.88, 0.20), UDim2.fromScale(0.06, 0.76), 7)
        cooldown.TextColor3 = COLORS.Muted
        skillCooldowns[slot] = cooldown

        local overlay = Instance.new("Frame")
        overlay.Name = "Cooldown"
        overlay.Size = UDim2.fromScale(1, 0)
        overlay.Position = UDim2.fromScale(0, 1)
        overlay.AnchorPoint = Vector2.new(0, 1)
        overlay.BackgroundColor3 = COLORS.Cooldown
        overlay.BackgroundTransparency = 0.28
        overlay.BorderSizePixel = 0
        overlay.ZIndex = skill.ZIndex + 1
        overlay.Parent = skill
        corner(overlay, 12)
        skillOverlays[slot] = overlay
    end

    local actionArea = Instance.new("Frame")
    actionArea.Name = "Actions"
    actionArea.Size = UDim2.fromScale(0.31, 0.31)
    actionArea.Position = UDim2.fromScale(0.73, 0.53)
    actionArea.BackgroundTransparency = 1
    actionArea.Parent = root
    sizeConstraint(actionArea, Vector2.new(210, 210), Vector2.new(420, 420))

    local m1Holder = Instance.new("Frame")
    m1Holder.Size = UDim2.fromScale(0.54, 0.54)
    m1Holder.Position = UDim2.fromScale(0.50, 0.53)
    m1Holder.AnchorPoint = Vector2.new(0.5, 0.5)
    m1Holder.BackgroundTransparency = 1
    m1Holder.Parent = actionArea

    local m1 = button(m1Holder, "M1", "M1")
    m1.TextSize = 22
    aspect(m1, 1)

    local function makeSmallAction(name: string, textValue: string, y: number): TextButton
        local holder = Instance.new("Frame")
        holder.Size = UDim2.fromScale(0.34, 0.20)
        holder.Position = UDim2.fromScale(0.14, y)
        holder.BackgroundTransparency = 1
        holder.Parent = actionArea
        local actionButton = button(holder, name, textValue)
        aspect(actionButton, 1.65)
        return actionButton
    end

    local sprint = makeSmallAction("Sprint", "SPRINT", 0.07)
    local block = makeSmallAction("Block", "BLOCK", 0.34)
    local dash = makeSmallAction("Dash", "DASH", 0.63)

    local special = button(root, "Special", "SPECIAL")
    special.Size = UDim2.fromScale(0.18, 0.060)
    special.Position = UDim2.fromScale(0.50, 0.925)
    special.AnchorPoint = Vector2.new(0.5, 0.5)
    sizeConstraint(special, Vector2.new(150, 42), Vector2.new(340, 70))

    local ultimate = button(root, "Ultimate", "ULTIMATE")
    ultimate.Size = UDim2.fromScale(0.15, 0.060)
    ultimate.Position = UDim2.fromScale(0.385, 0.925)
    ultimate.AnchorPoint = Vector2.new(0.5, 0.5)
    sizeConstraint(ultimate, Vector2.new(130, 42), Vector2.new(280, 70))

    local awakening = button(root, "Awakening", "AWAKEN")
    awakening.Size = UDim2.fromScale(0.15, 0.060)
    awakening.Position = UDim2.fromScale(0.615, 0.925)
    awakening.AnchorPoint = Vector2.new(0.5, 0.5)
    sizeConstraint(awakening, Vector2.new(130, 42), Vector2.new(280, 70))

    local self: HUD = setmetatable({
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
        SpecialButton = special,
        _Hints = skillHints,
        _TopButtons = {},
    } :: any

    function self:GetButton(name: string): TextButton?
        local map: {[string]: TextButton} = {
            M1 = self.M1Button,
            Dash = self.DashButton,
            Block = self.BlockButton,
            Sprint = self.SprintButton,
            Special = self.SpecialButton,
            Ultimate = self.UltimateButton,
            Awakening = self.AwakeningButton
        }
        return map[name]
    end

    function self:SetVisible(visible: boolean)
        self.Root.Visible = visible
    end

    function self:UpdateCharacter(name: string, subtitle: string, moves: {[number]: any})
        self.IdentityName.Text = name
        self.IdentityTitle.Text = subtitle

        for slot = 1, 4 do
            local move = moves[slot]
            self.SkillButtons[slot].Text = tostring(slot) .. "\n" .. (move and tostring(move.Name) or ("Skill " .. tostring(slot)))
        end
    end

    function self:UpdateHealth(healthValue: number, maxHealth: number)
        local ratio = math.clamp(healthValue / math.max(1, maxHealth), 0, 1)
        self.HealthFill.Size = UDim2.fromScale(ratio, 1)
        self.HealthText.Text = string.format(
            "%d / %d",
            math.floor(math.max(0, healthValue) + 0.5),
            math.floor(math.max(1, maxHealth) + 0.5)
        )
    end

    function self:UpdateState(combatState: string)
        self.StateText.Text = ({
            Attacking = "ATTACK",
            UsingAbility = "SKILL",
            Blocking = "BLOCK",
            Stunned = "STUNNED",
            Ragdolled = "DOWN",
            Dashing = "DASH",
            Ultimate = "ULTIMATE",
            Awakening = "AWAKEN",
            Dead = "KO"
        })[combatState] or "READY"
    end

    function self:UpdatePower(ultimateValue: number, awakeningValue: number, ultimateReady: boolean, awakeningReady: boolean)
        local value = math.max(ultimateValue, awakeningValue)
        self.MeterFill.Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1)
        self.MeterFill.BackgroundColor3 = awakeningValue > ultimateValue
            and Color3.fromRGB(255, 94, 177)
            or COLORS.Accent

        self.MeterText.Text = awakeningValue > ultimateValue
            and string.format("AWAKENING %d%%", math.floor(awakeningValue))
            or string.format("ULTIMATE %d%%", math.floor(ultimateValue))

        self.UltimateButton.Text = ultimateReady and "ULTIMATE\nREADY" or "ULTIMATE"
        self.AwakeningButton.Text = awakeningReady and "AWAKEN\nREADY" or "AWAKEN"
    end

    function self:SetCooldown(slot: number, remaining: number, total: number)
        local buttonObject = self.SkillButtons[slot]
        local cooldown = self.SkillCooldowns[slot]
        local overlay = self.SkillOverlays[slot]
        if not buttonObject or not cooldown or not overlay then
            return
        end

        if remaining <= 0 then
            cooldown.Text = "READY"
            overlay.Size = UDim2.fromScale(1, 0)
            buttonObject.BackgroundTransparency = 0.08
            return
        end

        cooldown.Text = string.format("%.1fs", remaining)
        overlay.Size = UDim2.fromScale(1, math.clamp(remaining / math.max(0.01, total), 0, 1))
        buttonObject.BackgroundTransparency = 0.22
    end

    function self:SetActionState(action: string, active: boolean)
        local object = self:GetButton(action)
        if not object then
            return
        end

        object.BackgroundColor3 = active and COLORS.ButtonPressed or COLORS.Button
        object.TextColor3 = active and COLORS.Accent or COLORS.Text
    end

    function self:RefreshInputHints()
        local preferred = UserInputService.PreferredInput
        local skillKeys = {"1", "2", "3", "4"}
        local gamepadKeys = {"RB", "Y", "D↑", "D↓"}

        for slot = 1, 4 do
            local hint = self._Hints[slot]
            if preferred == Enum.PreferredInput.Touch then
                hint.Text = ""
            elseif preferred == Enum.PreferredInput.Gamepad then
                hint.Text = gamepadKeys[slot]
            else
                hint.Text = skillKeys[slot]
            end
        end

        if preferred == Enum.PreferredInput.Gamepad then
            self.M1Button.Text = "M1\nRT"
            self.DashButton.Text = "DASH\nA"
            self.BlockButton.Text = "BLOCK\nLT"
            self.SprintButton.Text = "SPRINT\nLB"
            self.SpecialButton.Text = "SPECIAL\nX"
            GuiService.GuiNavigationEnabled = true
        elseif preferred == Enum.PreferredInput.Touch then
            self.M1Button.Text = "M1"
            self.DashButton.Text = "DASH"
            self.BlockButton.Text = "BLOCK"
            self.SprintButton.Text = "SPRINT"
            self.SpecialButton.Text = "SPECIAL"
            GuiService.GuiNavigationEnabled = false
        else
            self.M1Button.Text = "M1"
            self.DashButton.Text = "DASH\nQ"
            self.BlockButton.Text = "BLOCK\nF"
            self.SprintButton.Text = "SPRINT\nSHIFT"
            self.SpecialButton.Text = "SPECIAL\nE"
            GuiService.GuiNavigationEnabled = false
        end
    end

    self:RefreshInputHints()

    UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
        self:RefreshInputHints()
    end)

    return self
end

return HUDController
