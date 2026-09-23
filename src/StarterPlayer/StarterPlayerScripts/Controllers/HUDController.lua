--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUDConfig = require(ReplicatedStorage.Shared.UI.HUDConfig)

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
    DomainText: TextLabel,
    TargetText: TextLabel,
    ComboText: TextLabel,
    NotificationText: TextLabel,
    MeterFill: Frame,
    MeterText: TextLabel,
    UltimateButton: TextButton,
    AwakeningButton: TextButton,
    SkillButtons: {[number]: TextButton},
    SkillHints: {[number]: TextLabel},
    SkillCooldowns: {[number]: TextLabel},
    SkillOverlays: {[number]: Frame},
    M1Button: TextButton,
    DashButton: TextButton,
    BlockButton: TextButton,
    SprintButton: TextButton,
    SpecialButton: TextButton,
    PreferredInput: Enum.PreferredInput,
    SetPreferredInput: (self: HUD, preferred: Enum.PreferredInput) -> (),
    SetVisible: (self: HUD, visible: boolean) -> (),
    UpdateCharacter: (self: HUD, name: string, subtitle: string, moves: {[number]: any}) -> (),
    UpdateHealth: (self: HUD, health: number, maxHealth: number) -> (),
    UpdateState: (self: HUD, state: string) -> (),
    SetTarget: (self: HUD, targetName: string?) -> (),
    SetDomain: (self: HUD, domainName: string?) -> (),
    ShowCombo: (self: HUD, count: number) -> (),
    Notify: (self: HUD, textValue: string) -> (),
    ClearNotification: (self: HUD) -> (),
    UpdatePower: (self: HUD, ultimate: number, awakening: number, ultimateReady: boolean, awakeningReady: boolean) -> (),
    SetCooldown: (self: HUD, slot: number, remaining: number, total: number) -> (),
    SetBlocking: (self: HUD, active: boolean) -> (),
    SetSprinting: (self: HUD, active: boolean) -> ()
}

local function corner(object: GuiObject, radius: number)
    local ui = Instance.new("UICorner")
    ui.CornerRadius = UDim.new(0, radius)
    ui.Parent = object
end

local function stroke(object: GuiObject, transparency: number)
    local ui = Instance.new("UIStroke")
    ui.Thickness = 1
    ui.Color = HUDConfig.Colors.Stroke
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
    object.TextColor3 = HUDConfig.Colors.Text
    object.TextWrapped = true
    object.TextXAlignment = Enum.TextXAlignment.Center
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.Parent = parent
    return object
end

local function button(
    parent: Instance,
    name: string,
    textValue: string
): TextButton
    local object = Instance.new("TextButton")
    object.Name = name
    object.Size = UDim2.fromScale(1, 1)
    object.Text = textValue
    object.Font = Enum.Font.GothamBlack
    object.TextSize = 11
    object.TextColor3 = HUDConfig.Colors.Text
    object.BackgroundColor3 = HUDConfig.Colors.PanelSoft
    object.BackgroundTransparency = 0.08
    object.BorderSizePixel = 0
    object.AutoButtonColor = false
    object.Active = true
    object.Selectable = true
    object.Parent = parent
    corner(object, 12)
    stroke(object, 0.52)

    local constraint = Instance.new("UISizeConstraint")
    constraint.MinSize = Vector2.new(
        HUDConfig.Scale.TouchMinimumButton,
        HUDConfig.Scale.TouchMinimumButton
    )
    constraint.MaxSize = Vector2.new(120, 120)
    constraint.Parent = object

    object.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Gamepad1 then
            TweenService:Create(object, TweenInfo.new(0.06), {
                BackgroundTransparency = 0
            }):Play()
        end
    end)

    object.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Gamepad1 then
            TweenService:Create(object, TweenInfo.new(0.08), {
                BackgroundTransparency = 0.08
            }):Play()
        end
    end)

    return object
end

local function aspect(object: GuiObject, ratio: number)
    local constraint = Instance.new("UIAspectRatioConstraint")
    constraint.AspectRatio = ratio
    constraint.Parent = object
end

