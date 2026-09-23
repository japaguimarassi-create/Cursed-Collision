--!strict

local Theme = require(script.Parent.HUDTheme)
local Platform = require(script.Parent.HUDPlatform)
local Widgets = require(script.Parent.HUDWidgets)
local Actions = require(script.Parent.HUDActionBus)

local View = {}

local function section(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    return frame
end

local function actionButton(parent: Instance, name: string, action: string, size: UDim2, position: UDim2): TextButton
    local holder = Instance.new("Frame")
    holder.Name = name .. "Holder"
    holder.Size = size
    holder.Position = position
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local button = Widgets.Button(holder, name, Platform:Hint(name))
    button.Activated:Connect(function()
        Actions:Emit(action :: any)
    end)
    return button
end

function View.Create(root: Frame): any
    local topLeft = section(root, "TopLeft", UDim2.fromScale(0.34, 0.064), UDim2.fromScale(0.018, 0.018))

    local characters = Widgets.Button(topLeft, "Characters", "CHARACTERS")
    characters.Size = UDim2.fromScale(0.46, 1)
    characters.Activated:Connect(function()
        root:SetAttribute("OpenCharacterMenu", true)
    end)

    local emotes = Widgets.Button(topLeft, "Emotes", "EMOTES")
    emotes.Size = UDim2.fromScale(0.46, 1)
    emotes.Position = UDim2.fromScale(0.54, 0)
    emotes.Activated:Connect(function()
        root:SetAttribute("OpenEmoteMenu", true)
    end)

    local menu = Widgets.Button(root, "Menu", "MENU")
    menu.Size = UDim2.fromScale(0.12, 0.064)
    menu.Position = UDim2.fromScale(0.862, 0.018)
    menu.Activated:Connect(function()
        root:SetAttribute("OpenMainMenu", true)
    end)

    local identity = Instance.new("Frame")
    identity.Size = UDim2.fromScale(0.28, 0.078)
    identity.Position = UDim2.fromScale(0.50, 0.018)
    identity.AnchorPoint = Vector2.new(0.5, 0)
    identity.BackgroundColor3 = Theme.Colors.Panel
    identity.BackgroundTransparency = 0.12
    identity.BorderSizePixel = 0
    identity.Parent = root
    Widgets.Corner(identity, Theme.Radius.Medium)
    Widgets.Stroke(identity, 0.70)

    local identityName = Widgets.Label(identity, "Potential Man", UDim2.fromScale(0.92, 0.48), UDim2.fromScale(0.04, 0.04), 14)
    local identityTitle = Widgets.Label(identity, "", UDim2.fromScale(0.92, 0.30), UDim2.fromScale(0.04, 0.57), 8)
    identityTitle.TextColor3 = Theme.Colors.Muted

    local health = Instance.new("Frame")
    health.Size = UDim2.fromScale(0.31, 0.044)
    health.Position = UDim2.fromScale(0.018, 0.105)
    health.BackgroundColor3 = Theme.Colors.Surface
    health.BorderSizePixel = 0
    health.Parent = root
    Widgets.Corner(health, Theme.Radius.Small)
    Widgets.Stroke(health, 0.76)

    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = Theme.Colors.Health
    healthFill.BorderSizePixel = 0
    healthFill.Parent = health
    Widgets.Corner(healthFill, Theme.Radius.Small)

    local healthText = Widgets.Label(health, "100 / 100", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 9)

    local state = Instance.new("Frame")
    state.Size = UDim2.fromScale(0.20, 0.040)
    state.Position = UDim2.fromScale(0.50, 0.108)
    state.AnchorPoint = Vector2.new(0.5, 0)
    state.BackgroundColor3 = Theme.Colors.Panel
    state.BackgroundTransparency = 0.20
    state.Parent = root
    Widgets.Corner(state, Theme.Radius.Small)
    Widgets.Stroke(state, 0.78)
    local stateText = Widgets.Label(state, "READY", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 8)

    local power = Instance.new("Frame")
    power.Size = UDim2.fromScale(0.60, 0.044)
    power.Position = UDim2.fromScale(0.50, 0.704)
    power.AnchorPoint = Vector2.new(0.5, 0.5)
    power.BackgroundColor3 = Theme.Colors.Surface
    power.BorderSizePixel = 0
    power.Parent = root
    Widgets.Corner(power, Theme.Radius.Small)
    Widgets.Stroke(power, 0.76)

    local meterFill = Instance.new("Frame")
    meterFill.Size = UDim2.fromScale(0, 1)
    meterFill.BackgroundColor3 = Theme.Colors.Ultimate
    meterFill.BorderSizePixel = 0
    meterFill.Parent = power
    Widgets.Corner(meterFill, Theme.Radius.Small)

    local meterText = Widgets.Label(power, "ULTIMATE 0%", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 8)

    local skills = section(root, "Skills", UDim2.fromScale(0.74, 0.132), UDim2.fromScale(0.50, 0.805))
    skills.AnchorPoint = Vector2.new(0.5, 0.5)

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.235, 0, 0.90, 0)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 0)
    grid.Parent = skills

    local skillButtons: {[number]: TextButton} = {}
    local skillCooldowns: {[number]: TextLabel} = {}
    local skillOverlays: {[number]: Frame} = {}

    for slot = 1, 4 do
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = slot
        holder.Parent = skills

        local button = Widgets.Button(holder, "Skill" .. tostring(slot), tostring(slot))
        local key = Widgets.Label(button, tostring(slot), UDim2.fromScale(0.22, 0.22), UDim2.fromScale(0.06, 0.05), 8)
        key.TextXAlignment = Enum.TextXAlignment.Left
        key.TextColor3 = Theme.Colors.Muted

        local cooldown = Widgets.Label(button, "READY", UDim2.fromScale(0.86, 0.22), UDim2.fromScale(0.07, 0.76), 7)
        cooldown.TextColor3 = Theme.Colors.Muted

        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.fromScale(1, 0)
        overlay.Position = UDim2.fromScale(0, 1)
        overlay.AnchorPoint = Vector2.new(0, 1)
        overlay.BackgroundColor3 = Theme.Colors.Background
        overlay.BackgroundTransparency = 0.28
        overlay.BorderSizePixel = 0
        overlay.ZIndex = button.ZIndex + 1
        overlay.Parent = button
        Widgets.Corner(overlay, Theme.Radius.Medium)

        button.Activated:Connect(function()
            Actions:Emit(("Skill" .. tostring(slot)) :: any)
        end)

        skillButtons[slot] = button
        skillCooldowns[slot] = cooldown
        skillOverlays[slot] = overlay
    end

    local actions = section(root, "Actions", UDim2.fromScale(0.33, 0.34), UDim2.fromScale(0.69, 0.50))
    local m1 = actionButton(actions, "M1", "M1", UDim2.fromScale(0.52, 0.52), UDim2.fromScale(0.46, 0.42))
    m1.AnchorPoint = Vector2.new(0.5, 0.5)
    m1.TextSize = 21

    local dash = actionButton(actions, "Dash", "Dash", UDim2.fromScale(0.32, 0.20), UDim2.fromScale(0.03, 0.65))
    local block = actionButton(actions, "Block", "BlockToggle", UDim2.fromScale(0.32, 0.20), UDim2.fromScale(0.03, 0.38))
    local sprint = actionButton(actions, "Sprint", "SprintToggle", UDim2.fromScale(0.32, 0.20), UDim2.fromScale(0.03, 0.11))

    local special = actionButton(root, "Special", "Special", UDim2.fromScale(0.17, 0.058), UDim2.fromScale(0.50, 0.924))
    special.AnchorPoint = Vector2.new(0.5, 0.5)

    local ultimate = actionButton(root, "Ultimate", "Ultimate", UDim2.fromScale(0.15, 0.058), UDim2.fromScale(0.385, 0.924))
    ultimate.AnchorPoint = Vector2.new(0.5, 0.5)

    local awakening = actionButton(root, "Awakening", "Awakening", UDim2.fromScale(0.15, 0.058), UDim2.fromScale(0.615, 0.924))
    awakening.AnchorPoint = Vector2.new(0.5, 0.5)

    return {
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
    }
