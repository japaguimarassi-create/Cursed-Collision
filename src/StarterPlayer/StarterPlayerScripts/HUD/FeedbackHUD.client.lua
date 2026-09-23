--!strict

local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")

local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="CursedCollisionHUD_Feedback"
gui.ResetOnSpawn=false
gui.ScreenInsets=Enum.ScreenInsets.None
gui.DisplayOrder=60
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")

local layer=Instance.new("Frame"); layer.Size=UDim2.fromScale(1,1); layer.BackgroundTransparency=1; layer.Parent=gui

local function popup(text:string,position:UDim2,kind:string)
    local label=Instance.new("TextLabel")
    label.Size=UDim2.fromScale(0.30,0.055); label.Position=position
    label.AnchorPoint=Vector2.new(0.5,0.5); label.BackgroundTransparency=1; label.Text=text
    label.Font=Enum.Font.GothamBlack; label.TextSize=11; label.TextColor3=
        kind=="Damage" and Color3.fromRGB(255,104,117)
        or kind=="Parry" and Color3.fromRGB(102,211,255)
        or Color3.fromRGB(202,169,255)
    label.Parent=layer
    local start=label.Position
    local finish=UDim2.new(start.X.Scale,start.X.Offset,start.Y.Scale-0.045,start.Y.Offset)
    TweenService:Create(label,TweenInfo.new(0.38,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=finish,TextTransparency=1}):Play()
    Debris:AddItem(label,0.45)
end

local remotes=ReplicatedStorage:WaitForChild("Remotes",30)
local fx=remotes and remotes:WaitForChild("CombatFX",15)
if not fx then return end

fx.OnClientEvent:Connect(function(kind,position,payload)
    if type(kind)~="string" or not payload then return end
    if kind=="Hit" then
        local amount=tonumber(payload.amount) or tonumber(payload.damage) or 0
        if amount>0 and payload.target==player.Character then
            popup("-"..math.floor(amount),UDim2.fromScale(0.58,0.38),"Damage")
        elseif payload.actor==player.Character then
            popup("HIT",UDim2.fromScale(0.52,0.40),"Hit")
        end
    elseif kind=="PerfectBlock" and payload.actor==player.Character then
        popup("PERFECT BLOCK",UDim2.fromScale(0.50,0.30),"Parry")
    elseif kind=="Death" and payload.actor==player.Character then
        popup("ELIMINATED",UDim2.fromScale(0.50,0.30),"Hit")
    end
end)
