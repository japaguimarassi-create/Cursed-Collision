--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local CharacterMoves = require(ReplicatedStorage.Characters.CharacterMoves)
local CustomMovesets = require(ReplicatedStorage.Characters.CustomMovesets)
local InputController = require(script.Parent.Controllers.InputController)
local InputManager = require(script.Parent.Controllers.InputManager)
local HUDController = require(script.Parent.Controllers.HUDController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)

if not remotes then
    return
end

local combatAction = remotes:WaitForChild("CombatAction", 15)
local combatFX = remotes:WaitForChild("CombatFX", 15)
local movementRemote = remotes:WaitForChild("MovementRemote", 15)

if not combatAction or not combatFX or not movementRemote then
    return
end

local hud = HUDController.new()

local localCooldowns: {[string]: number} = {}
local comboCount = 0
local comboExpireAt = 0

local function blockedByMenu(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function remaining(key: string): number
    return math.max(
        0,
        (localCooldowns[key] or 0) - os.clock()
    )
end

local function cooldownFor(action: string): number
    if action == "M1" then
        return Config.Combat.M1.Cooldown
    end

    if action == "Dash" then
        return Config.Combat.Dash.Cooldown
    end

    if action == "Special" then
        local id = player:GetAttribute("CharacterId") or "PotentialMan"
        local definition = Definitions[id]
        return math.clamp(
            tonumber(definition and definition.SpecialCooldown) or Config.Combat.Special.Cooldown,
            0.25,
            20
        )
    end

    if string.sub(action, 1, 5) == "Skill" then
        local slot = tonumber(string.sub(action, 6))
        local id = player:GetAttribute("CharacterId") or "PotentialMan"
        local move = slot and CustomMovesets.GetMove(id, slot)

        return math.clamp(
            tonumber(move and move.Cooldown) or 1,
            Config.Combat.Skill.MinCooldown,
            Config.Combat.Skill.MaxCooldown
        )
    end

    return 0
end

local function fire(action: string, payload: any)
    if blockedByMenu() then
        return
    end

    if action ~= "BlockStart"
        and action ~= "BlockEnd"
        and remaining(action) > 0 then
        return
    end

    local duration = cooldownFor(action)
    if duration > 0 then
        localCooldowns[action] = os.clock() + duration
    end

    combatAction:FireServer(action, payload)
end

local function setBlocking(active: boolean)
    player:SetAttribute("LocalBlocking", active)
    hud:SetBlocking(active)

    if active then
        fire("BlockStart")
    else
        fire("BlockEnd")
    end
end

local function setSprinting(active: boolean)
    player:SetAttribute("LocalSprinting", active)
    hud:SetSprinting(active)

    movementRemote:FireServer(
        active and "SprintStart" or "SprintEnd"
    )
end

local function activatePower(action: string)
    if blockedByMenu() then
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

    local specialName = CharacterMoves[id]
        and CharacterMoves[id].SpecialName
        or "SPECIAL"

    hud.SpecialButton.Text = specialName .. "\n" .. "SPECIAL"
    localCooldowns = {}
    comboCount = 0
    hud:ShowCombo(0)
    hud:SetTarget(nil)
end

local function bindHealth(character: Model)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local function update()
        hud:UpdateHealth(
            humanoid.Health,
            humanoid.MaxHealth
        )
    end

    humanoid.HealthChanged:Connect(update)
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
    update()
end

local function updateState()
    hud:UpdateState(
        tostring(player:GetAttribute("CombatState") or "Idle")
    )
end

local function updatePower()
    local ultimate = math.clamp(
        tonumber(player:GetAttribute("UltimateMeter")) or 0,
        0,
        100
    )

    local awakening = math.clamp(
        tonumber(player:GetAttribute("AwakeningMeter")) or 0,
        0,
        100
    )

    hud:UpdatePower(
        ultimate,
        awakening,
        player:GetAttribute("UltimateReady") == true,
        player:GetAttribute("AwakeningReady") == true
    )

    local domain = player:GetAttribute("DomainName")
    hud:SetDomain(
        type(domain) == "string" and domain or nil
    )
end

local function setMenuVisibility()
    local hidden = blockedByMenu()
    hud:SetVisible(not hidden)

    if hidden then
        if player:GetAttribute("LocalBlocking") == true then
            player:SetAttribute("LocalBlocking", false)
            hud:SetBlocking(false)
            combatAction:FireServer("BlockEnd")
        end

        if player:GetAttribute("LocalSprinting") == true then
            player:SetAttribute("LocalSprinting", false)
            hud:SetSprinting(false)
            movementRemote:FireServer("SprintEnd")
        end
    end
end

for _, attribute in ipairs({
    "CCHUD_MenuOpen",
    "CCHUD_CharacterMenuOpen",
    "CCHUD_EmoteWheelOpen",
    "CCHUD_OwnerPanelOpen"
}) do
    player:GetAttributeChangedSignal(attribute):Connect(setMenuVisibility)
end

player:GetAttributeChangedSignal("CharacterId"):Connect(refreshCharacter)
player:GetAttributeChangedSignal("CombatState"):Connect(updateState)
player:GetAttributeChangedSignal("UltimateMeter"):Connect(updatePower)
player:GetAttributeChangedSignal("AwakeningMeter"):Connect(updatePower)
player:GetAttributeChangedSignal("UltimateReady"):Connect(updatePower)
player:GetAttributeChangedSignal("AwakeningReady"):Connect(updatePower)
player:GetAttributeChangedSignal("DomainName"):Connect(updatePower)

hud.M1Button.Activated:Connect(function()
    fire("M1")
end)

hud.DashButton.Activated:Connect(function()
    fire("Dash", InputController:GetDashDirection())
end)

hud.BlockButton.Activated:Connect(function()
    setBlocking(
        player:GetAttribute("LocalBlocking") ~= true
    )
end)

hud.SprintButton.Activated:Connect(function()
    setSprinting(
        player:GetAttribute("LocalSprinting") ~= true
    )
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

for slot = 1, 4 do
    hud.SkillButtons[slot].Activated:Connect(function()
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
    {
        Enum.UserInputType.MouseButton1,
        Enum.KeyCode.ButtonR2
    },
    false
)

InputManager:BindAction(
    "CC_Dash",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Dash", InputController:GetDashDirection())
        end
    end,
    {
        Enum.KeyCode.Q,
        Enum.KeyCode.ButtonA
    },
    false
)

InputManager:BindAction(
    "CC_Special",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Special")
        end
    end,
    {
        Enum.KeyCode.E,
        Enum.KeyCode.ButtonX
    },
    false
)

InputManager:BindAction(
    "CC_Skill1",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill1")
        end
    end,
    {
        Enum.KeyCode.One,
        Enum.KeyCode.ButtonR1
    },
    false
)

InputManager:BindAction(
    "CC_Skill2",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill2")
        end
    end,
    {
        Enum.KeyCode.Two,
        Enum.KeyCode.ButtonY
    },
    false
)

InputManager:BindAction(
    "CC_Skill3",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill3")
        end
    end,
    {
        Enum.KeyCode.Three,
        Enum.KeyCode.DPadUp
    },
    false
)

InputManager:BindAction(
    "CC_Skill4",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill4")
        end
    end,
    {
        Enum.KeyCode.Four,
        Enum.KeyCode.DPadDown
    },
    false
)

InputManager:BindAction(
    "CC_Block",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            if player:GetAttribute("LocalBlocking") ~= true then
                setBlocking(true)
            end
        elseif state == Enum.UserInputState.End
            or state == Enum.UserInputState.Cancel then
            if player:GetAttribute("LocalBlocking") == true then
                setBlocking(false)
            end
        end
    end,
    {
        Enum.KeyCode.F,
        Enum.KeyCode.ButtonL2
    },
    false
)

InputManager:BindAction(
    "CC_Sprint",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            setSprinting(true)
        elseif state == Enum.UserInputState.End
            or state == Enum.UserInputState.Cancel then
            setSprinting(false)
        end
    end,
    {
        Enum.KeyCode.LeftShift,
        Enum.KeyCode.ButtonL1
    },
    false
)

InputManager:BindAction(
    "CC_Ultimate",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activatePower("Ultimate")
        end
    end,
    {
        Enum.KeyCode.R,
        Enum.KeyCode.ButtonR3
    },
    false
)

InputManager:BindAction(
    "CC_Awakening",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            activatePower("Awakening")
        end
    end,
    {
        Enum.KeyCode.G,
        Enum.KeyCode.ButtonL3
    },
    false
)

combatFX.OnClientEvent:Connect(function(kind, position, payload)
    if not payload then
        return
    end

    if kind == "Hit" then
        local actor = payload.actor
        local attacker = payload.attacker
        local localCharacter = player.Character

        if attacker == localCharacter
            and actor
            and actor:IsA("Model") then
            local humanoid = actor:FindFirstChildOfClass("Humanoid")
            local name = actor:GetAttribute("CharacterName")
                or humanoid and humanoid.DisplayName
                or actor.Name

            hud:SetTarget(tostring(name))

            comboCount += 1
            comboExpireAt = os.clock() + 0.92
            hud:ShowCombo(comboCount)
        elseif actor == localCharacter then
            hud:Notify(
                payload.guardBreak == true
                    and "GUARD BROKEN"
                    or "HIT"
            )
        end
    elseif kind == "PerfectBlock" then
        local actor = payload.actor

        if actor == player.Character then
            hud:Notify("PERFECT BLOCK")
        end
    elseif kind == "BlockImpact" then
        local actor = payload.actor

        if actor == player.Character then
            hud:Notify("BLOCK")
        end
    elseif kind == "Death" then
        local actor = payload.actor

        if actor == player.Character then
            hud:Notify("DEFEATED")
        elseif payload.attacker == player.Character then
            hud:Notify("+5 CREDITS")
        end
    elseif kind == "AbilityTimeline"
        and payload.phase == "HitFrame"
        and payload.actor == player.Character then
        hud:Notify("IMPACT")
    end

    if position then
        hud.Gui:SetAttribute(
            "LastCombatFXX",
            position.X
        )
    end
end)

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
    accumulator += dt

    if accumulator < 0.05 then
        return
    end

    accumulator = 0

    local now = os.clock()

    if now >= comboExpireAt and comboCount > 0 then
        comboCount = 0
        hud:ShowCombo(0)
        hud:SetTarget(nil)
    end

    for slot = 1, 4 do
        local key = "Skill" .. tostring(slot)
        local total = cooldownFor(key)
        hud:SetCooldown(
            slot,
            remaining(key),
            total
        )
    end
end)

player.CharacterAdded:Connect(function(character)
    bindHealth(character)
    refreshCharacter()
    updateState()
    updatePower()
end)

refreshCharacter()
updateState()
updatePower()
setMenuVisibility()

if player.Character then
    bindHealth(player.Character)
end
