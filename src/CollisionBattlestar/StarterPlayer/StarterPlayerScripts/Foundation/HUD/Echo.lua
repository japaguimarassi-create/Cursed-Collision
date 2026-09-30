--!strict

local Components=require(script.Parent:WaitForChild("Components"))
local Theme=require(script.Parent:WaitForChild("Theme"))
local Invite=require(script.Parent.Parent:WaitForChild("SocialInvite"))

local Echo={}
Echo.__index=Echo

function Echo.Create(rootFrame:Frame,remote:RemoteEvent,player:Player)
    local self=setmetatable({remote=remote,player=player,connections={},classId="Vanguard"},Echo)
    local panel=Components.Panel(rootFrame,"EchoPanel",UDim2.fromOffset(400,500),UDim2.new(.5,-200,.5,-250),16)
    panel.Visible=false
    panel.ZIndex=40
    self.panel=panel

    local title=Components.Label(panel,"Title","FRIEND ECHO",UDim2.new(1,-120,0,30),UDim2.fromOffset(18,14),20,Theme.Colors.Text,true)
    title.ZIndex=41
    local subtitle=Components.Label(panel,"Subtitle","Choose an owned class, then bring a friend into the fight.",UDim2.new(1,-36,0,34),UDim2.fromOffset(18,43),11,Theme.Colors.Muted,false)
    subtitle.TextWrapped=true
    subtitle.ZIndex=41

    local close=Components.Button(panel,"Close","CLOSE",UDim2.fromOffset(72,32),UDim2.new(1,-88,0,12),Theme.Colors.PanelSoft,10,10)
    close.ZIndex=41
    close.Activated:Connect(function() self:Toggle(false) end)

    local selector=Instance.new("Frame")
    selector.Name="Classes"
    selector.Size=UDim2.new(1,-36,0,42)
    selector.Position=UDim2.fromOffset(18,82)
    selector.BackgroundTransparency=1
    selector.Parent=panel
    selector.ZIndex=41
    self.selector=selector
    local list=Instance.new("UIListLayout")
    list.FillDirection=Enum.FillDirection.Horizontal
    list.Padding=UDim.new(0,6)
    list.Parent=selector

    for _,classId in ipairs({"Vanguard","Striker","Guardian","Support"}) do
        local button=Components.Button(selector,classId,classId,UDim2.fromOffset(82,36),UDim2.fromOffset(),Theme.Colors.PanelSoft,9,9)
        button.ZIndex=42
        button.Activated:Connect(function()
            self.classId=classId
            self:RefreshClassButtons()
        end)
        self[classId]=button
    end
    self:RefreshClassButtons()

    local invite=Components.Button(panel,"Invite","INVITE FRIENDS",UDim2.fromOffset(150,36),UDim2.fromOffset(18,130),Theme.Colors.CyanDark,10,10)
    invite.ZIndex=41
    invite.Activated:Connect(function()
        if not Invite.PromptCurrentPlayer() then
            self:Message("INVITE UNAVAILABLE")
        end
    end)

    local dismiss=Components.Button(panel,"Dismiss","DISMISS ECHO",UDim2.fromOffset(130,36),UDim2.fromOffset(178,130),Theme.Colors.RedDark,10,10)
    dismiss.ZIndex=41
    dismiss.Activated:Connect(function() remote:FireServer("Dismiss") end)

    local message=Components.Label(panel,"Message","",UDim2.new(1,-36,0,22),UDim2.fromOffset(18,170),11,Theme.Colors.Cyan,true)
    message.ZIndex=41
    self.message=message

    local friends=Instance.new("ScrollingFrame")
    friends.Name="Friends"
    friends.Size=UDim2.new(1,-36,1,-208)
    friends.Position=UDim2.fromOffset(18,198)
    friends.BackgroundTransparency=1
    friends.BorderSizePixel=0
    friends.ScrollBarThickness=5
    friends.AutomaticCanvasSize=Enum.AutomaticSize.Y
    friends.Parent=panel
    friends.ZIndex=41
    self.friends=friends
    local friendLayout=Instance.new("UIListLayout")
    friendLayout.Padding=UDim.new(0,7)
    friendLayout.Parent=friends

    table.insert(self.connections,remote.OnClientEvent:Connect(function(kind,...)
        local args={...}
        if kind=="Friends" then self:RenderFriends(args[1])
        elseif kind=="Failed" then self:Message(tostring(args[1] or "FAILED"))
        elseif kind=="Summoned" then self:Message("ECHO ACTIVE • "..tostring(args[2] or self.classId))
        elseif kind=="Dismissed" then self:Message("ECHO DISMISSED")
        end
    end))
    return self
end

function Echo:RefreshClassButtons()
    for _,classId in ipairs({"Vanguard","Striker","Guardian","Support"}) do
        local button=self[classId]
        button.BackgroundColor3=if classId==self.classId then Theme.Colors.CyanDark else Theme.Colors.PanelSoft
    end
end

function Echo:ClearFriends()
    for _,child in ipairs(self.friends:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
end

function Echo:RenderFriends(entries)
    self:ClearFriends()
    for _,friend in ipairs(entries or {}) do
        local row=Components.Panel(self.friends,"Friend",UDim2.new(1,-8,0,64),UDim2.fromOffset(),10)
        row.ZIndex=42
        local name=Components.Label(row,"Name",tostring(friend.DisplayName or friend.Username),UDim2.new(1,-116,0,22),UDim2.fromOffset(10,8),13,Theme.Colors.Text,true)
        name.ZIndex=43
        local state=Components.Label(row,"State",friend.Online and "ONLINE — PLAYING" or "READY FOR ECHO",UDim2.new(1,-116,0,20),UDim2.fromOffset(10,31),10,friend.Online and Theme.Colors.Yellow or Theme.Colors.Muted,false)
        state.ZIndex=43
        local button=Components.Button(row,"Summon",friend.Online and "ONLINE" or "SUMMON",UDim2.fromOffset(88,38),UDim2.new(1,-98,0,13),friend.Online and Theme.Colors.PanelSoft or Theme.Colors.CyanDark,10,9)
        button.ZIndex=43
        button.AutoButtonColor=not friend.Online
        if not friend.Online then
            button.Activated:Connect(function() self.remote:FireServer("Summon",friend.UserId,self.classId) end)
        end
    end
end

function Echo:Message(text:string)
    self.message.Text=text
    task.delay(2,function() if self.message.Text==text then self.message.Text="" end end)
end

function Echo:Request()
    self.remote:FireServer("List")
end

function Echo:Toggle(open:boolean?)
    local value=if open==nil then not self.panel.Visible else open
    self.panel.Visible=value
    if value then self:Request() end
end

function Echo:Destroy()
    for _,c in ipairs(self.connections) do c:Disconnect() end
    if self.panel then self.panel:Destroy() end
end

return Echo
