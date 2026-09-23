--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Util = require(script.Parent.Util)

local player = Players.LocalPlayer
local M = {}
local started = false

function M.Start()
    if started then
        return
    end
    started = true

    local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
    if not remotes then
        return
    end

    local accountAction = remotes:WaitForChild("AccountAction", 15)
    local accountEvent = remotes:WaitForChild("AccountEvent", 15)
    local gamePassAction = remotes:WaitForChild("GamePassAction", 15)
    local gamePassEvent = remotes:WaitForChild("GamePassEvent", 15)
    if not accountAction or not accountEvent or not gamePassAction or not gamePassEvent then
        return
    end

    local shop = require(ReplicatedStorage.Economy.ShopDefinitions)
    local gamePassConfig = require(ReplicatedStorage.Monetization.GamePassConfig)

    local gui = Util.makeGui("CursedCollisionAccountUI", 20)
    local root = Util.makeRoot(gui)
    local colors = Util.Colors

    local menuButton = Util.button(root, "MenuButton", "☰", UDim2.fromScale(0.060, 0.052), UDim2.fromScale(0.925, 0.020), true)
    menuButton.TextSize = 18
    menuButton.AnchorPoint = Vector2.new(0.5, 0)

    local panel = Instance.new("Frame")
    panel.Name = "AccountPanel"
    panel.Size = UDim2.fromScale(0.86, 0.78)
    panel.Position = UDim2.fromScale(0.50, 0.51)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = colors.Panel
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = root
    Util.corner(panel, 16)
    Util.stroke(panel, colors.Accent, 0.58, 1.4)

    local panelScale = Instance.new("UIScale")
    panelScale.Scale = 0.96
    panelScale.Parent = panel

    local title = Util.label(panel, "CURSED COLLISION", UDim2.fromScale(0.42, 0.075), UDim2.fromScale(0.032, 0.025), 19, Enum.Font.GothamBlack)
    title.TextXAlignment = Enum.TextXAlignment.Left

    local subtitle = Util.label(panel, "SHOP", UDim2.fromScale(0.35, 0.045), UDim2.fromScale(0.032, 0.094), 8)
    subtitle.TextColor3 = colors.Muted
    subtitle.TextXAlignment = Enum.TextXAlignment.Left

    local credits = Util.label(panel, "0 C", UDim2.fromScale(0.20, 0.06), UDim2.fromScale(0.68, 0.035), 12, Enum.Font.GothamBlack)
    credits.TextColor3 = colors.Gold
    credits.TextXAlignment = Enum.TextXAlignment.Right

    local platform = Util.label(panel, Util.platform(), UDim2.fromScale(0.18, 0.045), UDim2.fromScale(0.68, 0.093), 8)
    platform.TextColor3 = colors.Muted
    platform.TextXAlignment = Enum.TextXAlignment.Right

    local closeButton = Util.button(panel, "Close", "×", UDim2.fromScale(0.062, 0.078), UDim2.fromScale(0.923, 0.022), true)
    closeButton.TextSize = 22

    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.fromScale(0.88, 0.075)
    tabs.Position = UDim2.fromScale(0.06, 0.145)
    tabs.BackgroundTransparency = 1
    tabs.Parent = panel

    local tabShop = Util.button(tabs, "ShopTab", "SHOP", UDim2.fromScale(0.30, 1), UDim2.fromScale(0, 0), true)
    local tabQuests = Util.button(tabs, "QuestTab", "QUESTS", UDim2.fromScale(0.30, 1), UDim2.fromScale(0.35, 0), true)
    local tabPasses = Util.button(tabs, "PassTab", "GAMEPASSES", UDim2.fromScale(0.30, 1), UDim2.fromScale(0.70, 0), true)

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.fromScale(0.88, 0.68)
    content.Position = UDim2.fromScale(0.06, 0.245)
    content.BackgroundTransparency = 1
    content.Parent = panel

    type Quest = {[string]: any}
    type MenuState = {
        activeTab: "Shop" | "Quests" | "Passes",
        economy: {
            Credits: number,
            OwnedSkins: {[string]: boolean},
            EquippedSkin: string
        },
        quests: {
            Daily: {Quest},
            Weekly: {Quest},
            General: {Quest}
        },
        passes: {[string]: boolean}
    }

    local state: MenuState = {
        activeTab = "Shop",
        economy = {
            Credits = 0,
            OwnedSkins = {},
            EquippedSkin = ""
        },
        quests = {
            Daily = {},
            Weekly = {},
            General = {}
        },
        passes = {
            UltimateSkin = false,
            KillSound = false,
            InstantSkin = false
        }
    }

    local function clear()
        for _, child in ipairs(content:GetChildren()) do
            child:Destroy()
        end
    end

    local function list()
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.fromScale(1, 1)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 5
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.CanvasSize = UDim2.fromOffset(0, 0)
        scroll.Selectable = true
        scroll.Parent = content

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = scroll

        return scroll
    end

    local function renderShop()
        clear()
        local scroll = list()
        local characterId = tostring(player:GetAttribute("CharacterId") or "PotentialMan")

        for id, item in pairs(shop.Skins) do
            if item.Character == characterId then
                local owned = state.economy.OwnedSkins[id] == true
                local equipped = state.economy.EquippedSkin == id
                local card = Util.button(scroll, tostring(id), tostring(item.Name) .. "\n" .. tostring(item.Rarity or "SKIN"), UDim2.new(1, -8, 0, 72), UDim2.new(), true)
                card.LayoutOrder += 1
                card.TextXAlignment = Enum.TextXAlignment.Left
                card.TextColor3 = equipped and colors.Accent or colors.Text
                card.Text = (equipped and "◆ " or "") .. tostring(item.Name) .. "\n" .. (owned and (equipped and "EQUIPPED" or "OWNED") or tostring(item.Price) .. " C")
                card.Activated:Connect(function()
                    accountAction:FireServer(owned and "Equip" or "Buy", {
                        category = "Skins",
                        id = item.Id
                    })
                end)
            end
        end
    end

    local function questCard(parent: Instance, quest: any, order: number)
        local card = Util.button(parent, "Quest" .. order, "", UDim2.new(1, -8, 0, 86), UDim2.new(), true)
        card.LayoutOrder = order
        card.AutoButtonColor = false

        local name = Util.label(card, tostring(quest.Name or "Mission"), UDim2.fromScale(0.66, 0.25), UDim2.fromScale(0.025, 0.08), 11, Enum.Font.GothamBlack)
        name.TextXAlignment = Enum.TextXAlignment.Left
        local desc = Util.label(card, tostring(quest.Description or ""), UDim2.fromScale(0.66, 0.30), UDim2.fromScale(0.025, 0.34), 8)
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextColor3 = colors.Muted

        local progress = math.max(0, math.floor(tonumber(quest.Progress) or 0))
        local target = math.max(1, math.floor(tonumber(quest.Target) or 1))
        local bar = Instance.new("Frame")
        bar.Size = UDim2.fromScale(0.54, 0.10)
        bar.Position = UDim2.fromScale(0.025, 0.75)
        bar.BackgroundColor3 = Color3.fromRGB(42, 44, 54)
        bar.BorderSizePixel = 0
        bar.Parent = card
        Util.corner(bar, 5)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.fromScale(math.clamp(progress / target, 0, 1), 1)
        fill.BackgroundColor3 = quest.Completed and colors.Success or colors.Accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Util.corner(fill, 5)
    end

    local function renderQuests()
        clear()
        local scroll = list()
        local order = 0

        local sections: {{string, {Quest}}} = {
            {"DAILY", state.quests.Daily},
            {"WEEKLY", state.quests.Weekly},
            {"MASTERY", state.quests.General}
        }

        for _, section in ipairs(sections) do
            order += 1
            local header = Util.label(scroll, section[1], UDim2.new(1, -8, 0, 28), UDim2.new(), 12, Enum.Font.GothamBlack)
            header.LayoutOrder = order
            header.TextColor3 = colors.Accent2
            header.TextXAlignment = Enum.TextXAlignment.Left

            for _, quest in ipairs(section[2]) do
                order += 1
                questCard(scroll, quest, order)
            end
        end
    end

    local function renderPasses()
        clear()
        local scroll = list()

        local titles: {[string]: string} = {
            UltimateSkin = "ULTIMATE SKIN",
            InstantSkin = "INSTANT SKIN",
            KillSound = "KILL SOUND"
        }
        local descriptions: {[string]: string} = {
            UltimateSkin = "Use the equipped skin for Ultimate/Awakening.",
            InstantSkin = "Apply the equipped skin instantly.",
            KillSound = "Play a custom sound after a confirmed elimination."
        }

        for index, key in ipairs({"UltimateSkin", "InstantSkin", "KillSound"}) do
            local row = Util.button(
                scroll,
                key,
                titles[key] .. "\n" .. descriptions[key],
                UDim2.new(1, -8, 0, 86),
                UDim2.new(),
                true
            )
            row.LayoutOrder = index
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.Activated:Connect(function()
                if state.passes[key] then
                    return
                end

                local pass = gamePassConfig[key]
                if pass and type(pass.Id) == "number" and pass.Id > 0 then
                    pcall(function()
                        MarketplaceService:PromptGamePassPurchase(player, pass.Id)
                    end)
                end
            end)
        end
    end

    local function render()
        if state.activeTab == "Shop" then
            subtitle.Text = "SHOP"
            renderShop()
        elseif state.activeTab == "Quests" then
            subtitle.Text = "QUESTS"
            renderQuests()
        else
            subtitle.Text = "GAMEPASSES"
            renderPasses()
        end
    end

    local function open()
        Util.closeKnownPanels("Menu")
        Util.setMenuAttributes("Menu", true)
        accountAction:FireServer("Sync", {})
        gamePassAction:FireServer("Sync", {})
        render()
        panel.Visible = true
        panelScale.Scale = 0.94
        TweenService:Create(panelScale, TweenInfo.new(0.14, Enum.EasingStyle.Back), {Scale = 1}):Play()
        Util.setGamepadNavigation(true)
        GuiService.SelectedObject = tabShop
    end

    local function closePanel()
        panel.Visible = false
        Util.setMenuAttributes("Menu", false)
    end

    menuButton.Activated:Connect(function()
        if panel.Visible then closePanel() else open() end
    end)
    closeButton.Activated:Connect(closePanel)

    tabShop.Activated:Connect(function()
        state.activeTab = "Shop"
        render()
    end)

    tabQuests.Activated:Connect(function()
        state.activeTab = "Quests"
        render()
    end)

    tabPasses.Activated:Connect(function()
        state.activeTab = "Passes"
        render()
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == Enum.KeyCode.ButtonStart then
            if panel.Visible then closePanel() else open() end
        end
    end)

    accountEvent.OnClientEvent:Connect(function(event, payload)
        if event == "Sync" then
            state.economy = payload and payload.Economy or state.economy
            state.quests = payload and payload.Quests or state.quests
            credits.Text = tostring(state.economy.Credits or 0) .. " C"
            if panel.Visible then render() end
        elseif event == "Notice" then
            local message = tostring(payload and payload.Message or "")
            if message ~= "" then
                local toast = Util.label(root, message, UDim2.fromScale(0.50, 0.060), UDim2.fromScale(0.25, 0.88), 11)
                toast.BackgroundTransparency = 0.10
                toast.BackgroundColor3 = payload and payload.Success == true and Color3.fromRGB(26, 56, 40) or Color3.fromRGB(61, 27, 35)
                Util.corner(toast, 9)
                Debris:AddItem(toast, 2.2)
            end
        end
    end)

    gamePassEvent.OnClientEvent:Connect(function(event, payload)
        if event == "Sync" then
            for key, value in pairs(payload or {}) do
                if state.passes[key] ~= nil then
                    state.passes[key] = value == true
                end
            end
            if panel.Visible and state.activeTab == "Passes" then
                render()
            end
        elseif event == "Result" then
            accountAction:FireServer("Sync", {})
            gamePassAction:FireServer("Sync", {})
        end
    end)

    UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
        platform.Text = Util.platform()
        if Util.platform() == "Console" then
            GuiService.GuiNavigationEnabled = true
        end
    end)

    player:GetAttributeChangedSignal("CharacterId"):Connect(function()
        if panel.Visible and state.activeTab == "Shop" then
            render()
        end
    end)

    Util.setMenuAttributes("Menu", false)
end

return M
