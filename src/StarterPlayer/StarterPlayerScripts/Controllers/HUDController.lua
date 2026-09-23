--!strict

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.HUDTheme)
local Platform = require(script.Parent.HUDPlatform)

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
    CharacterButton: TextButton,
    EmoteButton: TextButton,
    MenuButton: TextButton,
    OwnerButton: TextButton
}

local HUDController = {}
HUDController.__index = HUDController

local function corner(object: GuiObject, radius: number)
    local ui = Instance.new("UICorner")
    ui.CornerRadius = UDim.new(0, radius)
    ui.Parent = object
end

local function stroke(object: GuiObject, transparency: number?)
    local ui = Instance.new("UIStroke")
    ui.Thickness = 1
    ui.Transparency = transparency or 0.55
    ui.Parent = object
end

local function aspect(object: GuiObject, ratio: number)
    local ui = Instance.new("UIAspectRatioConstraint")
    ui.AspectRatio = ratio
    ui.Parent = object
end

local function label(parent: Instance, textValue: string, size: UDim2, position: UDim2, textSize: number): TextLabel
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Size = size
    object.Position = position
    object.Text = textValue
    object.TextColor3 = Theme.Colors.Text
    object.Font = Enum.Font.GothamBold
    object.TextSize = textSize
    object.TextWrapped = true
    object.TextXAlignment = Enum.TextXAlignment.Center
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.Parent = parent
    return object
end

local function makeButton(parent: Instance, name: string, textValue: string): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.fromScale(1, 1)
    button.BackgroundColor3 = Theme.Colors.Surface
    button.BackgroundTransparency = 0.08
    button.BorderSizePixel = 0
    button.Text = textValue
    button.TextColor3 = Theme.Colors.Text
    button.Font = Enum.Font.GothamBlack
    button.TextSize = 11
    button.AutoButtonColor = false
    button.Active = true
    button.Selectable = true
    button.Parent = parent
    corner(button, Theme.Radius.Medium)
    stroke(button)
    return button
end

local function pressFeedback(button: GuiButton)
    button.Activated:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.07), {
            BackgroundColor3 = Theme.Colors.SurfacePressed
        }):Play()

        task.delay(0.09, function()
            if button.Parent then
                TweenService:Create(button, TweenInfo.new(0.11), {
                    BackgroundColor3 = Theme.Colors.Surface
                }):Play()
            end
        end)
    end)
end

local function safeScale(root: Frame)
    local scale = Instance.new("UIScale")
    scale.Parent = root

    local function update()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local shortAxis = math.min(viewport.X, viewport.Y)
        scale.Scale = math.clamp(shortAxis / 720, 0.72, 1.08)
    end

    update()

    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
    end

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(update)

    return scale
end

local function sectionFrame(root: Frame, name: string): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.BackgroundTransparency = 1
    frame.Parent = root
    return frame
end

