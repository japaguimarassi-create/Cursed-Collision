--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local player=Players.LocalPlayer
local rootFolder=script.Parent
local HUD=rootFolder:WaitForChild("HUD",15)
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Root=require(HUD:WaitForChild("Root"))
local Status=require(HUD:WaitForChild("Status"))
local Economy=require(HUD:WaitForChild("Economy"))
local Profile=require(HUD:WaitForChild("Profile"))
local Vitals=require(HUD:WaitForChild("Vitals"))
local Actions=require(HUD:WaitForChild("Actions"))
local Navigation=require(HUD:WaitForChild("Navigation"))
local Feedback=require(HUD:WaitForChild("Feedback"))
local Admin=require(HUD:WaitForChild("Admin"))
local Controller={}; local initialized=false
local function getRemotes()
    local remotes=ReplicatedStorage:WaitForChild("Remotes",15); if not remotes then error("Remotes unavailable") end
    local state=remotes:WaitForChild("State",15); local action=remotes:WaitForChild("Action",15); local travel=remotes:WaitForChild("Travel",15); local admin=remotes:WaitForChild("AdminAction",15)
    if not state or not action or not travel or not admin then error("HUD remotes unavailable") end
    return state::RemoteEvent,action::RemoteEvent,travel::RemoteEvent,admin::RemoteEvent
end
local function hideDefaultHealth()
    for _=1,5 do
        local ok=pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,false) end)
        if ok then return end
        task.wait(0.1)
    end
end
function Controller:Init()
    if initialized then
        local existing=player.PlayerGui:FindFirstChild("CollisionBattlestarHUD")
        if existing then player:SetAttribute("CollisionHUDReady",true); return existing end
        initialized=false
    end
    hideDefaultHealth()
    local stateRemote,actionRemote,travelRemote,adminRemote=getRemotes()
    local gui=Root.Create(player)
    local root={Gui=gui,Panel=Root.Panel,Label=Root.Label,Button=Root.Button,Rounded=Root.Rounded,Stroke=Root.Stroke,Gradient=Root.Gradient,Progress=Root.Progress,AnimateIn=Root.AnimateIn}
    Profile.Mount(root,Config,player)
    local status=Status.Mount(root,Config)
    Economy.Mount(root,Config,player)
    Vitals.Mount(root,Config,player)
    local actions=Actions.Mount(root)
    Navigation.Mount(root,Config,player,travelRemote)
    local feedback=Feedback.Mount(root,Config)
    Admin.Mount(root,Config,player,adminRemote)
    actions.M1.Button.Activated:Connect(function() if actions.M1.Activate() then actionRemote:FireServer("M1") end end)
    actions.Dash.Button.Activated:Connect(function() if actions.Dash.Activate() then actionRemote:FireServer("Dash") end end)
    stateRemote.OnClientEvent:Connect(function(kind:string,a,b)
        if kind=="WaveIntermission" then
            status.Phase.Text="NEXT ENGAGEMENT"; status.Wave.Text="WAVE "..tostring(workspace:GetAttribute("CollisionWave") or 0); status.Countdown.Visible=true; status.Countdown.Text=("START IN %ds"):format(tonumber(a) or 0); status.Enemies.Text="READY"; status.Pulse()
        elseif kind=="WaveStart" then
            status.Phase.Text="ACTIVE WAVE"; status.Wave.Text=("WAVE %d"):format(tonumber(a) or 0); status.Enemies.Text=("%d TARGETS"):format(tonumber(b) or 0); status.Countdown.Visible=false; status.Pulse(); Feedback.Show(feedback,Config,"ELITE CONTACT",Config.UI.Danger,1.6)
        elseif kind=="WaveState" then
            status.Phase.Text="ACTIVE WAVE"; status.Wave.Text=("WAVE %d"):format(tonumber(a) or 0); status.Enemies.Text=("%d TARGETS"):format(tonumber(b) or 0); status.Countdown.Visible=false
        elseif kind=="Reward" then
            Feedback.Show(feedback,Config,("+%d CREDITS"):format(tonumber(a) or 0),Config.UI.Good,1)
        elseif kind=="WaveReward" then
            Feedback.Show(feedback,Config,("WAVE %d CLEAR  •  +%d CREDITS"):format(tonumber(b) or 0,tonumber(a) or 0),Config.UI.Good,2)
        elseif kind=="WaveClear" then
            status.Enemies.Text="AREA CLEAR"; Feedback.Show(feedback,Config,"AREA CLEAR",Config.UI.Accent,1.5)
        elseif kind=="ShopMessage" then
            Feedback.Show(feedback,Config,tostring(a),Config.UI.Warning,1.6)
        elseif kind=="Zone" then
            local pvp=tostring(a)=="PvP"; status.Zone.Text=pvp and "PVP BATTLEGROUNDS" or "PVE CITY"; status.Zone.TextColor3=pvp and Config.UI.Danger or Config.UI.Muted
        elseif kind=="PvpHit" then
            Feedback.Show(feedback,Config,("-%d HP"):format(tonumber(a) or 0),Config.UI.Warning,0.7)
        elseif kind=="Attack" then
            Feedback.Show(feedback,Config,"STRIKE",Config.UI.Accent,0.28)
        end
    end)
    workspace:GetAttributeChangedSignal("CollisionWave"):Connect(function() status.Wave.Text=("WAVE %d"):format(workspace:GetAttribute("CollisionWave") or 0) end)
    workspace:GetAttributeChangedSignal("CollisionEnemies"):Connect(function() status.Enemies.Text=("%d TARGETS"):format(workspace:GetAttribute("CollisionEnemies") or 0) end)
    player:GetAttributeChangedSignal("Zone"):Connect(function()
        local pvp=(player:GetAttribute("Zone") or "PvE")=="PvP"; status.Zone.Text=pvp and "PVP BATTLEGROUNDS" or "PVE CITY"; status.Zone.TextColor3=pvp and Config.UI.Danger or Config.UI.Muted
    end)
    status.Wave.Text=("WAVE %d"):format(workspace:GetAttribute("CollisionWave") or 0)
    status.Enemies.Text=("%d TARGETS"):format(workspace:GetAttribute("CollisionEnemies") or 0)
    status.Zone.Text=(player:GetAttribute("Zone") or "PvE")=="PvP" and "PVP BATTLEGROUNDS" or "PVE CITY"
    player:SetAttribute("CollisionHUDReady",true); initialized=true
    task.delay(0.2,function() local boot=player.PlayerGui:FindFirstChild("CollisionBattlestarImmediateHUD"); if boot then boot:Destroy() end end)
    return gui
end
return Controller