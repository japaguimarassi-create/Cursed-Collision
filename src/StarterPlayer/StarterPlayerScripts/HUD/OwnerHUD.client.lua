--!strict

local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")

local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="CursedCollisionHUD_Owner"
gui.ResetOnSpawn=false
gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
gui.DisplayOrder=45
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")

local root=Instance.new("Frame"); root.Size=UDim2.fromScale(1,1); root.BackgroundTransparency=1; root.Parent=gui
local panel=Instance.new("Frame")
panel.Name="OwnerPanel"; panel.Size=UDim2.fromScale(0.82,0.72); panel.Position=UDim2.fromScale(0.5,0.52); panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.BackgroundColor3=Color3.fromRGB(12,13,18); panel.Visible=false; panel.Parent=root
local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,16); c.Parent=panel
local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(255,177,76); s.Thickness=1.5; s.Parent=panel

local title=Instance.new("TextLabel"); title.Size=UDim2.fromScale(0.7,0.08); title.Position=UDim2.fromScale(0.04,0.03); title.BackgroundTransparency=1; title.Text="OWNER CONTROL"; title.Font=Enum.Font.GothamBlack; title.TextSize=19; title.TextColor3=Color3.fromRGB(255,177,76); title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=panel
local close=Instance.new("TextButton"); close.Size=UDim2.fromScale(0.07,0.075); close.Position=UDim2.fromScale(0.92,0.025); close.Text="×"; close.Font=Enum.Font.GothamBlack; close.TextSize=22; close.TextColor3=Color3.fromRGB(240,241,246); close.BackgroundColor3=Color3.fromRGB(22,25,34); close.BorderSizePixel=0; close.Parent=panel
local cc=Instance.new("UICorner"); cc.CornerRadius=UDim.new(0,10); cc.Parent=close

local amount=Instance.new("TextBox"); amount.Size=UDim2.fromScale(0.40,0.08); amount.Position=UDim2.fromScale(0.04,0.15); amount.Text="1000"; amount.PlaceholderText="Amount"; amount.TextColor3=Color3.fromRGB(240,241,246); amount.BackgroundColor3=Color3.fromRGB(21,24,32); amount.Font=Enum.Font.Gotham; amount.TextSize=12; amount.ClearTextOnFocus=false; amount.Parent=panel
local ac=Instance.new("UICorner"); ac.CornerRadius=UDim.new(0,9); ac.Parent=amount

local targetId=player.UserId

local function action(name:string,payload:any?)
    local remotes=ReplicatedStorage:FindFirstChild("Remotes"); local admin=remotes and remotes:FindFirstChild("AdminAction")
    if not admin or not admin:IsA("RemoteEvent") then return end
    local data=payload or {}; data.targetUserId=targetId; admin:FireServer(name,data)
end

local function make(text:string,x:number,y:number)
    local b=Instance.new("TextButton"); b.Size=UDim2.fromScale(0.40,0.09); b.Position=UDim2.fromScale(x,y); b.Text=text; b.Font=Enum.Font.GothamBlack; b.TextSize=10; b.TextColor3=Color3.fromRGB(240,241,246); b.BackgroundColor3=Color3.fromRGB(21,24,32); b.BorderSizePixel=0; b.Parent=panel; local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=b; return b
end

local give=make("GIVE CREDITS",0.04,0.26)
local heal=make("HEAL SELF",0.51,0.26)
local allEmotes=make("GIVE ALL EMOTES",0.04,0.38)
local allSkins=make("GIVE ALL SKINS",0.51,0.38)
local save=make("SAVE",0.04,0.50)
local kick=make("KICK",0.51,0.50)
local broadcastBox=Instance.new("TextBox"); broadcastBox.Size=UDim2.fromScale(0.87,0.09); broadcastBox.Position=UDim2.fromScale(0.04,0.64); broadcastBox.PlaceholderText="Owner broadcast"; broadcastBox.TextColor3=Color3.fromRGB(240,241,246); broadcastBox.BackgroundColor3=Color3.fromRGB(21,24,32); broadcastBox.Parent=panel; local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,9); bc.Parent=broadcastBox
local broadcast=make("BROADCAST",0.04,0.77)
local note=Instance.new("TextLabel"); note.Size=UDim2.fromScale(0.42,0.12); note.Position=UDim2.fromScale(0.51,0.75); note.BackgroundTransparency=1; note.Text="Server-authorized owner panel"; note.Font=Enum.Font.Gotham; note.TextSize=8; note.TextColor3=Color3.fromRGB(155,158,176); note.TextWrapped=true; note.Parent=panel

give.Activated:Connect(function() action("GrantCredits",{amount=tonumber(amount.Text) or 0}) end)
heal.Activated:Connect(function() action("Heal") end)
allEmotes.Activated:Connect(function() action("GiveAllEmotes") end)
allSkins.Activated:Connect(function() action("GiveAllSkins") end)
save.Activated:Connect(function() action("SaveAll",{targetUserId=player.UserId}) end)
kick.Activated:Connect(function() action("Kick",{reason="Removed by Cursed Collision Owner."}) end)
broadcast.Activated:Connect(function()
    local remotes=ReplicatedStorage:FindFirstChild("Remotes"); local admin=remotes and remotes:FindFirstChild("AdminAction")
    if admin and admin:IsA("RemoteEvent") then admin:FireServer("Announce",{message=broadcastBox.Text}) end
    broadcastBox.Text=""
end)
close.Activated:Connect(function() panel.Visible=false; player:SetAttribute("CCHUD_OwnerPanelOpen",false) end)

player:GetAttributeChangedSignal("CCHUD_OwnerPanelOpen"):Connect(function()
    local open=player:GetAttribute("CCHUD_OwnerPanelOpen")==true and player:GetAttribute("IsGameOwner")==true
    panel.Visible=open
    if open then
        player:SetAttribute("CCHUD_MenuOpen",false)
        player:SetAttribute("CCHUD_CharacterMenuOpen",false)
        player:SetAttribute("CCHUD_EmoteWheelOpen",false)
    end
end)
player:GetAttributeChangedSignal("IsGameOwner"):Connect(function()
    if player:GetAttribute("IsGameOwner")~=true then
        panel.Visible=false
        player:SetAttribute("CCHUD_OwnerPanelOpen",false)
    end
end)
if player:GetAttribute("IsGameOwner")==true and player:GetAttribute("CCHUD_OwnerPanelOpen")==true then panel.Visible=true end
UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.P then
        if player:GetAttribute("IsGameOwner")==true then
            player:SetAttribute("CCHUD_OwnerPanelOpen",not(player:GetAttribute("CCHUD_OwnerPanelOpen")==true))
        end
    end
end)