local function inputPreset()
    local preferred = UserInputService.PreferredInput

    if preferred == Enum.PreferredInput.Gamepad then
        return HUDConfig.Inputs.Gamepad
    end

    if preferred == Enum.PreferredInput.Touch then
        return HUDConfig.Inputs.Touch
    end

    return HUDConfig.Inputs.KeyboardAndMouse
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

    local scale = Instance.new("UIScale")
    scale.Parent = root

    local function refreshScale()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local shortAxis = math.min(viewport.X, viewport.Y)
        scale.Scale = math.clamp(
            shortAxis / HUDConfig.Scale.ReferenceShortAxis,
            HUDConfig.Scale.Minimum,
            HUDConfig.Scale.Maximum
        )
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

    local top = Instance.new("Frame")
    top.Name = "TopIdentity"
    top.Size = UDim2.fromScale(0.36, 0.082)
    top.Position = UDim2.fromScale(0.50, 0.025)
    top.AnchorPoint = Vector2.new(0.5, 0)
    top.BackgroundColor3 = HUDConfig.Colors.Panel
    top.BackgroundTransparency = 0.18
    top.BorderSizePixel = 0
    top.Parent = root
    corner(top, 13)
    stroke(top, 0.72)

    local identityName = label(
        top,
        "Potential Man",
        UDim2.fromScale(0.94, 0.48),
        UDim2.fromScale(0.03, 0.04),
        15
    )

    local identityTitle = label(
        top,
        "Shadow Potential",
        UDim2.fromScale(0.94, 0.27),
        UDim2.fromScale(0.03, 0.57),
        8
    )
    identityTitle.TextColor3 = HUDConfig.Colors.Muted

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
    healthFill.BackgroundColor3 = HUDConfig.Colors.Danger
    healthFill.BorderSizePixel = 0
    healthFill.Parent = health
    corner(healthFill, 8)

    local healthText = label(
        health,
        "100 / 100",
        UDim2.fromScale(1, 1),
        UDim2.fromScale(0, 0),
        9
    )

    local state = Instance.new("Frame")
    state.Name = "State"
    state.Size = UDim2.fromScale(0.20, 0.042)
    state.Position = UDim2.fromScale(0.50, 0.116)
    state.AnchorPoint = Vector2.new(0.5, 0)
    state.BackgroundColor3 = HUDConfig.Colors.Panel
    state.BackgroundTransparency = 0.25
    state.Parent = root
    corner(state, 8)
    stroke(state, 0.78)

    local stateText = label(
        state,
        "READY",
        UDim2.fromScale(1, 1),
        UDim2.fromScale(0, 0),
        8
    )

    local targetText = label(
        root,
        "TARGET —",
        UDim2.fromScale(0.22, 0.038),
        UDim2.fromScale(0.018, 0.165),
        8
    )
    targetText.TextXAlignment = Enum.TextXAlignment.Left
    targetText.TextColor3 = HUDConfig.Colors.Muted

    local domainText = label(
        root,
        "DOMAIN —",
        UDim2.fromScale(0.22, 0.038),
        UDim2.fromScale(0.762, 0.165),
        8
    )
    domainText.TextXAlignment = Enum.TextXAlignment.Right
    domainText.TextColor3 = HUDConfig.Colors.Muted
    domainText.Visible = false

    local comboText = label(
        root,
        "",
        UDim2.fromScale(0.24, 0.070),
        UDim2.fromScale(0.50, 0.59),
        20
    )
    comboText.AnchorPoint = Vector2.new(0.5, 0.5)
    comboText.TextColor3 = HUDConfig.Colors.Text

    local notificationText = label(
        root,
        "",
        UDim2.fromScale(0.42, 0.046),
        UDim2.fromScale(0.50, 0.65),
        9
    )
    notificationText.AnchorPoint = Vector2.new(0.5, 0.5)
    notificationText.TextColor3 = HUDConfig.Colors.Muted

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
    local skillHints: {[number]: TextLabel} = {}
    local skillCooldowns: {[number]: TextLabel} = {}
    local skillOverlays: {[number]: Frame} = {}

    for slot = 1, 4 do
        local cell = Instance.new("Frame")
        cell.Name = "SkillCell" .. tostring(slot)
        cell.BackgroundTransparency = 1
        cell.LayoutOrder = slot
        cell.Parent = skillFrame

        local skill = button(
            cell,
            "Skill" .. tostring(slot),
            tostring(slot)
        )
        skill.TextSize = 11
        aspect(skill, 1.45)
        skillButtons[slot] = skill

        local hint = label(
            skill,
            tostring(slot),
            UDim2.fromScale(0.28, 0.20),
            UDim2.fromScale(0.06, 0.05),
            8
        )
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.TextColor3 = HUDConfig.Colors.Muted
        skillHints[slot] = hint

        local cooldown = label(
            skill,
            "READY",
            UDim2.fromScale(0.88, 0.20),
            UDim2.fromScale(0.06, 0.76),
            7
        )
        cooldown.TextColor3 = HUDConfig.Colors.Muted
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
    meterFill.BackgroundColor3 = HUDConfig.Colors.Accent
    meterFill.BorderSizePixel = 0
    meterFill.Parent = meter
    corner(meterFill, 7)

    local meterText = label(
        meter,
        "ULTIMATE 0%",
        UDim2.fromScale(1, 1),
        UDim2.fromScale(0, 0),
        8
    )

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

    local blockHolder = Instance.new("Frame")
    blockHolder.Size = UDim2.fromScale(0.34, 0.20)
    blockHolder.Position = UDim2.fromScale(0.14, 0.34)
    blockHolder.BackgroundTransparency = 1
    blockHolder.Parent = actionArea
    local block = button(blockHolder, "Block", "BLOCK")

    local sprintHolder = Instance.new("Frame")
    sprintHolder.Size = UDim2.fromScale(0.34, 0.20)
    sprintHolder.Position = UDim2.fromScale(0.14, 0.07)
    sprintHolder.BackgroundTransparency = 1
    sprintHolder.Parent = actionArea
    local sprint = button(sprintHolder, "Sprint", "SPRINT")

    local special = button(root, "Special", "SPECIAL")
    special.Size = UDim2.fromScale(0.18, 0.060)
    special.Position = UDim2.fromScale(0.50, 0.925)
    special.AnchorPoint = Vector2.new(0.5, 0.5)

    local ultimate = button(root, "Ultimate", "ULTIMATE")
    ultimate.Size = UDim2.fromScale(0.15, 0.060)
    ultimate.Position = UDim2.fromScale(0.385, 0.925)
    ultimate.AnchorPoint = Vector2.new(0.5, 0.5)

    local awakening = button(root, "Awakening", "AWAKEN")
    awakening.Size = UDim2.fromScale(0.15, 0.060)
    awakening.Position = UDim2.fromScale(0.615, 0.925)
    awakening.AnchorPoint = Vector2.new(0.5, 0.5)

    local hud: HUD = setmetatable({
        Gui = gui,
        Root = root,
        IdentityName = identityName,
        IdentityTitle = identityTitle,
        HealthFill = healthFill,
        HealthText = healthText,
        StateText = stateText,
        DomainText = domainText,
        TargetText = targetText,
        ComboText = comboText,
        NotificationText = notificationText,
        MeterFill = meterFill,
        MeterText = meterText,
        UltimateButton = ultimate,
        AwakeningButton = awakening,
        SkillButtons = skillButtons,
        SkillHints = skillHints,
        SkillCooldowns = skillCooldowns,
        SkillOverlays = skillOverlays,
        M1Button = m1,
        DashButton = dash,
        BlockButton = block,
        SprintButton = sprint,
        SpecialButton = special,
        PreferredInput = UserInputService.PreferredInput
    }, HUDController)

    hud:SetPreferredInput(UserInputService.PreferredInput)

    UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
        hud:SetPreferredInput(UserInputService.PreferredInput)
    end)

    return hud
