--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes",30)
local accountAction = remotes and remotes:WaitForChild("AccountAction",15)
local accountEvent = remotes and remotes:WaitForChild("AccountEvent",15)
local passAction = remotes and remotes:WaitForChild("GamePassAction",15)
local passEvent = remotes and remotes:WaitForChild("GamePassEvent",15)
if not accountAction or not accountEvent or not passAction or not passEvent then return end

local Shop = require(ReplicatedStorage.Economy.ShopDefinitions)
local Passes = require(ReplicatedStorage.Monetization.GamePassConfig)

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionHUD_Menu"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.DisplayOrder = 35
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1,1)
root.BackgroundTransparency = 1
root.Parent = gui

local backdrop = Instance.new("TextButton")
backdrop.Size = UDim2.fromScale(1,1)
backdrop.BackgroundColor3 = Color3.fromRGB(3,4,7)
backdrop.BackgroundTransparency = 0.34
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.Parent = root

local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(0.86,0.80)
panel.Position = UDim2.fromScale(0.50,0.51)
panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.BackgroundColor3 = Color3.fromRGB(11,13,19)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = root
local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0,18)
pc.Parent = panel
local ps = Instance.new("UIStroke")
ps.Color = Color3.fromRGB(99,194,255)
ps.Transparency = 0.30
ps.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(0.65,0.08)
title.Position = UDim2.fromScale(0.04,0.03)
title.BackgroundTransparency = 1
title.Text = "CURSED COLLISION"
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(240,241,246)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local credits = Instance.new("TextLabel")
credits.Size = UDim2.fromScale(0.28,0.06)
credits.Position = UDim2.fromScale(0.63,0.04)
credits.BackgroundTransparency = 1
credits.Text = "0 C"
credits.Font = Enum.Font.GothamBlack
credits.TextSize = 12
credits.TextColor3 = Color3.fromRGB(255,211,102)
credits.TextXAlignment = Enum.TextXAlignment.Right
credits.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromScale(0.07,0.075)
close.Position = UDim2.fromScale(0.92,0.025)
close.Text = "×"
close.Font = Enum.Font.GothamBlack
close.TextSize = 22
close.TextColor3 = Color3.fromRGB(240,241,246)
close.BackgroundColor3 = Color3.fromRGB(20,23,31)
close.BorderSizePixel = 0
close.Parent = panel
local ccc=Instance.new("UICorner"); ccc.CornerRadius=UDim.new(0,10); ccc.Parent=close

local tabs = Instance.new("Frame")
tabs.Size = UDim2.fromScale(0.88,0.08)
tabs.Position = UDim2.fromScale(0.06,0.14)
tabs.BackgroundTransparency = 1
tabs.Parent = panel

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.fromScale(0.88,0.68)
content.Position = UDim2.fromScale(0.06,0.24)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.fromOffset(0,0)
content.ScrollBarThickness = 4
content.Selectable = true
content.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,8)
layout.Parent = content

local state = {tab="Shop", economy={Credits=0,OwnedSkins={}}, quests={Daily={},Weekly={},General={}}, passes={UltimateSkin=false,InstantSkin=false,KillSound=false}}

local function simpleButton(text:string, x:number)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromScale(0.30,0.90); b.Position=UDim2.fromScale(x,0)
    b.Text=text; b.Font=Enum.Font.GothamBlack; b.TextSize=9
    b.TextColor3=Color3.fromRGB(240,241,246); b.BackgroundColor3=Color3.fromRGB(21,24,32)
    b.BorderSizePixel=0; b.Selectable=true; b.Parent=tabs
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,9); c.Parent=b
    return b
end

local tabShop=simpleButton("SHOP",0)
local tabQuest=simpleButton("MISSIONS",0.35)
local tabPass=simpleButton("PASSES",0.70)

local function clear()
    for _,child in ipairs(content:GetChildren()) do
        if child ~= layout then child:Destroy() end
    end
end