function HUDController.new(): HUD
    local existing = player.PlayerGui:FindFirstChild("CursedCollisionCombatHUD")
    if existing then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CursedCollisionCombatHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 5
    gui.IgnoreGuiInset = false
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player.PlayerGui

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = gui
    safeScale(root)

    local topLeft = sectionFrame(root, "TopLeft")
    topLeft.Size = UDim2.fromScale(0.37, 0.065)
    topLeft.Position = UDim2.fromScale(0.018, 0.018)

    local characterCell = Instance.new("Frame")
    characterCell.Size = UDim2.fromScale(0.30, 1)
    characterCell.BackgroundTransparency = 1
    characterCell.Parent = topLeft
    local characterButton = makeButton(characterCell, "CharacterButton", "CHARACTERS")
    pressFeedback(characterButton)

    local emoteCell = Instance.new("Frame")
    emoteCell.Size = UDim2.fromScale(0.27, 1)
    emoteCell.Position = UDim2.fromScale(0.33, 0)
    emoteCell.BackgroundTransparency = 1
    emoteCell.Parent = topLeft
    local emoteButton = makeButton(emoteCell, "EmoteButton", "EMOTES")
    pressFeedback(emoteButton)

    local topRight = sectionFrame(root, "TopRight")
    topRight.Size = UDim2.fromScale(0.37, 0.065)
    topRight.Position = UDim2.fromScale(0.612, 0.018)

    local ownerCell = Instance.new("Frame")
    ownerCell.Size = UDim2.fromScale(0.28, 1)
    ownerCell.BackgroundTransparency = 1
    ownerCell.Parent = topRight
    local ownerButton = makeButton(ownerCell, "OwnerButton", "OWNER")
    ownerButton.TextColor3 = Theme.Colors.Warning
    ownerButton.Visible = false
    pressFeedback(ownerButton)

    local menuCell = Instance.new("Frame")
    menuCell.Size = UDim2.fromScale(0.28, 1)
    menuCell.Position = UDim2.fromScale(0.72, 0)
    menuCell.BackgroundTransparency = 1
    menuCell.Parent = topRight
    local menuButton = makeButton(menuCell, "MenuButton", "MENU")
    pressFeedback(menuButton)

    local identity = Instance.new("Frame")
    identity.Name = "Identity"
    identity.Size = UDim2.fromScale(0.28, 0.078)
    identity.Position = UDim2.fromScale(0.50, 0.018)
    identity.AnchorPoint = Vector2.new(0.5, 0)
    identity.BackgroundColor3 = Theme.Colors.Panel
    identity.BackgroundTransparency = 0.13
    identity.BorderSizePixel = 0
    identity.Parent = root
    corner(identity, Theme.Radius.Medium)
    stroke(identity, 0.70)

    local identityName = label(identity, "Potential Man", UDim2.fromScale(0.92, 0.50), UDim2.fromScale(0.04, 0.06), 14)
    local identityTitle = label(identity, "", UDim2.fromScale(0.92, 0.28), UDim2.fromScale(0.04, 0.57), 8)
    identityTitle.TextColor3 = Theme.Colors.Muted

    local health = Instance.new("Frame")
    health.Name = "Health"
    health.Size = UDim2.fromScale(0.31, 0.044)
    health.Position = UDim2.fromScale(0.018, 0.105)
    health.BackgroundColor3 = Theme.Colors.Surface
    health.BorderSizePixel = 0
    health.Parent = root
    corner(health, Theme.Radius.Small)
    stroke(health, 0.76)

    local healthFill = Instance.new("Frame")
    healthFill.Name = "Fill"
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = Theme.Colors.Health
    healthFill.BorderSizePixel = 0
    healthFill.Parent = health
    corner(healthFill, Theme.Radius.Small)

    local healthText = label(health, "100 / 100", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 9)

    local stateFrame = Instance.new("Frame")
    stateFrame.Name = "State"
    stateFrame.Size = UDim2.fromScale(0.20, 0.040)
    stateFrame.Position = UDim2.fromScale(0.50, 0.108)
    stateFrame.AnchorPoint = Vector2.new(0.5, 0)
    stateFrame.BackgroundColor3 = Theme.Colors.Panel
    stateFrame.BackgroundTransparency = 0.20
    stateFrame.Parent = root
    corner(stateFrame, Theme.Radius.Small)
    stroke(stateFrame, 0.78)

    local stateText = label(stateFrame, "READY", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 8)

    local power = Instance.new("Frame")
    power.Name = "Power"
    power.Size = UDim2.fromScale(0.60, 0.044)
    power.Position = UDim2.fromScale(0.50, 0.707)
    power.AnchorPoint = Vector2.new(0.5, 0.5)
    power.BackgroundColor3 = Theme.Colors.Surface
    power.BorderSizePixel = 0
    power.Parent = root
    corner(power, Theme.Radius.Small)
    stroke(power, 0.76)

    local meterFill = Instance.new("Frame")
    meterFill.Name = "Fill"
    meterFill.Size = UDim2.fromScale(0, 1)
    meterFill.BackgroundColor3 = Theme.Colors.Ultimate
    meterFill.BorderSizePixel = 0
    meterFill.Parent = power
    corner(meterFill, Theme.Radius.Small)

    local meterText = label(power, "ULTIMATE 0%", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 8)

    local skillFrame = sectionFrame(root, "Skills")
    skillFrame.Size = UDim2.fromScale(0.74, 0.13)
    skillFrame.Position = UDim2.fromScale(0.50, 0.805)
    skillFrame.AnchorPoint = Vector2.new(0.5, 0.5)

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.235, 0, 0.89, 0)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 0)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = skillFrame

    local skillButtons: {[number]: TextButton} = {}
    local skillCooldowns: {[number]: TextLabel} = {}
    local skillOverlays: {[number]: Frame} = {}

    for slot = 1, 4 do
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = slot
        holder.Parent = skillFrame

        local button = makeButton(holder, "Skill" .. tostring(slot), tostring(slot))
        aspect(button, 1.46)
        pressFeedback(button)

        local hint = label(button, tostring(slot), UDim2.fromScale(0.23, 0.22), UDim2.fromScale(0.06, 0.05), 8)
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.TextColor3 = Theme.Colors.Muted

        local cooldown = label(button, "READY", UDim2.fromScale(0.86, 0.22), UDim2.fromScale(0.07, 0.76), 7)
        cooldown.TextColor3 = Theme.Colors.Muted

        local overlay = Instance.new("Frame")
        overlay.Name = "Cooldown"
        overlay.Size = UDim2.fromScale(1, 0)
        overlay.Position = UDim2.fromScale(0, 1)
        overlay.AnchorPoint = Vector2.new(0, 1)
        overlay.BackgroundColor3 = Theme.Colors.Background
        overlay.BackgroundTransparency = 0.30
        overlay.BorderSizePixel = 0
        overlay.ZIndex = button.ZIndex + 1
        overlay.Parent = button
        corner(overlay, Theme.Radius.Medium)

        skillButtons[slot] = button
        skillCooldowns[slot] = cooldown
        skillOverlays[slot] = overlay
    end

    local actionArea = sectionFrame(root, "Actions")
    actionArea.Size = UDim2.fromScale(0.33, 0.32)
    actionArea.Position = UDim2.fromScale(0.70, 0.525)

    local m1Holder = Instance.new("Frame")
    m1Holder.Size = UDim2.fromScale(0.58, 0.58)
    m1Holder.Position = UDim2.fromScale(0.52, 0.53)
    m1Holder.AnchorPoint = Vector2.new(0.5, 0.5)
    m1Holder.BackgroundTransparency = 1
    m1Holder.Parent = actionArea

    local m1 = makeButton(m1Holder, "M1", Platform:Hint("M1"))
    m1.TextSize = 21
    aspect(m1, 1)
    pressFeedback(m1)

    local function actionButton(name: string, action: string, x: number, y: number): TextButton
        local holder = Instance.new("Frame")
        holder.Size = UDim2.fromScale(0.34, 0.20)
        holder.Position = UDim2.fromScale(x, y)
        holder.BackgroundTransparency = 1
        holder.Parent = actionArea

        local button = makeButton(holder, name, Platform:Hint(action))
        pressFeedback(button)
        return button
    end

    local dash = actionButton("Dash", "Dash", 0.06, 0.63)
    local block = actionButton("Block", "Block", 0.06, 0.36)
    local sprint = actionButton("Sprint", "Sprint", 0.06, 0.09)

    local special = makeButton(root, "Special", Platform:Hint("Special"))
    special.Size = UDim2.fromScale(0.17, 0.058)
    special.Position = UDim2.fromScale(0.50, 0.925)
    special.AnchorPoint = Vector2.new(0.5, 0.5)
    special.TextSize = 10
    pressFeedback(special)

    local ultimate = makeButton(root, "Ultimate", Platform:Hint("Ultimate"))
    ultimate.Size = UDim2.fromScale(0.15, 0.058)
    ultimate.Position = UDim2.fromScale(0.385, 0.925)
    ultimate.AnchorPoint = Vector2.new(0.5, 0.5)
    ultimate.TextSize = 10
    pressFeedback(ultimate)

    local awakening = makeButton(root, "Awakening", Platform:Hint("Awakening"))
    awakening.Size = UDim2.fromScale(0.15, 0.058)
    awakening.Position = UDim2.fromScale(0.615, 0.925)
    awakening.AnchorPoint = Vector2.new(0.5, 0.5)
    awakening.TextSize = 10
    pressFeedback(awakening)

    local controller = setmetatable({
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
        CharacterButton = characterButton,
        EmoteButton = emoteButton,
        MenuButton = menuButton,
        OwnerButton = ownerButton
    }, HUDController) :: any

    controller:RefreshPlatform()

    Platform:Refresh(function()
        controller:RefreshPlatform()
    end)

    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.AutoSelectGuiEnabled = true
    end

    UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
        GuiService.GuiNavigationEnabled = UserInputService.PreferredInput == Enum.PreferredInput.Gamepad

        if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
            GuiService.AutoSelectGuiEnabled = true
            GuiService.SelectedObject = controller.M1Button
        end
    end)

    return controller
