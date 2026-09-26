--!strict
local C={}
C.Items={}
local featured={{"Skin_Neon","NEON VECTOR",750,"Skin","Cyan-violet combat palette."},{"Skin_Iron","IRON CORE",900,"Skin","Industrial close-range palette."},{"Skin_Apex","APEX SIGNAL",1100,"Skin","High-contrast arena palette."},{"Title_Rival","RIVAL",300,"Title","Competitive profile title."},{"Title_Veteran","VETERAN",600,"Title","Veteran profile title."},{"Title_Wanderer","WANDERER",450,"Title","City-roaming title."},{"Title_Overclocked","OVERCLOCKED",800,"Title","High-output title."},{"Banner_Cyan","CYAN VECTOR",400,"Banner","Profile banner."}}
for _,v in ipairs(featured) do table.insert(C.Items,{Id=v[1],Name=v[2],Category="Featured",Price=v[3],Kind=v[4],Description=v[5]}) end
C.Bundles={{Id="Bundle350",Name="350 CREDITS",Robux=49,ProductId=0},{Id="Bundle1000",Name="1,000 CREDITS",Robux=119,ProductId=0},{Id="Bundle2500",Name="2,500 CREDITS",Robux=239,ProductId=0},{Id="Bundle5000",Name="5,000 CREDITS",Robux=399,ProductId=0},{Id="Bundle7500",Name="7,500 CREDITS",Robux=849,ProductId=0},{Id="Bundle15000",Name="15,000 CREDITS",Robux=2499,ProductId=0},{Id="Bundle30000",Name="30,000 CREDITS",Robux=5399,ProductId=0,Best=true}}
function C.Get(id:string)
  for _,item in ipairs(C.Items) do if item.Id==id then return item end end
  return nil
end
return C