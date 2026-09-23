--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)
local InputController = require(script.Parent.Parent.Controllers.InputController)
local InputManager = require(script.Parent.Parent.Controllers.InputManager)
local HUDController = require(script.Parent.Parent.Controllers.HUDController)

local player = Players.LocalPlayer
local started = false

local function serverRemaining(action: string): number
    local untilValue = tonumber(player:GetAttribute("CooldownUntil_" .. action)) or 0
    return math.max(0, untilValue - workspace:GetServerTimeNow())
end

local function durationFor(action: string): number
    if action == "M1" then
        return Config.Combat.M1.Cooldown
    end

    if action == "Dash" then
        return Config.Combat.Dash.Cooldown
    end

    if action == "Special" then
        return math.clamp(
            tonumber(player:GetAttribute("SpecialCooldown")) or Config.Combat.Special.Cooldown,
            0.25,
            20
        )
    end

    local slot = tonumber(string.match(action, "^Skill(%d)$"))
    if slot then
        local id = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
        local move = Movesets.GetMove(id, slot)
        return math.clamp(
            tonumber(move and move.Cooldown) or 1,
            Config.Combat.Skill.MinCooldown,
            Config.Combat.Skill.MaxCooldown
        )
    end

    return 0
end

local predicted: {[string]: number} = {}