end

function View.UpdateCharacter(view: any, name: string, subtitle: string, moves: {[number]: any})
    view.IdentityName.Text = name
    view.IdentityTitle.Text = subtitle
    for slot = 1, 4 do
        local move = moves[slot]
        view.SkillButtons[slot].Text = tostring(slot) .. "\n" .. (move and move.Name or ("Skill " .. tostring(slot)))
    end
end

function View.UpdateHealth(view: any, health: number, maxHealth: number)
    local ratio = math.clamp(health / math.max(1, maxHealth), 0, 1)
    view.HealthFill.Size = UDim2.fromScale(ratio, 1)
    view.HealthText.Text = string.format("%d / %d", math.floor(math.max(0, health) + 0.5), math.floor(math.max(1, maxHealth) + 0.5))
end

function View.UpdateState(view: any, state: string)
    view.StateText.Text = ({
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

function View.UpdatePower(view: any, ultimate: number, awakening: number, ultimateReady: boolean, awakeningReady: boolean)
    local value = math.max(ultimate, awakening)
    view.MeterFill.Size = UDim2.fromScale(math.clamp(value / 100, 0, 1))
    view.MeterFill.BackgroundColor3 = if awakening > ultimate then Theme.Colors.Awakening else Theme.Colors.Ultimate
    view.MeterText.Text = if awakening > ultimate then string.format("AWAKENING %d%%", math.floor(awakening)) else string.format("ULTIMATE %d%%", math.floor(ultimate))
    view.UltimateButton.Text = if ultimateReady then "ULT READY" else Platform:Hint("Ultimate")
    view.AwakeningButton.Text = if awakeningReady then "AWK READY" else Platform:Hint("Awakening")
end

function View.SetCooldown(view: any, slot: number, remaining: number, total: number)
    local button = view.SkillButtons[slot]
    local cooldown = view.SkillCooldowns[slot]
    local overlay = view.SkillOverlays[slot]
    if remaining <= 0 then
        cooldown.Text = "READY"
        overlay.Size = UDim2.fromScale(1, 0)
        button.BackgroundTransparency = 0.08
        return
    end
    cooldown.Text = string.format("%.1fs", remaining)
    overlay.Size = UDim2.fromScale(1, math.clamp(remaining / math.max(0.01, total), 0, 1))
    button.BackgroundTransparency = 0.22
end

function View.RefreshPlatform(view: any)
    view.M1Button.Text = Platform:Hint("M1")
    view.DashButton.Text = Platform:Hint("Dash")
    view.BlockButton.Text = Platform:Hint("Block")
    view.SprintButton.Text = Platform:Hint("Sprint")
    view.SpecialButton.Text = Platform:Hint("Special")
end

return View
