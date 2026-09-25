--!strict
local RunService=game:GetService("RunService");local Players=game:GetService("Players");local p=Players.LocalPlayer;local cam=workspace.CurrentCamera
RunService:BindToRenderStep("CBS_Camera",Enum.RenderPriority.Camera.Value+1,function()
	local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local target=70
	if h then target+=h.MoveDirection.Magnitude*3 end
	if p:GetAttribute("Overdrive")==true then target+=5 end
	cam.FieldOfView+=(target-cam.FieldOfView)*.08
end)