local function hidden(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function start()
    if started then
        return
    end
    started = true

    local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
    if not remotes then
        return
    end

    local combatAction = remotes:WaitForChild("CombatAction", 15)
    local combatFX = remotes:WaitForChild("CombatFX", 15)
    local movementRemote = remotes:WaitForChild("MovementRemote", 15)
    if not combatAction or not combatFX or not movementRemote
        or not combatAction:IsA("RemoteEvent")
        or not combatFX:IsA("RemoteEvent")
        or not movementRemote:IsA("RemoteEvent") then
        return
    end

    local hud = HUDController.new()

    local function fire(action: string, payload: any?)
        if hidden() then
            return
        end

        if action ~= "BlockStart"
            and action ~= "BlockEnd"
            and action ~= "Ultimate"
            and action ~= "Awakening" then
            local localReadyAt = predicted[action] or 0
            if math.max(0, localReadyAt - workspace:GetServerTimeNow()) > 0
                or serverRemaining(action) > 0 then
                return
            end

            local duration = durationFor(action)
            if duration > 0 then
                predicted[action] = workspace:GetServerTimeNow() + duration
            end
        end

        combatAction:FireServer(action, payload)
    end

    local blockActive = false
    local sprintActive = false

    local function setBlock(active: boolean)
        blockActive = active
        player:SetAttribute("LocalBlocking", active)
        hud:SetActionState("Block", active)
        fire(active and "BlockStart" or "BlockEnd")
    end

    local function setSprint(active: boolean)
        sprintActive = active
        player:SetAttribute("LocalSprinting", active)
        hud:SetActionState("Sprint", active)
        movementRemote:FireServer(active and "SprintStart" or "SprintEnd")
    end

    hud.M1Button.Activated:Connect(function()
        fire("M1")
    end)

    hud.DashButton.Activated:Connect(function()
        fire("Dash", InputController:GetDashDirection())
    end)

    hud.BlockButton.Activated:Connect(function()
        setBlock(not blockActive)
    end)

    hud.SprintButton.Activated:Connect(function()
        setSprint(not sprintActive)
    end)

    hud.SpecialButton.Activated:Connect(function()
        fire("Special")
    end)

    hud.UltimateButton.Activated:Connect(function()
        fire("Ultimate")
    end)

    hud.AwakeningButton.Activated:Connect(function()
        fire("Awakening")
    end)

    for slot = 1, 4 do
        hud.SkillButtons[slot].Activated:Connect(function()
            fire("Skill" .. tostring(slot))
        end)
    end

    InputManager:BindAction("CC_M1", function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("M1")
        end
    end, {Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2}, false)

    InputManager:BindAction("CC_Dash", function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Dash", InputController:GetDashDirection())
        end
    end, {Enum.KeyCode.Q, Enum.KeyCode.ButtonA}, false)

    InputManager:BindAction("CC_Special", function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Special")
        end
    end, {Enum.KeyCode.E, Enum.KeyCode.ButtonX}, false)

    InputManager:BindAction("CC_Skill1", function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill1")
        end
    end, {Enum.KeyCode.One, Enum.KeyCode.ButtonR1}, false)

    InputManager:BindAction("CC_Skill2", function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill2")
        end
    end, {Enum.KeyCode.Two, Enum.KeyCode.ButtonY}, false)

    InputManager:BindAction("CC_Skill3", function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill3")
        end
    end, {Enum.KeyCode.Three, Enum.KeyCode.DPadUp}, false)

    InputManager:BindAction("CC_Skill4", function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Skill4")
        end
    end, {Enum.KeyCode.Four, Enum.KeyCode.DPadDown}, false)

    InputManager:BindAction("CC_Block", function(_, state)
        if state == Enum.UserInputState.Begin then
            setBlock(true)
        elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
            setBlock(false)
        end
    end, {Enum.KeyCode.F, Enum.KeyCode.ButtonL2}, false)

    InputManager:BindAction("CC_Sprint", function(_, state)
        if state == Enum.UserInputState.Begin then
            setSprint(true)
        elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
            setSprint(false)
        end
    end, {Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL1}, false)

    InputManager:BindAction("CC_Ultimate", function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Ultimate")
        end
    end, {Enum.KeyCode.R, Enum.KeyCode.ButtonR3}, false)

    InputManager:BindAction("CC_Awakening", function(_, state)
        if state == Enum.UserInputState.Begin then
            fire("Awakening")
        end
    end, {Enum.KeyCode.G, Enum.KeyCode.ButtonL3}, false)

    local function updateCharacter()
        local id = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
        local definition = Definitions[id]
        if definition then
            hud:UpdateCharacter(
                tostring(definition.Name),
                tostring(definition.Subtitle or ""),
                Movesets.Get(id)
            )
        end
    end

    local function updateState()
        hud:UpdateState(tostring(player:GetAttribute("CombatState") or "Idle"))
        hud:SetActionState("Block", player:GetAttribute("Blocking") == true)
        hud:SetActionState("Sprint", sprintActive)
    end

    local function updatePower()
        hud:UpdatePower(
            tonumber(player:GetAttribute("UltimateMeter")) or 0,
            tonumber(player:GetAttribute("AwakeningMeter")) or 0,
            player:GetAttribute("UltimateReady") == true,
            player:GetAttribute("AwakeningReady") == true
        )

        local domain = player:GetAttribute("DomainName")
        hud:SetDomain(
            type(domain) == "string" and domain or nil
        )
    end

    local function bindHealth(character: Model)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            return
        end

        local function update()
            hud:UpdateHealth(humanoid.Health, humanoid.MaxHealth)
        end

        humanoid.HealthChanged:Connect(update)
        humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
        update()
    end

    local function updateVisible()
        hud:SetVisible(not hidden())

        if hidden() and sprintActive then
            setSprint(false)
        end

        if hidden() and blockActive then
            setBlock(false)
        end
    end

    for _, attribute in ipairs({
        "CharacterId",
        "CharacterName",
        "CharacterTitle",
        "SpecialName",
        "SpecialCooldown"
    }) do
        player:GetAttributeChangedSignal(attribute):Connect(updateCharacter)
    end

    for _, attribute in ipairs({
        "CombatState",
        "Blocking",
        "CombatStunned",
        "Ragdolled"
    }) do
        player:GetAttributeChangedSignal(attribute):Connect(updateState)
    end

    for _, attribute in ipairs({
        "UltimateMeter",
        "AwakeningMeter",
        "UltimateReady",
        "AwakeningReady"
    }) do
        player:GetAttributeChangedSignal(attribute):Connect(updatePower)
    end

    for _, attribute in ipairs({
        "CCHUD_MenuOpen",
        "CCHUD_CharacterMenuOpen",
        "CCHUD_EmoteWheelOpen",
        "CCHUD_OwnerPanelOpen"
    }) do
        player:GetAttributeChangedSignal(attribute):Connect(updateVisible)
    end

    local comboCount = 0
    local _comboExpiresAt = 0

    combatFX.OnClientEvent:Connect(function(kind, _position, payload)
        if not payload or type(payload) ~= "table" then
            return
        end

        if kind == "Hit" then
            local actor = payload.actor
            local attacker = payload.attacker
            local character = player.Character

            if attacker == character and actor and actor:IsA("Model") then
                comboCount += 1
                _comboExpiresAt = os.clock() + Config.Combat.M1.ComboReset

                local targetName = actor:GetAttribute("CharacterName")
                    or actor.Name

                hud:SetTarget(tostring(targetName))
                hud:ShowCombo(comboCount)
                hud:Notify(
                    payload.guardBreak == true
                        and "GUARD BREAK"
                        or "HIT"
                )
            elseif actor == character then
                hud:Notify(
                    payload.ragdoll == true
                        and "RAGDOLL"
                        or payload.guardBreak == true
                            and "GUARD BROKEN"
                            or "HIT"
                )
            end
        elseif kind == "PerfectBlock" then
            if payload.actor == player.Character then
                hud:Notify("PERFECT BLOCK")
            end
        elseif kind == "BlockImpact" then
            if payload.actor == player.Character then
                hud:Notify("BLOCK")
            end
        elseif kind == "Death" then
            if payload.actor == player.Character then
                hud:Notify("DEFEATED")
            elseif payload.attacker == player.Character then
                hud:Notify("+5 CREDITS")
            end
        end
    end)

    player.CharacterAdded:Connect(function(character)
        bindHealth(character)
    end)

    updateCharacter()
    updateState()
    updatePower()
    updateVisible()

    task.spawn(function()
        while hud.Gui.Parent do
            local currentTime = workspace:GetServerTimeNow()

            for slot = 1, 4 do
                local action = "Skill" .. tostring(slot)
                local remaining = math.max(
                    math.max(0, (predicted[action] or 0) - currentTime),
                    serverRemaining(action)
                )

                hud:SetCooldown(slot, remaining, durationFor(action))
            end

            task.wait(0.08)
        end
    end)
end

return {
    Start = start
}
