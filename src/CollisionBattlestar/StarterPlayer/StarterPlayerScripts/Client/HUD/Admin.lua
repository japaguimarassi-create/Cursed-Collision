--!strict

local Players = game:GetService("Players")

local Admin = {}

function Admin.Mount(root, config, player, remote)
    local mounted = false

    local function mount()
        if mounted or player:GetAttribute("IsOwner") ~= true then
            return
        end
        mounted = true

        local launcher = root.Button(root.Gui, "AdminMenuButton", "CONTROL", UDim2.fromOffset(96, 30))
        launcher.Position = UDim2.fromOffset(18, 82)
        launcher.TextSize = 8
        launcher.BackgroundColor3 = config.UI.Danger

        local overlay = Instance.new("Frame")
        overlay.Name = "AdminOverlay"
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 0.34
        overlay.Visible = false
        overlay.ZIndex = 300
        overlay.Parent = root.Gui

        local window = root.Pill(overlay, UDim2.fromScale(0.92, 0.88), UDim2.fromScale(0.5, 0.5), config.UI.Surface, 0.02)
        window.Name = "AdminControlCenter"
        window.AnchorPoint = Vector2.new(0.5, 0.5)
        window.ZIndex = 301

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, -28, 0, 54)
        header.Position = UDim2.fromOffset(14, 10)
        header.BackgroundTransparency = 1
        header.ZIndex = 302
        header.Parent = window

        local title = root.Label(header, "CONTROL CENTER", 16)
        title.Size = UDim2.new(1, -120, 0, 26)
        title.Position = UDim2.fromOffset(0, 0)
        title.ZIndex = 303

        local sub = root.Label(header, "OWNER • SERVER AUTHORITY", 7, config.UI.Muted, Enum.Font.GothamMedium)
        sub.Size = UDim2.new(1, -120, 0, 16)
        sub.Position = UDim2.fromOffset(1, 27)
        sub.ZIndex = 303

        local close = root.Button(header, "Close", "×", UDim2.fromOffset(38, 38))
        close.Position = UDim2.new(1, -38, 0, 2)
        close.AnchorPoint = Vector2.new(1, 0)
        close.TextSize = 18
        close.ZIndex = 304

        local targetBox = Instance.new("TextBox")
        targetBox.Name = "UserIdBox"
        targetBox.Size = UDim2.fromOffset(150, 32)
        targetBox.Position = UDim2.new(1, -212, 0, 5)
        targetBox.BackgroundColor3 = config.UI.Surface2
        targetBox.BackgroundTransparency = 0.05
        targetBox.BorderSizePixel = 0
        targetBox.Text = ""
        targetBox.PlaceholderText = "USER ID"
        targetBox.PlaceholderColor3 = config.UI.Muted
        targetBox.TextColor3 = config.UI.Text
        targetBox.Font = Enum.Font.GothamMedium
        targetBox.TextSize = 9
        targetBox.ClearTextOnFocus = false
        targetBox.ZIndex = 304
        targetBox.Parent = header
        root.Rounded(targetBox, 10)
        root.Stroke(targetBox, nil, 0.2, 1)

        local tabs = Instance.new("ScrollingFrame")
        tabs.Name = "Categories"
        tabs.Size = UDim2.new(1, -28, 0, 38)
        tabs.Position = UDim2.fromOffset(14, 68)
        tabs.BackgroundTransparency = 1
        tabs.BorderSizePixel = 0
        tabs.AutomaticCanvasSize = Enum.AutomaticSize.X
        tabs.CanvasSize = UDim2.new()
        tabs.ScrollingDirection = Enum.ScrollingDirection.X
        tabs.ScrollBarThickness = 0
        tabs.ZIndex = 302
        tabs.Parent = window

        local tabLayout = Instance.new("UIListLayout")
        tabLayout.FillDirection = Enum.FillDirection.Horizontal
        tabLayout.Padding = UDim.new(0, 7)
        tabLayout.Parent = tabs

        local body = Instance.new("Frame")
        body.Name = "Body"
        body.Size = UDim2.new(1, -28, 1, -118)
        body.Position = UDim2.fromOffset(14, 110)
        body.BackgroundTransparency = 1
        body.ZIndex = 302
        body.Parent = window

        local playerPane = root.Pill(body, UDim2.new(0, 200, 1, 0), UDim2.fromOffset(0, 0), config.UI.Surface2, 0.06)
        playerPane.Name = "PlayerListPane"
        playerPane.ZIndex = 303

        local playerTitle = root.Label(playerPane, "PLAYERS", 9)
        playerTitle.Size = UDim2.new(1, -20, 0, 20)
        playerTitle.Position = UDim2.fromOffset(10, 8)
        playerTitle.ZIndex = 304

        local targetLabel = root.Label(playerPane, "NO TARGET", 8, config.UI.Warning, Enum.Font.GothamMedium)
        targetLabel.Size = UDim2.new(1, -20, 0, 18)
        targetLabel.Position = UDim2.fromOffset(10, 28)
        targetLabel.ZIndex = 304

        local list = Instance.new("ScrollingFrame")
        list.Name = "PlayerList"
        list.Size = UDim2.new(1, -16, 1, -56)
        list.Position = UDim2.fromOffset(8, 50)
        list.BackgroundTransparency = 1
        list.BorderSizePixel = 0
        list.ScrollBarThickness = 3
        list.ZIndex = 304
        list.Parent = playerPane

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 5)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = list

        local actionPane = root.Pill(body, UDim2.new(1, -214, 1, 0), UDim2.fromOffset(214, 0), config.UI.Surface, 0.05)
        actionPane.Name = "ActionPane"
        actionPane.ZIndex = 303

        local context = root.Label(actionPane, "SELECT A CONTROL", 10)
        context.Size = UDim2.new(1, -24, 0, 22)
        context.Position = UDim2.fromOffset(12, 8)
        context.ZIndex = 304

        local contextSub = root.Label(actionPane, "All actions are checked on the server.", 7, config.UI.Muted, Enum.Font.GothamMedium)
        contextSub.Size = UDim2.new(1, -24, 0, 18)
        contextSub.Position = UDim2.fromOffset(12, 29)
        contextSub.ZIndex = 304

        local input = Instance.new("TextBox")
        input.Name = "ValueInput"
        input.Size = UDim2.new(1, -24, 0, 34)
        input.Position = UDim2.fromOffset(12, 52)
        input.BackgroundColor3 = config.UI.Surface2
        input.BackgroundTransparency = 0.05
        input.BorderSizePixel = 0
        input.Text = ""
        input.PlaceholderText = "VALUE / SKIN / COMPANION / MESSAGE"
        input.PlaceholderColor3 = config.UI.Muted
        input.TextColor3 = config.UI.Text
        input.Font = Enum.Font.GothamMedium
        input.TextSize = 9
        input.ClearTextOnFocus = false
        input.ZIndex = 305
        input.Parent = actionPane
        root.Rounded(input, 10)
        root.Stroke(input, nil, 0.2, 1)

        local actions = Instance.new("ScrollingFrame")
        actions.Name = "Actions"
        actions.Size = UDim2.new(1, -24, 1, -96)
        actions.Position = UDim2.fromOffset(12, 94)
        actions.BackgroundTransparency = 1
        actions.BorderSizePixel = 0
        actions.ScrollBarThickness = 3
        actions.ZIndex = 304
        actions.Parent = actionPane

        local grid = Instance.new("UIGridLayout")
        grid.CellPadding = UDim2.fromOffset(7, 7)
        grid.CellSize = UDim2.new(0.5, -4, 0, 38)
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.Parent = actions

        local selectedUserId = 0
        local category = "PLAYERS"
        local categories = {"PLAYERS", "GAMEPLAY", "ECONOMY", "CHARACTER", "SERVER", "TOOLS"}
        local actionDefinitions = {
            PLAYERS = {
                {"Heal", "HEAL"},
                {"Kill", "KILL"},
                {"Respawn", "RESPAWN"},
                {"Bring", "BRING"},
                {"Goto", "GO TO"},
                {"Freeze", "FREEZE"},
                {"Unfreeze", "UNFREEZE"},
                {"God", "GOD MODE"},
                {"Normal", "NORMAL"},
                {"Kick", "KICK"},
                {"Ban", "BAN 1H"},
                {"Ban", "BAN 1D"},
                {"Ban", "BAN 7D"},
                {"Ban", "BAN PERM"},
                {"Unban", "UNBAN ID"},
                {"ZonePvE", "MOVE PVE"},
                {"ZonePvP", "MOVE PVP"},
            },
            GAMEPLAY = {
                {"NextWave", "NEXT WAVE"},
                {"RestartWave", "RESTART WAVE"},
                {"SetWave", "SET WAVE"},
                {"ClearEnemies", "CLEAR ENEMIES"},
                {"SpawnEnemy", "SPAWN ENEMY"},
                {"SpawnElite", "SPAWN ELITE"},
            },
            ECONOMY = {
                {"Credits", "+1K"},
                {"Credits", "+10K"},
                {"Credits", "+100K"},
                {"SetCredits", "SET CREDITS"},
                {"MaxStats", "MAX STATS"},
                {"SetMultiplier", "SET MULTIPLIERS"},
            },
            CHARACTER = {
                {"GrantSkin", "GRANT SKIN"},
                {"EquipSkin", "EQUIP SKIN"},
                {"GrantCompanion", "GRANT COMPANION"},
                {"Heal", "FULL HEAL"},
                {"God", "GOD MODE"},
                {"Normal", "NORMAL"},
            },
            SERVER = {
                {"Lock", "LOCK SERVER"},
                {"Unlock", "UNLOCK SERVER"},
                {"Announcement", "ANNOUNCE"},
                {"TimeDay", "DAY"},
                {"TimeNight", "NIGHT"},
                {"Gravity", "SET GRAVITY"},
                {"Shutdown", "SHUTDOWN"},
            },
            TOOLS = {
                {"Status", "SERVER STATUS"},
                {"Logs", "ADMIN LOGS"},
                {"ClearEnemies", "CLEAN ARENA"},
                {"NextWave", "FORCE WAVE"},
                {"Heal", "HEAL SELF"},
                {"God", "GOD SELF"},
                {"Normal", "NORMAL SELF"},
            },
        }

        local function setTarget(userId: number)
            selectedUserId = userId
            local selected = Players:GetPlayerByUserId(userId)
            targetLabel.Text = selected and (selected.DisplayName .. "  @" .. selected.Name) or ("USER " .. tostring(userId))
            targetLabel.TextColor3 = selected and config.UI.Good or config.UI.Warning
            targetBox.Text = tostring(userId)
        end

        local function numericValue(defaultValue: number): number
            local value = tonumber(input.Text)
            return value or defaultValue
        end

        local function send(action: string, value: any?, rawText: string?)
            local id = selectedUserId
            if category == "SERVER" or category == "TOOLS" or action == "Unban" or action == "Announcement" then
                id = selectedUserId
            end
            remote:FireServer(action, id, value, rawText or input.Text)
            if action ~= "Status" and action ~= "Logs" then
                input.Text = ""
            end
        end

        local function renderActions()
            for _, child in ipairs(actions:GetChildren()) do
                if not child:IsA("UIGridLayout") then
                    child:Destroy()
                end
            end

            local defs = actionDefinitions[category]
            context.Text = category
            contextSub.Text = if category == "PLAYERS" or category == "CHARACTER"
                then (selectedUserId > 0 and ("TARGET • " .. tostring(selectedUserId)) or "Select a player on the left.")
                else "Owner-only server controls."

            for index, def in ipairs(defs) do
                local action = def[1]
                local label = def[2]
                local b = root.Button(actions, "AdminAction_" .. index, label, UDim2.new(0.5, -4, 0, 38))
                b.LayoutOrder = index
                b.TextSize = 8
                b.ZIndex = 305
                if label == "KICK" or string.find(label, "BAN") or label == "KILL" or label == "SHUTDOWN" then
                    b.BackgroundColor3 = config.UI.Danger
                elseif string.find(label, "MAX") or string.find(label, "FULL") or string.find(label, "GOD") then
                    b.BackgroundColor3 = config.UI.Good
                end

                b.Activated:Connect(function()
                    if action == "Ban" then
                        local duration = if label == "BAN 1H" then "1H" elseif label == "BAN 1D" then "1D" elseif label == "BAN 7D" then "7D" else "PERM"
                        send("Ban", duration, input.Text)
                    elseif action == "Credits" then
                        local amount = if label == "+1K" then 1000 elseif label == "+10K" then 10000 else 100000
                        send("Credits", amount)
                    elseif action == "SetCredits" then
                        send("SetCredits", numericValue(0))
                    elseif action == "SetWave" then
                        send("SetWave", numericValue(1))
                    elseif action == "SpawnEnemy" then
                        local tier = math.clamp(math.floor(numericValue(1)), 1, 3)
                        send("SpawnEnemy", tier)
                    elseif action == "Gravity" then
                        local gravity = tonumber(input.Text) or 196.2
                        send("Gravity", gravity)
                    elseif action == "SetMultiplier" then
                        local money, damage, speed = input.Text:match("^(%d+)%s*[,%s]%s*(%d+)%s*[,%s]%s*(%d+)$")
                        send("SetMultiplier", {
                            Money = tonumber(money) or 1,
                            Damage = tonumber(damage) or 1,
                            Speed = tonumber(speed) or 1,
                        })
                    else
                        send(action, input.Text)
                    end
                end)
            end

            local camera = workspace.CurrentCamera
            local width = camera and camera.ViewportSize.X or 1000
            grid.CellSize = if width < 600 then UDim2.new(1, -4, 0, 38) else UDim2.new(0.5, -4, 0, 38)
            actions.CanvasSize = UDim2.fromOffset(0, grid.AbsoluteContentSize.Y + 12)
        end

        local function refreshPlayers()
            for _, child in ipairs(list:GetChildren()) do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end

            local players = Players:GetPlayers()
            table.sort(players, function(a, b)
                return a.Name:lower() < b.Name:lower()
            end)

            for index, target in ipairs(players) do
                local button = root.Button(list, "Player_" .. target.UserId, target.DisplayName, UDim2.new(1, -4, 0, 42))
                button.LayoutOrder = index
                button.TextXAlignment = Enum.TextXAlignment.Left
                button.TextSize = 8
                button.Text = target.DisplayName .. "\n@" .. target.Name
                button.TextWrapped = true
                button.ZIndex = 305
                button.Activated:Connect(function()
                    setTarget(target.UserId)
                end)
                if target.UserId == player.UserId then
                    button.BackgroundColor3 = config.UI.Accent
                end
            end

            list.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 10)

            if selectedUserId > 0 and not Players:GetPlayerByUserId(selectedUserId) then
                targetLabel.Text = "USER " .. tostring(selectedUserId)
            end
        end

        for index, name in ipairs(categories) do
            local tab = root.Button(tabs, "AdminTab_" .. name, name, UDim2.fromOffset(96, 34))
            tab.LayoutOrder = index
            tab.TextSize = 7
            tab.ZIndex = 303
            tab.Activated:Connect(function()
                category = name
                renderActions()
            end)
        end

        launcher.Activated:Connect(function()
            overlay.Visible = true
            refreshPlayers()
            renderActions()
            window.Size = UDim2.fromScale(0.88, 0.82)
            root.AnimateIn(window, "Down")
        end)

        close.Activated:Connect(function()
            overlay.Visible = false
        end)

        targetBox.FocusLost:Connect(function()
            local id = tonumber(targetBox.Text)
            if id and id > 0 then
                setTarget(math.floor(id))
            end
        end)

        Players.PlayerAdded:Connect(function()
            if overlay.Visible then
                refreshPlayers()
            end
        end)

        Players.PlayerRemoving:Connect(function(target)
            if target.UserId == selectedUserId then
                targetLabel.Text = "USER " .. tostring(selectedUserId)
            end
            if overlay.Visible then
                refreshPlayers()
            end
        end)

        renderActions()
        refreshPlayers()
    end

    if player:GetAttribute("IsOwner") == true then
        mount()
    else
        player:GetAttributeChangedSignal("IsOwner"):Connect(mount)
    end

    return nil
end

return Admin
