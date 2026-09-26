--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local HUDLayout=require(ReplicatedStorage.Shared.UI.HUDLayout)

local M={}
local lastError=""

local function ready(gui:ScreenGui?):boolean
	if not gui or not gui:IsA("ScreenGui") then return false end
	if gui:GetAttribute("HUDLayoutReady")~=true then return false end
	if gui:GetAttribute("InputBindingsReady")~=true then return false end
	local status=gui:FindFirstChild("StatusFrame")
	local health=status and status:FindFirstChild("HealthBackground")
	local energy=status and status:FindFirstChild("EnergyBackground")
	local ult=status and status:FindFirstChild("UltBackground")
	local hotbar=gui:FindFirstChild("Hotbar")
	local mobile=gui:FindFirstChild("MobileActions")
	if not status or not health or not energy or not ult or not hotbar or not mobile then return false end
	for _,name in ipairs({"Light","Dash","Block","Special"}) do
		if not hotbar:FindFirstChild(name) then return false end
	end
	for _,name in ipairs({"MobileM1","MobileGuard","MobileDash","MobileSpecial"}) do
		if not mobile:FindFirstChild(name) then return false end
	end
	return true
end

function M.Build():ScreenGui?
	local playerGui=player:WaitForChild("PlayerGui")
	local old=playerGui:FindFirstChild("CollisionHUD")
	if old then old:Destroy() end
	local ok,result=pcall(HUDLayout.Build)
	if not ok or not result or not result:IsA("ScreenGui") then
		lastError=tostring(result or "HUD layout build failed")
		player:SetAttribute("HUDRecoveryError",lastError)
		return nil
	end
	result.Parent=playerGui
	if not ready(result) then
		lastError="HUD structure verification failed"
		player:SetAttribute("HUDRecoveryError",lastError)
		result:Destroy()
		return nil
	end
	lastError=""
	player:SetAttribute("HUDRecoveryError","")
	result:SetAttribute("HUDRecoveryReady",true)
	return result
end

function M.IsReady():boolean
	local gui=player:FindFirstChildOfClass("PlayerGui") and player.PlayerGui:FindFirstChild("CollisionHUD")
	return ready(gui)
end

function M.GetLastError():string
	return lastError
end

return M
