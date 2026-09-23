--!strict

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local CombatView = require(script.Parent.HUDCombatView)
local Menus = require(script.Parent.HUDMenus)
local Platform = require(script.Parent.HUDPlatform)

local player = Players.LocalPlayer
local Controller = {}
Controller.__index = Controller

function Controller.new(): any
    local playerGui = player:WaitForChild("PlayerGui")

    for _, name in ipairs({"CursedCollisionCombatHUD", "CursedCollisionMenuHUD"}) do
        local old = playerGui:FindFirstChild(name)
        if old then
            old:Destroy()
        end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CursedCollisionCombatHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 5
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local root = Instance.new("Frame")
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = gui

    local scale = Instance.new("UIScale")
    scale.Parent = root

    local function resize()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end
        local viewport = camera.ViewportSize
        local shortAxis = math.min(viewport.X, viewport.Y)
        scale.Scale = math.clamp(shortAxis / 720, 0.72, 1.08)
    end

    resize()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
    end

    local combat = CombatView.Create(root)
    local menus = Menus.new()

    root:GetAttributeChangedSignal("OpenCharacterMenu"):Connect(function()
        if root:GetAttribute("OpenCharacterMenu") then
            root:SetAttribute("OpenCharacterMenu", false)
            menus:Open("Characters")
        end
    end)

    root:GetAttributeChangedSignal("OpenEmoteMenu"):Connect(function()
        if root:GetAttribute("OpenEmoteMenu") then
            root:SetAttribute("OpenEmoteMenu", false)
            menus:Open("Emotes")
        end
    end)

    root:GetAttributeChangedSignal("OpenMainMenu"):Connect(function()
        if root:GetAttribute("OpenMainMenu") then
            root:SetAttribute("OpenMainMenu", false)
            menus:Open("Menu")
        end
    end)

    Platform:Changed(function()
        CombatView.RefreshPlatform(combat)
        if Platform:IsGamepad() then
            GuiService.GuiNavigationEnabled = true
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
        Combat = combat,
        Menus = menus
    }, Controller)
end

function Controller:SetVisible(self: any, visible: boolean)
    self.Root.Visible = visible
end

function Controller:UpdateCharacter(self: any, name: string, subtitle: string, moves: {[number]: any})
    CombatView.UpdateCharacter(self.Combat, name, subtitle, moves)
end

function Controller:UpdateHealth(self: any, health: number, maxHealth: number)
    CombatView.UpdateHealth(self.Combat, health, maxHealth)
end

function Controller:UpdateState(self: any, state: string)
    CombatView.UpdateState(self.Combat, state)
end

function Controller:UpdatePower(self: any, ultimate: number, awakening: number, ultimateReady: boolean, awakeningReady: boolean)
    CombatView.UpdatePower(self.Combat, ultimate, awakening, ultimateReady, awakeningReady)
end

function Controller:SetCooldown(self: any, slot: number, remaining: number, total: number)
    CombatView.SetCooldown(self.Combat, slot, remaining, total)
end

return Controller
