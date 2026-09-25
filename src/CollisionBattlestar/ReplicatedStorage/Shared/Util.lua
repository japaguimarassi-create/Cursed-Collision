--!strict
local U={}
function U.Clamp(v:number,a:number,b:number):number return math.max(a,math.min(b,v)) end
function U.Root(m:Model?):BasePart? local p=m and m:FindFirstChild("HumanoidRootPart");return p and p:IsA("BasePart") and p or nil end
function U.Hum(m:Instance?):Humanoid? return m and m:FindFirstChildOfClass("Humanoid") or nil end
function U.Model(x:Instance):Model? local p:Instance?=x;while p do if p:IsA("Model")then return p end;p=p.Parent end;return nil end
function U.Part(parent:Instance,name:string,size:Vector3,cf:CFrame,material:Enum.Material,color:Color3,anchored:boolean):Part local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Material=material;p.Color=color;p.Anchored=anchored;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p end
function U.Nearest(players:{Player},origin:Vector3,maxDistance:number):(Player?,number)local best:Player?=nil;local dist=maxDistance;for _,p in players do local r=U.Root(p.Character);local h=U.Hum(p.Character);if r and h and h.Health>0 then local d=(r.Position-origin).Magnitude;if d<dist then best=p;dist=d end end end;return best,dist end
return U
