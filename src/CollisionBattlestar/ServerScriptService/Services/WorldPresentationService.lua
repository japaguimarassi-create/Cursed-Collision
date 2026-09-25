--!strict
local Lighting=game:GetService("Lighting")
local CollectionService=game:GetService("CollectionService")

local S={}
local palette={
	Stable={Color3.fromRGB(92,198,255),Color3.fromRGB(54,72,88),.20,1.0,17.5},
	Unstable={Color3.fromRGB(255,166,80),Color3.fromRGB(72,58,54),.35,1.8,18.5},
	Distorted={Color3.fromRGB(178,92,255),Color3.fromRGB(67,49,82),.55,2.5,22},
	Invaded={Color3.fromRGB(255,86,92),Color3.fromRGB(80,43,52),.62,3.0,1.5},
	Collapsed={Color3.fromRGB(255,170,80),Color3.fromRGB(55,38,40),.70,3.4,3},
	Recovering={Color3.fromRGB(112,210,178),Color3.fromRGB(48,67,63),.28,1.2,19},
	Resonating={Color3.fromRGB(116,176,255),Color3.fromRGB(49,65,88),.25,1.5,20},
}

local atmosphere:Atmosphere?
local colorCorrection:ColorCorrectionEffect?
local function ensure()
	if not atmosphere then atmosphere=Lighting:FindFirstChild("CollisionAtmosphere")or Instance.new("Atmosphere");atmosphere.Name="CollisionAtmosphere";atmosphere.Parent=Lighting end
	if not colorCorrection then colorCorrection=Lighting:FindFirstChild("CollisionColor")or Instance.new("ColorCorrectionEffect");colorCorrection.Name="CollisionColor";colorCorrection.Parent=Lighting end
end

function S.Apply(state:string)
	ensure()
	local p=palette[state]or palette.Stable
	atmosphere.Color=p[1];atmosphere.Decay=p[2];atmosphere.Density=p[3];atmosphere.Haze=p[4];Lighting.ClockTime=p[5]
	local targets=CollectionService:GetTagged("CollisionResponsive")
	for _,item in ipairs(targets)do
		if item:IsA("BasePart")then
			item.Color=p[1]
		end
	end
	if colorCorrection then
		colorCorrection.Saturation=state=="Collapsed" and -.45 or state=="Distorted" and .25 or 0
		colorCorrection.Contrast=state=="Invaded" and .25 or state=="Collapsed" and .35 or .05
	end
end

function S.Init(worldState)
	worldState.Changed.Event:Connect(function(newState:string)
		S.Apply(newState)
	end)
	S.Apply(workspace:GetAttribute("CollisionState")or"Stable")
end

return S