end

function HUDController:RefreshPlatform(self: HUD)
    local platform = Platform:Get()

    self.M1Button.Text = Platform:Hint("M1")
    self.DashButton.Text = Platform:Hint("Dash")
    self.BlockButton.Text = Platform:Hint("Block")
    self.SprintButton.Text = Platform:Hint("Sprint")
    self.SpecialButton.Text = Platform:Hint("Special")
    self.UltimateButton.Text = Platform:Hint("Ultimate")
    self.AwakeningButton.Text = Platform:Hint("Awakening")

    local scale = self.Root:FindFirstChildOfClass("UIScale")
    local actionArea = self.Root:FindFirstChild("Actions")
    local skillFrame = self.Root:FindFirstChild("Skills")

    if scale and actionArea and skillFrame then
        if platform == "Touch" then
            scale.Scale = math.max(scale.Scale, 0.76)
        elseif platform == "Gamepad" then
            GuiService.GuiNavigationEnabled = true
        end
    end
end

function HUDController:SetVisible(self: HUD, visible: boolean)
    self.Root.Visible = visible
end

function HUDController:SetOwnerVisible(self: HUD, visible: boolean)
    self.OwnerButton.Visible = visible
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
    self.HealthText.Text = string.format(
        "%d / %d",
        math.floor(math.max(0, health) + 0.5),
        math.floor(math.max(1, maxHealth) + 0.5)
    )
