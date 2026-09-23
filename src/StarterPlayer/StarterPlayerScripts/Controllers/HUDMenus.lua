--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)
local Shop = require(ReplicatedStorage.Economy.ShopDefinitions)
local GamePassConfig = require(ReplicatedStorage.Monetization.GamePassConfig)

local HUDMenus = {}
HUDMenus.__index = HUDMenus

local player = Players.LocalPlayer

local function corner(object: GuiObject, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object
end

function HUDMenus.new(core: any)
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local combatAction = remotes:WaitForChild("CombatAction")
    local accountAction = remotes:WaitForChild("AccountAction")
    local gamePassAction = remotes:WaitForChild("GamePassAction")
    local adminAction = remotes:WaitForChild("AdminAction")

    local root = Instance.new("Frame")
    root.Name = "Menus"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Visible = true
    root.Parent = core.Root

    local backdrop = core.Overlay

    local panels: {[string]: GuiObject} = {}

    local function hideAll()
        for _, panel in pairs(panels) do
            panel.Visible = false
        end
        backdrop.Visible = false
        player:SetAttribute("CCHUD_MenuOpen", false)
        player:SetAttribute("CCHUD_CharacterMenuOpen", false)
        player:SetAttribute("CCHUD_EmoteWheelOpen", false)
        player:SetAttribute("CCHUD_OwnerPanelOpen", false)
    end

    local function panel(name: string, size: UDim2): Frame
        local frame = core:Panel(root, name)
        frame.Size = size
        frame.Position = UDim2.fromScale(0.50, 0.51)
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Visible = false
        panels[name] = frame
        return frame
    end

    local function header(parent: Frame, title: string, subtitle: string)
        local titleLabel = core:Label(parent, "Title", title)
        titleLabel.Size = UDim2.fromScale(0.72, 0.08)
        titleLabel.Position = UDim2.fromScale(0.035, 0.025)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Font = Enum.Font.GothamBlack
        titleLabel.TextSize = 19

        local sub = core:Label(parent, "Subtitle", subtitle)
        sub.Size = UDim2.fromScale(0.72, 0.045)
        sub.Position = UDim2.fromScale(0.035, 0.095)
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 9
        sub.TextColor3 = core.Palette.Muted

        local close = core:Button(parent, "Close", "×")
        close.Size = UDim2.fromOffset(54, 46)
        close.Position = UDim2.fromScale(0.93, 0.028)
        close.AnchorPoint = Vector2.new(1, 0)
        close.TextSize = 21
        close.Activated:Connect(hideAll)
    end

    local function open(name: string)
        hideAll()
        local target = panels[name]
        if not target then
            return
        end

        target.Visible = true
        backdrop.Visible = true
        player:SetAttribute("CCHUD_MenuOpen", true)

        if name == "Characters" then
            player:SetAttribute("CCHUD_CharacterMenuOpen", true)
        elseif name == "Emotes" then
            player:SetAttribute("CCHUD_EmoteWheelOpen", true)
        elseif name == "Owner" then
            player:SetAttribute("CCHUD_OwnerPanelOpen", true)
        end

        local scale = target:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
        scale.Parent = target
        scale.Scale = 0.94
        TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end

    local menu = panel("Menu", UDim2.fromScale(0.64, 0.72))
    header(menu, "CURSED COLLISION", "PLAY • LOADOUT • SETTINGS")

    local menuList = Instance.new("UIListLayout")
    menuList.Padding = UDim.new(0, 9)
    menuList.Parent = menu
    menuList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    menuList.VerticalAlignment = Enum.VerticalAlignment.Center

    local menuButtons = {
        {"RESUME", "Resume"},
        {"CHARACTERS", "Characters"},
        {"EMOTES", "Emotes"},
        {"LEADERBOARD", "Leaderboard"},
        {"SHOP / MISSIONS", "Shop"}
    }

    for _, entry in ipairs(menuButtons) do
        local button = core:Button(menu, entry[2], entry[1])
        button.Size = UDim2.fromScale(0.62, 0.105)
        button.Activated:Connect(function()
            hideAll()
            if entry[2] == "Resume" then
                return
            end
            open(if entry[2] == "Shop" then "Shop" else entry[2])
        end)
    end

    local characters = panel("Characters", UDim2.fromScale(0.90, 0.78))
    header(characters, "CHARACTERS", "25 FIGHTERS • TOUCH / GAMEPAD READY")

    local selected = Instance.new("Frame")
    selected.Size = UDim2.fromScale(0.94, 0.135)
    selected.Position = UDim2.fromScale(0.03, 0.155)
    selected.BackgroundColor3 = core.Palette.Surface2
    selected.BorderSizePixel = 0
    selected.Parent = characters
    corner(selected, 12)

    local selectedName = core:Label(selected, "Name", "Potential Man")
    selectedName.Size = UDim2.fromScale(0.55, 0.38)
    selectedName.Position = UDim2.fromScale(0.025, 0.08)
    selectedName.TextXAlignment = Enum.TextXAlignment.Left
    selectedName.Font = Enum.Font.GothamBlack
    selectedName.TextSize = 15

    local selectedMoves = core:Label(selected, "Moves", "")
    selectedMoves.Size = UDim2.fromScale(0.68, 0.34)
    selectedMoves.Position = UDim2.fromScale(0.025, 0.52)
    selectedMoves.TextXAlignment = Enum.TextXAlignment.Left
    selectedMoves.TextSize = 8
    selectedMoves.TextColor3 = core.Palette.Muted

    local choose = core:Button(selected, "Select", "SELECT")
    choose.Size = UDim2.fromScale(0.22, 0.55)
    choose.Position = UDim2.fromScale(0.755, 0.23)

    local grid = Instance.new("ScrollingFrame")
    grid.Name = "Roster"
    grid.Size = UDim2.fromScale(0.94, 0.65)
    grid.Position = UDim2.fromScale(0.03, 0.315)
    grid.BackgroundTransparency = 1
    grid.BorderSizePixel = 0
    grid.ScrollBarThickness = 5
    grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
    grid.CanvasSize = UDim2.fromOffset(0, 0)
    grid.Parent = characters

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.31, -8, 0, 68)
    gridLayout.CellPadding = UDim2.fromOffset(8, 8)
    gridLayout.Parent = grid

    local selectedId = player:GetAttribute("CharacterId") or "PotentialMan"
    local characterCards: {[string]: TextButton} = {}

    local order = {}
    for id in pairs(Definitions) do
        table.insert(order, id)
    end
    table.sort(order)

    local function setSelected(id: string)
        local definition = Definitions[id]
        if not definition then
            return
        end

        selectedId = id
        selectedName.Text = definition.Name
        local moves = Movesets.Get(id)
        local names = {}
        for slot = 1, 4 do
            names[slot] = moves[slot] and moves[slot].Name or ("Skill " .. slot)
        end
        selectedMoves.Text = table.concat(names, "  •  ")

        for cardId, card in pairs(characterCards) do
            card.BackgroundColor3 = if cardId == id
                then Color3.fromRGB(53, 39, 73)
                else core.Palette.Surface2
        end
    end

    for index, id in ipairs(order) do
        local definition = Definitions[id]
        local card = core:Button(grid, "Character_" .. id, definition.Name)
        card.LayoutOrder = index
        card.TextSize = 9
        characterCards[id] = card
        card.Activated:Connect(function()
            setSelected(id)
        end)
    end

    choose.Activated:Connect(function()
        combatAction:FireServer("SelectCharacter", selectedId)
        hideAll()
    end)

    local shopPanel = panel("Shop", UDim2.fromScale(0.90, 0.78))
    header(shopPanel, "LOADOUT", "SKINS • MISSIONS • PASSES")

    local tabs = Instance.new("Frame")
    tabs.Size = UDim2.fromScale(0.94, 0.08)
    tabs.Position = UDim2.fromScale(0.03, 0.145)
    tabs.BackgroundTransparency = 1
    tabs.Parent = shopPanel

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 7)
    tabLayout.Parent = tabs

    local content = Instance.new("Frame")
    content.Size = UDim2.fromScale(0.94, 0.70)
    content.Position = UDim2.fromScale(0.03, 0.245)
    content.BackgroundTransparency = 1
    content.Parent = shopPanel

    local function clearContent()
        for _, child in ipairs(content:GetChildren()) do
            child:Destroy()
        end
    end

    local economy = {Credits = 0, OwnedSkins = {}, EquippedSkin = ""}
    local quests = {Daily = {}, Weekly = {}, General = {}}
    local passes = {UltimateSkin = false, KillSound = false, InstantSkin = false}

    local function renderSkins()
        clearContent()

        local list = Instance.new("ScrollingFrame")
        list.Size = UDim2.fromScale(1, 1)
        list.BackgroundTransparency = 1
        list.BorderSizePixel = 0
        list.ScrollBarThickness = 5
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.Parent = content

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = list

        local characterId = player:GetAttribute("CharacterId") or "PotentialMan"

        for id, item in pairs(Shop.Skins) do
            if item.Character == characterId then
                local button = core:Button(list, id, item.Name .. "\n" .. tostring(item.Price) .. " C")
                button.Size = UDim2.new(1, -8, 0, 60)
                button.TextSize = 10
                button.Activated:Connect(function()
                    accountAction:FireServer(
                        if economy.OwnedSkins[id] then "Equip" else "Buy",
                        {category = "Skins", id = id}
                    )
                end)
            end
        end
    end

    local function renderMissions()
        clearContent()

        local list = Instance.new("ScrollingFrame")
        list.Size = UDim2.fromScale(1, 1)
        list.BackgroundTransparency = 1
        list.BorderSizePixel = 0
        list.ScrollBarThickness = 5
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.Parent = content

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = list

        local groups = {
            {"DAILY", quests.Daily},
            {"WEEKLY", quests.Weekly},
            {"GENERAL", quests.General}
        }

        for _, group in ipairs(groups) do
            local heading = core:Label(list, "Heading_" .. group[1], group[1])
            heading.Size = UDim2.new(1, -8, 0, 28)
            heading.TextXAlignment = Enum.TextXAlignment.Left
            heading.TextColor3 = core.Palette.Accent
            heading.Font = Enum.Font.GothamBlack
            heading.TextSize = 12

            for _, quest in ipairs(group[2] or {}) do
                local item = core:Button(list, tostring(quest.Name or "Mission"), tostring(quest.Name or "Mission") .. "\n" .. tostring(quest.Progress or 0) .. " / " .. tostring(quest.Target or 1))
                item.Size = UDim2.new(1, -8, 0, 70)
                item.TextSize = 9
            end
        end
    end

    local function renderPasses()
        clearContent()

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 8)
        list.Parent = content

        local passData = {
            {"UltimateSkin", "ULTIMATE SKIN", "Unlocks premium ultimate presentation."},
            {"KillSound", "KILL SOUND", "Enables a custom confirmed-kill sound."},
            {"InstantSkin", "INSTANT SKIN", "Unlocks an alternate skin purchase flow."}
        }

        for _, entry in ipairs(passData) do
            local key, title, description = entry[1], entry[2], entry[3]
            local button = core:Button(content, key, title .. "\n" .. description .. (passes[key] and "\nOWNED" or "\nBUY"))
            button.Size = UDim2.new(1, 0, 0, 82)
            button.TextSize = 9
            button.Activated:Connect(function()
                local config = GamePassConfig[key]
                if config and tonumber(config.Id) and config.Id > 0 then
                    gamePassAction:FireServer("Prompt", key)
                end
            end)
        end
    end

    local skinTab = core:Button(tabs, "SkinsTab", "SKINS")
    skinTab.Size = UDim2.fromScale(0.31, 0.85)
    local missionTab = core:Button(tabs, "MissionTab", "MISSIONS")
    missionTab.Size = UDim2.fromScale(0.31, 0.85)
    local passTab = core:Button(tabs, "PassTab", "PASSES")
    passTab.Size = UDim2.fromScale(0.31, 0.85)

    skinTab.Activated:Connect(renderSkins)
    missionTab.Activated:Connect(renderMissions)
    passTab.Activated:Connect(renderPasses)

    local leaderboard = panel("Leaderboard", UDim2.fromScale(0.60, 0.66))
    header(leaderboard, "PLAYERS", "CURRENT SERVER")

    local board = Instance.new("ScrollingFrame")
    board.Size = UDim2.fromScale(0.92, 0.72)
    board.Position = UDim2.fromScale(0.04, 0.18)
    board.BackgroundTransparency = 1
    board.BorderSizePixel = 0
    board.ScrollBarThickness = 5
    board.AutomaticCanvasSize = Enum.AutomaticSize.Y
    board.Parent = leaderboard

    local boardLayout = Instance.new("UIListLayout")
    boardLayout.Padding = UDim.new(0, 6)
    boardLayout.Parent = board

    local function renderBoard()
        for _, child in ipairs(board:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        for index, target in ipairs(Players:GetPlayers()) do
            local card = core:Button(board, "Player" .. target.UserId, string.format("%02d  %s  @%s", index, target.DisplayName, target.Name))
            card.Size = UDim2.new(1, -4, 0, 44)
            card.TextSize = 10
            card.LayoutOrder = index
        end
    end
    renderBoard()
    Players.PlayerAdded:Connect(renderBoard)
    Players.PlayerRemoving:Connect(function() task.defer(renderBoard) end)

    local ownerButton = core:Button(root, "OwnerOpen", "OWNER")
    ownerButton.Size = UDim2.fromOffset(82, 46)
    ownerButton.Position = UDim2.fromScale(0.50, 0.018)
    ownerButton.AnchorPoint = Vector2.new(0.5, 0)
    ownerButton.TextColor3 = core.Palette.Warning
    ownerButton.Visible = false

    local owner = panel("Owner", UDim2.fromScale(0.90, 0.80))
    header(owner, "OWNER CONTROL", "SERVER AUTHORIZED")

    local ownerList = Instance.new("UIListLayout")
    ownerList.Padding = UDim.new(0, 8)
    ownerList.Parent = owner
    ownerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ownerList.VerticalAlignment = Enum.VerticalAlignment.Center

    local ownerActions = {
        {"GIVE CREDITS", "GrantCredits", {amount = 1000}},
        {"SET CREDITS", "SetCredits", {amount = 1000}},
        {"GIVE 150 EMOTES", "GiveAllEmotes", {}},
        {"GIVE SKINS", "GiveAllSkins", {}},
        {"HEAL SELF", "Heal", {}},
        {"SAVE ALL", "SaveAll", {}}
    }

    for _, entry in ipairs(ownerActions) do
        local button = core:Button(owner, entry[2], entry[1])
        button.Size = UDim2.fromScale(0.62, 0.09)
        button.Activated:Connect(function()
            local payload = entry[3]
            payload.targetUserId = player.UserId
            adminAction:FireServer(entry[2], payload)
        end)
    end

    ownerButton.Activated:Connect(function()
        open("Owner")
    end)

    local function syncOwner()
        ownerButton.Visible = player:GetAttribute("IsGameOwner") == true
    end

    player:GetAttributeChangedSignal("IsGameOwner"):Connect(syncOwner)
    syncOwner()
    setSelected(selectedId)
    renderSkins()

    return {
        Root = root,
        Open = open,
        HideAll = hideAll,
        RefreshCharacters = setSelected
    }
end

return HUDMenus