end

function HUDController.SetPreferredInput(self: HUD, preferred: Enum.PreferredInput)
    self.PreferredInput = preferred
    local preset

    if preferred == Enum.PreferredInput.Gamepad then
        preset = HUDConfig.Inputs.Gamepad
        GuiService.GuiNavigationEnabled = true
    elseif preferred == Enum.PreferredInput.Touch then
        preset = HUDConfig.Inputs.Touch
        GuiService.GuiNavigationEnabled = false
    else
        preset = HUDConfig.Inputs.KeyboardAndMouse
    end

    for slot = 1, 4 do
        self.SkillHints[slot].Text = tostring(preset.Skill[slot] or "")
    end

    self.M1Button.Text = preferred == Enum.PreferredInput.Gamepad
        and "M1\n" .. preset.M1
        or "M1"

    self.DashButton.Text = preferred == Enum.PreferredInput.Touch
        and "DASH"
        or "DASH\n" .. preset.Dash

    self.BlockButton.Text = preferred == Enum.PreferredInput.Touch
        and "BLOCK"
        or "BLOCK\n" .. preset.Block

    self.SprintButton.Text = preferred == Enum.PreferredInput.Touch
        and "SPRINT"
        or "SPRINT\n" .. preset.Sprint

    self.SpecialButton.Text = preferred == Enum.PreferredInput.Touch
        and "SPECIAL"
        or "SPECIAL\n" .. preset.Special

    self.UltimateButton.Text = preferred == Enum.PreferredInput.Touch
        and "ULTIMATE"
        or "ULTIMATE\n" .. preset.Ultimate

    self.AwakeningButton.Text = preferred == Enum.PreferredInput.Touch
        and "AWAKEN"
        or "AWAKEN\n" .. preset.Awakening
end

