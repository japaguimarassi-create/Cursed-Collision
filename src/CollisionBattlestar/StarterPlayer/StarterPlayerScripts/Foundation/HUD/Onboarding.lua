--!strict

local Components=require(script.Parent:WaitForChild("Components"))
local Theme=require(script.Parent:WaitForChild("Theme"))

local Onboarding={}
Onboarding.__index=Onboarding

function Onboarding.Create(rootFrame:Frame,player:Player)
    local self=setmetatable({},Onboarding)
    local panel=Components.Panel(rootFrame,"Onboarding",UDim2.fromOffset(440,290),UDim2.new(.5,-220,.5,-145),18)
    panel.ZIndex=60
    self.panel=panel
    Components.Label(panel,"Title","THE COLLISION HAS BEGUN",UDim2.new(1,-36,0,34),UDim2.fromOffset(18,20),22,Theme.Colors.Text,true).ZIndex=61
    Components.Label(panel,"Subtitle","Fight. Hunt the red Elite. Upgrade. Survive.",UDim2.new(1,-36,0,26),UDim2.fromOffset(18,58),12,Theme.Colors.Cyan,true).ZIndex=61

    local body=Components.Label(panel,"Body","1  ATTACK — M1\n2  DASH — Q / B\n3  DEFEAT THE RED ELITE\n4  SPEND CREDITS AT THE SHOP\n5  YOUR FRIEND ECHO CAN FIGHT BESIDE YOU",UDim2.new(1,-36,0,130),UDim2.fromOffset(18,94),13,Theme.Colors.Muted,false)
    body.TextWrapped=true
    body.TextYAlignment=Enum.TextYAlignment.Top
    body.ZIndex=61

    local start=Components.Button(panel,"Start","ENTER THE ARENA",UDim2.fromOffset(170,44),UDim2.new(.5,-85,1,-64),Theme.Colors.CyanDark,12,12)
    start.ZIndex=61
    start.Activated:Connect(function() self:Dismiss() end)

    return self
end

function Onboarding:Dismiss()
    self.panel.Visible=false
end

function Onboarding:Destroy()
    if self.panel then self.panel:Destroy() end
end

return Onboarding
