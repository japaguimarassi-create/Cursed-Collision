--!strict

local Players = game:GetService("Players")

local HUDCombatView = require(script.Parent.HUDCombatView)
local HUDMenus = require(script.Parent.HUDMenus)
local HUDPlatform = require(script.Parent.HUDPlatform)

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
    _combat: any,
    _menus: any
}

local Controller = {}
Controller.__index = Controller

function Controller.new(): HUD
    local playerGui = player:WaitForChild("PlayerGui")

    local oldCombat = playerGui:FindFirstChild("CursedCollisionCombatHUD")
    if oldCombat then
        oldCombat:Destroy()
    end

    local oldMenu = playerGui:FindFirstChild("CursedCollisionMenuHUD")
    if oldMenu then
        oldMenu:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CursedCollisionCombatHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 5
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = gui

    local scale = Instance.new("UIScale")
    scale.Parent = root

    local function updateScale()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local shortAxis = math.min(viewport.X, viewport.Y)
        scale.Scale = math.clamp(shortAxis / 720, 0.72, 1.08)
    end

    updateScale()

    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    end

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        updateScale()
    end)

    local combat = HUDCombatView.Create(root)
    local menus = HUDMenus.new()

    root:GetAttributeChangedSignal("OpenCharacterMenu"):Connect(function()
        if root:GetAttribute("OpenCharacterMenu") == true then
            root:SetAttribute("OpenCharacterMenu", false)
            menus:Open("Characters")
        end
    end)

    root:GetAttributeChangedSignal("OpenEmoteMenu"):Connect(function()
        if root:GetAttribute("OpenEmoteMenu") == true then
            root:SetAttribute("OpenEmoteMenu", false)
            menus:Open("Emotes")
        end
    end)

    root:GetAttributeChangedSignal("OpenMainMenu"):Connect(function()
        if root:GetAttribute("OpenMainMenu") == true then
            root:SetAttribute("OpenMainMenu", false)
            menus:Open("Menu")
        end
    end)

    return setmetatable({
        Gui = gui,
        Root = root,
        IdentityName = combat.IdentityName,
        IdentityTitle = combat.IdentityTitle,
        HealthFill = combat.HealthFill,
        HealthText = combat.HealthText,
        StateText = combat.StateText,
        MeterFill = combat.MeterFill,
        MeterText = combat.MeterText,
        UltimateButton = combat.UltimateButton,
        AwakeningButton = combat.AwakeningButton,
        SkillButtons = combat.SkillButtons,
        SkillCooldowns = combat.SkillCooldowns,
        SkillOverlays = combat.SkillOverlays,
        M1Button = combat.M1Button,
        DashButton = combat.DashButton,
        BlockButton = combat.BlockButton,
        SprintButton = combat.SprintButton,
        SpecialButton = combat.SpecialButton,
        _combat = combat,
        _menus = menus
    }, Controller) :: any
end

function Controller:SetVisible(self: HUD, visible: boolean)
    self.Root.Visible = visible
end

function Controller:UpdateCharacter(self: HUD, name: string, subtitle: string, moves: {[number]: any})
    HUDCombatView.UpdateCharacter(self._combat, name, subtitle, moves)
end

function Controller:UpdateHealth(self: HUD, health: number, maxHealth: number)
    HUDCombatView.UpdateHealth(self._combat, health, maxHealth)
end

function Controller:UpdateState(self: HUD, state: string)
    HUDCombatView.UpdateState(self._combat, state)
end

function Controller:UpdatePower(
    self: HUD,
    ultimate: number,
    awakening: number,
    ultimateReady: boolean,
    awakeningReady: boolean
)
    HUDCombatView.UpdatePower(self._combat, ultimate, awakening, ultimateReady, awakeningReady)
end

function Controller:SetCooldown(self: HUD, slot: number, remaining: number, total: number)
    HUDCombatView.SetCooldown(self._combat, slot, remaining, total)
end

function Controller:OpenMenu(self: HUD, menuName: string)
    self._menus:Open(menuName)
end

function Controller:CloseMenu(self: HUD)
    self._menus:Close()
end

return Controller
