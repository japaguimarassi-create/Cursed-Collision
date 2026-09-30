--!strict

local Components=require(script.Parent:WaitForChild("Components"))
local Theme=require(script.Parent:WaitForChild("Theme"))

local TestLab={}
TestLab.__index=TestLab

function TestLab.Create(rootFrame:Frame,remote:RemoteEvent,player:Player)
    local self=setmetatable({remote=remote,player=player},TestLab)
    local owner=game.CreatorType==Enum.CreatorType.User and player.UserId==game.CreatorId
    if not owner then return self end
    local button=Components.Button(rootFrame,"TestLabButton","TEST LAB",UDim2.fromOffset(104,36),UDim2.new(1,-122,1,-66),Theme.Colors.RedDark,10,10)
    button.ZIndex=35
    button.Activated:Connect(function() remote:FireServer("Teleport") end)
    self.button=button
    return self
end

function TestLab:Destroy()
    if self.button then self.button:Destroy() end
end

return TestLab