local function row(textValue:string, order:number, callback:(()->())?)
    local b=Instance.new("TextButton")
    b.LayoutOrder=order
    b.Size=UDim2.new(1,-6,0,74)
    b.Text=textValue
    b.TextWrapped=true
    b.TextXAlignment=Enum.TextXAlignment.Left
    b.TextYAlignment=Enum.TextYAlignment.Center
    b.Font=Enum.Font.GothamBold
    b.TextSize=10
    b.TextColor3=Color3.fromRGB(240,241,246)
    b.BackgroundColor3=Color3.fromRGB(20,23,31)
    b.BorderSizePixel=0
    b.Selectable=true
    b.Parent=content
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=b
    if callback then b.Activated:Connect(callback) end
    return b
end

local function renderShop()
    clear()
    local i=0
    for _,item in pairs(Shop.Skins) do
        local char=tostring(player:GetAttribute("CharacterId") or "PotentialMan")
        if item.Character==char then
            i+=1
            local owned=state.economy.OwnedSkins[item.Id]==true
            row(item.Name.."\n"..(owned and "OWNED" or tostring(item.Price).." C"),i,function()
                accountAction:FireServer(owned and "Equip" or "Buy",{category="Skins",id=item.Id})
            end)
        end
    end
end

local function renderMissions()
    clear()
    local order=0
    for _,section in ipairs({"Daily","Weekly","General"}) do
        order+=1
        local h=row(section:upper(),order,nil)
        h.TextXAlignment=Enum.TextXAlignment.Left
        h.TextColor3=Color3.fromRGB(157,117,255)
        for _,q in ipairs(state.quests[section] or {}) do
            order+=1
            row(tostring(q.Name or "Mission").."\n"..tostring(q.Progress or 0).."/"..tostring(q.Target or 1).."  •  +"..tostring(q.Reward or 0).." C",order,nil)
        end
    end
end

local function renderPasses()
    clear()
    local order=0
    local names={UltimateSkin="ULTIMATE SKIN",InstantSkin="INSTANT SKIN",KillSound="KILL SOUND"}
    for _,key in ipairs({"UltimateSkin","InstantSkin","KillSound"}) do
        order+=1
        row(names[key].."\n"..(state.passes[key] and "OWNED" or "PURCHASE"),order,function()
            local info=Passes[key]
            if info and type(info.Id)=="number" and info.Id>0 then
                pcall(function() MarketplaceService:PromptGamePassPurchase(player,info.Id) end)
            end
        end)
    end
end

local function render()
    if state.tab=="Shop" then renderShop() elseif state.tab=="Missions" then renderMissions() else renderPasses() end
end

local function closePanel()
    panel.Visible=false; backdrop.Visible=false; player:SetAttribute("CCHUD_MenuOpen",false)
end

local function openPanel()
    player:SetAttribute("CCHUD_CharacterMenuOpen",false); player:SetAttribute("CCHUD_EmoteWheelOpen",false); player:SetAttribute("CCHUD_OwnerPanelOpen",false)
    player:SetAttribute("CCHUD_MenuOpen",true)
    panel.Visible=true; backdrop.Visible=true
    accountAction:FireServer("Sync",{}); passAction:FireServer("Sync",{})
    render()
    if UserInputService.PreferredInput==Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled=true
        GuiService.SelectedObject=tabShop
    end
end

close.Activated:Connect(closePanel)
backdrop.Activated:Connect(closePanel)

tabShop.Activated=function() state.tab="Shop"; render() end
tabQuest.Activated=function() state.tab="Missions"; render() end
tabPass.Activated=function() state.tab="Passes"; render() end

accountEvent.OnClientEvent:Connect(function(event,payload)
    if event=="Sync" and payload then
        state.economy=payload.Economy or state.economy
        state.quests=payload.Quests or state.quests
        credits.Text=tostring(state.economy.Credits or 0).." C"
        if panel.Visible then render() end
    end
end)

passEvent.OnClientEvent:Connect(function(event,payload)
    if event=="Sync" then
        for key,value in pairs(payload or {}) do
            if state.passes[key]~=nil then state.passes[key]=value==true end
        end
        if panel.Visible and state.tab=="Passes" then render() end
    end
end)

player:GetAttributeChangedSignal("CCHUD_MenuOpen"):Connect(function()
    if player:GetAttribute("CCHUD_MenuOpen")==true then openPanel() else closePanel() end
end)

player:GetAttributeChangedSignal("CharacterId"):Connect(function()
    if panel.Visible and state.tab=="Shop" then render() end
end)

UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.ButtonStart then
        if panel.Visible then closePanel() else openPanel() end
    end
end)
