--!strict

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local root = script.Parent

local function ensureBootGui()
    local playerGui = player:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("HUDBoot")
    if existing then
        return existing
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "HUDBoot"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.IgnoreGuiInset = false
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = playerGui

    local label = Instance.new("TextLabel")
    label.Name = "Status"
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = UDim2.fromScale(0.5, 0.5)
    label.Size = UDim2.fromOffset(260, 44)
    label.BackgroundTransparency = 0.15
    label.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
    label.Text = "COLLISION BATTLESTAR  •  LOADING"
    label.TextColor3 = Color3.fromRGB(242, 245, 250)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = label

    return gui
end

local bootGui = ensureBootGui()

task.spawn(function()
    local UIController = require(root:WaitForChild("UIController"))
    local loaded = false

    for _ = 1, 5 do
        local ok = pcall(function()
            UIController:Init()
        end)
        if ok then
            loaded = true
            break
        end
        task.wait(1)
    end

    if loaded then
        if bootGui.Parent then
            bootGui:Destroy()
        end
    else
        local status = bootGui:FindFirstChild("Status")
        if status and status:IsA("TextLabel") then
            status.Text = "HUD ERROR  •  REJOIN TO RETRY"
        end
    end
end)

task.spawn(function()
    local ok, InputController = pcall(function()
        return require(root:WaitForChild("InputController"))
    end)
    if not ok then
        return
    end

    for _ = 1, 3 do
        local initialized = pcall(function()
            InputController:Init()
        end)
        if initialized then
            return
        end
        task.wait(1)
    end
end)
