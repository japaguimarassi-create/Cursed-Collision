--!strict
local ContextActionService=game:GetService("ContextActionService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local actionRemote=ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Action")::RemoteEvent
local Controller={}; local initialized=false
local function bind(name:string,inputs:{Enum.KeyCode|Enum.UserInputType},actionName:string)
    ContextActionService:UnbindAction(name)
    ContextActionService:BindAction(name,function(_,state)
        if state==Enum.UserInputState.Begin then actionRemote:FireServer(actionName) end
        return Enum.ContextActionResult.Sink
    end,false,table.unpack(inputs))
end
function Controller:Init()
    if initialized then return end
    bind("CBS_Attack",{Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2},"M1")
    bind("CBS_Dash",{Enum.KeyCode.Q,Enum.KeyCode.ButtonB},"Dash")
    initialized=true
end
return Controller