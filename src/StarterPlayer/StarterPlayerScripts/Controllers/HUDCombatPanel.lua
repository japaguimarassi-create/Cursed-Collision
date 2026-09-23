--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)
local HUDCombatPanel = {}
HUDCombatPanel.__index = HUDCombatPanel

type Core = any

function HUDCombatPanel.new(core: Core)
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local combatAction = remotes:WaitForChild("CombatAction")
    local movementRemote = remotes:WaitForChild("MovementRemote")

    local root = Instance.new("Frame")
    root.Name = "Combat"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = core.Root

    local identity = Instance.new("Frame")
    identity.Name = "Identity"
    identity.Size = UDim2.fromScale(0.31, 0.088)
    identity.Position = UDim2.fromScale(0.50, 0.026)
    identity.AnchorPoint = Vector2.new(0.5, 0)
    identity.BackgroundColor3 = core.Palette.Surface
    identity.BackgroundTransparency = 0.14
    identity.BorderSizePixel = 0
    identity.Parent = root

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 13)
    corner.Parent = identity

    local stroke = Instance.new("UIStroke")
    stroke.Color = core.Palette.Accent
    stroke.Transparency = 0.66
    stroke.Parent = identity

    local name = core:Label(identity, "Name", "Potential Man")
    name.Size = UDim2.fromScale(0.90, 0.46)
    name.Position = UDim2.fromScale(0.05, 0.07)
    name.Font = Enum.Font.GothamBlack
    name.TextSize = 14

    local subtitle = core:Label(identity, "Subtitle", "Shadow Potential")
    subtitle.Size = UDim2.fromScale(0.90, 0.24)
    subtitle.Position = UDim2.fromScale(0.05, 0.58)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 8
    subtitle.TextColor3 = core.Palette.Muted

    local health = Instance.new("Frame")
    health.Name = "Health"
    health.Size = UDim2.fromScale(0.31, 0.038)
    health.Position = UDim2.fromScale(0.020, 0.122)
    health.BackgroundColor3 = core.Palette.Surface3
    health.BorderSizePixel = 0
    health.Parent = root

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 8)
    hc.Parent = health

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = core.Palette.Health
    fill.BorderSizePixel = 0
    fill.Parent = health
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 8)
    fc.Parent = fill

    local healthText = core:Label(health, "Value", "100 / 100")
    healthText.TextSize = 8

    local state = core:Label(root, "State", "READY")
    state.Size = UDim2.fromScale(0.18, 0.035)
    state.Position = UDim2.fromScale(0.50, 0.120)
    state.AnchorPoint = Vector2.new(0.5, 0)
    state.TextColor3 = core.Palette.Muted
    state.TextSize = 8

    local meter = Instance.new("Frame")
    meter.Name = "UltimateMeter"
    meter.Size = UDim2.fromScale(0.56, 0.036)
    meter.Position = UDim2.fromScale(0.50, 0.710)
    meter.AnchorPoint = Vector2.new(0.5, 0.5)
    meter.BackgroundColor3 = core.Palette.Surface3
    meter.BorderSizePixel = 0
    meter.Parent = root

    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 8)
    mc.Parent = meter

    local meterFill = Instance.new("Frame")
    meterFill.Name = "Fill"
    meterFill.Size = UDim2.fromScale(0, 1)
    meterFill.BackgroundColor3 = core.Palette.Accent
    meterFill.BorderSizePixel = 0
    meterFill.Parent = meter

    local mfc = Instance.new("UICorner")
    mfc.CornerRadius = UDim.new(0, 8)
    mfc.Parent = meterFill

    local meterText = core:Label(meter, "Value", "ULTIMATE 0%")
    meterText.TextSize = 8

    local skills = Instance.new("Frame")
    skills.Name = "Skills"
    skills.Size = UDim2.fromScale(0.62, 0.14)
    skills.Position = UDim2.fromScale(0.50, 0.815)
    skills.AnchorPoint = Vector2.new(0.5, 0.5)
    skills.BackgroundTransparency = 1
    skills.Parent = root

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.235, 0, 0.92, 0)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 0)
    grid.Parent = skills

    local skillButtons: {[number]: TextButton} = {}
    local cooldownLabels: {[number]: TextLabel} = {}

    for slot = 1, 4 do
        local b = core:Button(skills, "Skill" .. slot, tostring(slot))
        b.LayoutOrder = slot
        local key = core:Label(b, "Key", tostring(slot))
        key.Size = UDim2.fromScale(0.23, 0.22)
        key.Position = UDim2.fromScale(0.05, 0.03)
        key.TextXAlignment = Enum.TextXAlignment.Left
        key.TextSize = 8
        key.TextColor3 = core.Palette.Muted

        local cooldown = core:Label(b, "Cooldown", "READY")
        cooldown.Size = UDim2.fromScale(0.82, 0.20)
        cooldown.Position = UDim2.fromScale(0.09, 0.75)
        cooldown.TextSize = 7
        cooldown.TextColor3 = core.Palette.Muted

        skillButtons[slot] = b
        cooldownLabels[slot] = cooldown
    end

    local actions = Instance.new("Frame")
    actions.Name = "Actions"
    actions.Size = UDim2.fromScale(0.30, 0.31)
    actions.Position = UDim2.fromScale(0.725, 0.54)
    actions.BackgroundTransparency = 1
    actions.Parent = root

    local m1 = core:Button(actions, "M1", "M1")
    m1.Size = UDim2.fromScale(0.52, 0.52)
    m1.Position = UDim2.fromScale(0.58, 0.52)
    m1.AnchorPoint = Vector2.new(0.5, 0.5)
    m1.TextSize = 20

    local dash = core:Button(actions, "Dash", "DASH")
    dash.Size = UDim2.fromScale(0.34, 0.19)
    dash.Position = UDim2.fromScale(0.15, 0.64)
    dash.AnchorPoint = Vector2.new(0.5, 0.5)

    local block = core:Button(actions, "Block", "BLOCK")
    block.Size = UDim2.fromScale(0.34, 0.19)
    block.Position = UDim2.fromScale(0.15, 0.37)
    block.AnchorPoint = Vector2.new(0.5, 0.5)

    local sprint = core:Button(actions, "Sprint", "SPRINT")
    sprint.Size = UDim2.fromScale(0.34, 0.19)
    sprint.Position = UDim2.fromScale(0.15, 0.10)
    sprint.AnchorPoint = Vector2.new(0.5, 0.5)

    local special = core:Button(root, "Special", "SPECIAL")
    special.Size = UDim2.fromScale(0.18, 0.060)
    special.Position = UDim2.fromScale(0.50, 0.931)
    special.AnchorPoint = Vector2.new(0.5, 0.5)

    local ultimate = core:Button(root, "Ultimate", "ULTIMATE")
    ultimate.Size = UDim2.fromScale(0.145, 0.060)
    ultimate.Position = UDim2.fromScale(0.375, 0.931)
    ultimate.AnchorPoint = Vector2.new(0.5, 0.5)

    local awakening = core:Button(root, "Awakening", "AWAKEN")
    awakening.Size = UDim2.fromScale(0.145, 0.060)
    awakening.Position = UDim2.fromScale(0.625, 0.931)
    awakening.AnchorPoint = Vector2.new(0.5, 0.5)

    local cooldownUntil: {[string]: number} = {}

    local function fire(action: string, payload: any?)
        if player:GetAttribute("CCHUD_MenuOpen") == true
            or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
            or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
            or player:GetAttribute("CCHUD_OwnerPanelOpen") == true then
            return
        end
        combatAction:FireServer(action, payload)
    end

    local function localCooldown(key: string, duration: number)
        cooldownUntil[key] = os.clock() + duration
    end

    local function bindButton(button: TextButton, action: string, payloadProvider: (() -> any)?)
        button.Activated:Connect(function()
            local duration = if action == "M1"
                then 0.20
                elseif action == "Dash"
                then 0.78
                elseif action == "Special"
                then 0.55
                else 0

            if duration > 0 and (cooldownUntil[action] or 0) > os.clock() then
                return
            end

            if duration > 0 then
                localCooldown(action, duration)
            end

            fire(action, if payloadProvider then payloadProvider() else nil)
        end)
    end

    bindButton(m1, "M1", nil)
    bindButton(dash, "Dash", function()
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart or not rootPart:IsA("BasePart") then
            return "Forward"
        end
        return "Forward"
    end)
    bindButton(special, "Special", nil)

    for slot = 1, 4 do
        bindButton(skillButtons[slot], "Skill" .. slot, nil)
    end

    block.Activated:Connect(function()
        local active = player:GetAttribute("LocalBlocking") == true
        player:SetAttribute("LocalBlocking", not active)
        block.Text = if active then "BLOCK" else "BLOCKING"
        fire(if active then "BlockEnd" else "BlockStart")
    end)

    sprint.Activated:Connect(function()
        local active = player:GetAttribute("LocalSprinting") == true
        player:SetAttribute("LocalSprinting", not active)
        sprint.Text = if active then "SPRINT" else "SPRINTING"
        movementRemote:FireServer(if active then "SprintEnd" else "SprintStart")
    end)

    ultimate.Activated:Connect(function()
        fire("Ultimate")
    end)

    awakening.Activated:Connect(function()
        fire("Awakening")
    end)

    local function refreshCharacter()
        local id = player:GetAttribute("CharacterId") or "PotentialMan"
        local definition = Definitions[id]
        local moves = Movesets.Get(id)

        name.Text = definition and definition.Name or id
        subtitle.Text = definition and definition.Subtitle or ""

        for slot = 1, 4 do
            local move = moves[slot]
            skillButtons[slot].Text = tostring(slot) .. "\n" .. (move and move.Name or ("Skill " .. slot))
        end
    end

    local function refreshHealth()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            return
        end

        local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
        fill.Size = UDim2.fromScale(ratio, 1)
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
        humanoid.HealthChanged:Connect(refreshHealth)
        humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(refreshHealth)
        refreshHealth()
    end

    local stateNames = {
        Attacking = "ATTACK",
        UsingAbility = "SKILL",
        Blocking = "BLOCK",
        Stunned = "STUNNED",
        Ragdolled = "DOWN",
        Dashing = "DASH",
        Ultimate = "ULTIMATE",
        Awakening = "AWAKENING"
    }

    local function refreshState()
        local character = player.Character
        local value = character and character:GetAttribute("CombatState")
        state.Text = stateNames[tostring(value)] or "READY"
    end

    local function refreshMeters()
        local ultimateValue = math.clamp((tonumber(player:GetAttribute("UltimateMeter")) or 0) / 100, 0, 1)
        local awakeningValue = math.clamp((tonumber(player:GetAttribute("AwakeningMeter")) or 0) / 100, 0, 1)
        local highest = math.max(ultimateValue, awakeningValue)

        meterFill.Size = UDim2.fromScale(highest, 1)
        meterFill.BackgroundColor3 = if awakeningValue > ultimateValue then core.Palette.Accent2 else core.Palette.Accent
        meterText.Text = if awakeningValue > ultimateValue
            then string.format("AWAKENING %d%%", math.floor(awakeningValue * 100))
            else string.format("ULTIMATE %d%%", math.floor(ultimateValue * 100))

        ultimate.Text = player:GetAttribute("UltimateReady") == true and "ULTIMATE\nREADY" or "ULTIMATE"
        awakening.Text = player:GetAttribute("AwakeningReady") == true and "AWAKEN\nREADY" or "AWAKEN"
    end

    for slot = 1, 4 do
        local move = Movesets.Get(player:GetAttribute("CharacterId") or "PotentialMan")[slot]
        cooldownLabels[slot].Text = move and ("CD " .. tostring(move.Cooldown) .. "s") or "READY"
    end

    player:GetAttributeChangedSignal("CharacterId"):Connect(refreshCharacter)
    player:GetAttributeChangedSignal("UltimateMeter"):Connect(refreshMeters)
    player:GetAttributeChangedSignal("AwakeningMeter"):Connect(refreshMeters)
    player:GetAttributeChangedSignal("UltimateReady"):Connect(refreshMeters)
    player:GetAttributeChangedSignal("AwakeningReady"):Connect(refreshMeters)

    if player.CharacterAdded then
        player.CharacterAdded:Connect(function()
            task.defer(bindHealth)
            task.defer(refreshHealth)
        end)
    end

    task.spawn(function()
        while guiStillValid(root) do
            refreshState()
            for slot = 1, 4 do
                local action = "Skill" .. slot
                local remaining = math.max(0, (cooldownUntil[action] or 0) - os.clock())
                cooldownLabels[slot].Text = if remaining > 0 then string.format("%.1fs", remaining) else "READY"
                TweenService:Create(skillButtons[slot], TweenInfo.new(0.08), {
                    BackgroundTransparency = if remaining > 0 then 0.22 else 0.08
                }):Play()
            end
            task.wait(0.08)
        end
    end)

    refreshCharacter()
    bindHealth()
    refreshMeters()

    return {
        Root = root,
        SetVisible = function(_, visible: boolean)
            root.Visible = visible
        end
    }
end

function guiStillValid(root: GuiObject): boolean
    return root.Parent ~= nil
end

return HUDCombatPanel