end

function HUDController:UpdateState(self: HUD, state: string)
    self.StateText.Text = ({
        Attacking = "ATTACK",
        UsingAbility = "SKILL",
        Blocking = "BLOCK",
        Stunned = "STUNNED",
        Ragdolled = "DOWN",
        Dashing = "DASH",
        Ultimate = "ULTIMATE",
        Awakening = "AWAKEN"
    })[state] or "READY"
end

function HUDController:UpdatePower(
    self: HUD,
    ultimate: number,
    awakening: number,
    ultimateReady: boolean,
    awakeningReady: boolean
)
    local value = math.max(ultimate, awakening)
    self.MeterFill.Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1)

    if awakening > ultimate then
        self.MeterText.Text = string.format("AWAKENING %d%%", math.floor(awakening))
        self.MeterFill.BackgroundColor3 = Theme.Colors.Awakening
    else
        self.MeterText.Text = string.format("ULTIMATE %d%%", math.floor(ultimate))
        self.MeterFill.BackgroundColor3 = Theme.Colors.Ultimate
    end

    self.UltimateButton.Text = ultimateReady and (Platform:Hint("Ultimate") .. " READY") or Platform:Hint("Ultimate")
    self.AwakeningButton.Text = awakeningReady and (Platform:Hint("Awakening") .. " READY") or Platform:Hint("Awakening")
end

function HUDController:SetCooldown(self: HUD, slot: number, remaining: number, total: number)
    local button = self.SkillButtons[slot]
    local cooldown = self.SkillCooldowns[slot]
    local overlay = self.SkillOverlays[slot]

    if remaining <= 0 then
        cooldown.Text = "READY"
        overlay.Size = UDim2.fromScale(1, 0)
        button.BackgroundTransparency = 0.08
        return
    end

    cooldown.Text = string.format("%.1fs", remaining)
    overlay.Size = UDim2.fromScale(
        1,
        math.clamp(remaining / math.max(0.01, total), 0, 1)
    )
    button.BackgroundTransparency = 0.22
end

return HUDController