function HUDController.SetVisible(self: HUD, visible: boolean)
    self.Root.Visible = visible
end

function HUDController.UpdateCharacter(
    self: HUD,
    name: string,
    subtitle: string,
    moves: {[number]: any}
)
    self.IdentityName.Text = name
    self.IdentityTitle.Text = subtitle

    for slot = 1, 4 do
        local move = moves[slot]
        self.SkillButtons[slot].Text = tostring(slot) .. "\n" .. (
            move and move.Name or "Skill " .. tostring(slot)
        )
    end
end

function HUDController.UpdateHealth(
    self: HUD,
    health: number,
    maxHealth: number
)
    local ratio = math.clamp(health / math.max(1, maxHealth), 0, 1)
    self.HealthFill.Size = UDim2.fromScale(ratio, 1)
    self.HealthText.Text = string.format(
        "%d / %d",
        math.floor(math.max(0, health) + 0.5),
        math.floor(math.max(1, maxHealth) + 0.5)
    )
end

function HUDController.UpdateState(self: HUD, state: string)
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

function HUDController.SetTarget(self: HUD, targetName: string?)
    self.TargetText.Text = targetName and ("TARGET • " .. targetName) or "TARGET —"
end

function HUDController.SetDomain(self: HUD, domainName: string?)
    self.DomainText.Visible = domainName ~= nil and domainName ~= ""
    self.DomainText.Text = domainName
        and ("DOMAIN • " .. domainName)
        or "DOMAIN —"
end

function HUDController.ShowCombo(self: HUD, count: number)
    if count < 2 then
        self.ComboText.Text = ""
        return
    end

    self.ComboText.Text = tostring(count) .. " HIT"
end

function HUDController.Notify(self: HUD, textValue: string)
    self.NotificationText.Text = textValue
end

function HUDController.ClearNotification(self: HUD)
    self.NotificationText.Text = ""
end

local function inputLabel(preferred: Enum.PreferredInput, key: string): string
    local preset = if preferred == Enum.PreferredInput.Gamepad
        then HUDConfig.Inputs.Gamepad
        elseif preferred == Enum.PreferredInput.Touch
        then HUDConfig.Inputs.Touch
        else HUDConfig.Inputs.KeyboardAndMouse
    return tostring((preset :: any)[key] or "")
end

function HUDController:UpdatePower(
    self: HUD,
    ultimate: number,
    awakening: number,
    ultimateReady: boolean,
    awakeningReady: boolean
)
    local value = math.max(ultimate, awakening)

    self.MeterFill.Size = UDim2.fromScale(
        math.clamp(value / 100, 0, 1),
        1
    )

    local useAwakening = awakening > ultimate
    self.MeterFill.BackgroundColor3 = useAwakening
        and Color3.fromRGB(255, 94, 177)
        or HUDConfig.Colors.Accent

    self.MeterText.Text = useAwakening
        and string.format("AWAKENING %d%%", math.floor(awakening))
        or string.format("ULTIMATE %d%%", math.floor(ultimate))

    self.UltimateButton.Text = ultimateReady
        and "ULTIMATE\nREADY"
        or "ULTIMATE\n" .. inputLabel(self.PreferredInput, "Ultimate")

    self.AwakeningButton.Text = awakeningReady
        and "AWAKEN\nREADY"
        or "AWAKEN\n" .. inputLabel(self.PreferredInput, "Awakening")
end

function HUDController.SetCooldown(
    self: HUD,
    slot: number,
    remaining: number,
    total: number
)
    local buttonObject = self.SkillButtons[slot]
    local cooldown = self.SkillCooldowns[slot]
    local overlay = self.SkillOverlays[slot]

    if remaining <= 0 then
        cooldown.Text = "READY"
        overlay.Size = UDim2.fromScale(1, 0)
        buttonObject.BackgroundTransparency = 0.08
        return
    end

    cooldown.Text = string.format("%.1fs", remaining)

    local ratio = math.clamp(
        remaining / math.max(0.01, total),
        0,
        1
    )

    overlay.Size = UDim2.fromScale(1, ratio)
    buttonObject.BackgroundTransparency = 0.22
end

function HUDController.SetActionState(self: HUD, action: "Block" | "Sprint", active: boolean)
    if action == "Block" then
        self:SetBlocking(active)
    else
        self:SetSprinting(active)
    end
end

function HUDController.SetBlocking(self: HUD, active: boolean)
    self.BlockButton.Text = active and "BLOCKING" or "BLOCK"
end

function HUDController.SetSprinting(self: HUD, active: boolean)
    self.SprintButton.Text = active and "SPRINTING" or "SPRINT"
end

return HUDController
