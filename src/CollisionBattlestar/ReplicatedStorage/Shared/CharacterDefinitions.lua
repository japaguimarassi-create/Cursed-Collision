--!strict
export type Fighter={Id:string,SourceName:string,DisplayName:string,Color:Color3,Special:string,SpecialType:string,Damage:number,Radius:number,Knockback:number,Awakening:string,Domain:string}
local R:{[string]:Fighter}={
Yuji={Id="Yuji",SourceName="Yuji Itadori",DisplayName="Yuji",Color=Color3.fromRGB(235,86,104),Special="Black Flash",SpecialType="Burst",Damage=38,Radius=11,Knockback=58,Awakening="Divergent Rampage",Domain="Soul Impact"},
Gojo={Id="Gojo",SourceName="Satoru Gojo",DisplayName="Gojo",Color=Color3.fromRGB(90,187,255),Special="Blue Pull",SpecialType="Pull",Damage=30,Radius=13,Knockback=52,Awakening="Limitless Overflow",Domain="Infinite Void"},
Sukuna={Id="Sukuna",SourceName="Ryomen Sukuna",DisplayName="Sukuna",Color=Color3.fromRGB(238,81,76),Special="Dismantle",SpecialType="Line",Damage=42,Radius=15,Knockback=62,Awakening="Malevolent Force",Domain="Malevolent Shrine"},
Megumi={Id="Megumi",SourceName="Megumi Fushiguro",DisplayName="Potential Man",Color=Color3.fromRGB(94,148,255),Special="Divine Shadow",SpecialType="Burst",Damage=35,Radius=12,Knockback=45,Awakening="Chimera Surge",Domain="Chimera Shadow Garden"},
Yuta={Id="Yuta",SourceName="Yuta Okkotsu",DisplayName="Yuta",Color=Color3.fromRGB(221,235,255),Special="Rika Assist",SpecialType="GuardBreak",Damage=40,Radius=10,Knockback=55,Awakening="Copy Frenzy",Domain="Authentic Mutual Love"},
Maki={Id="Maki",SourceName="Maki Zenin",DisplayName="Maki",Color=Color3.fromRGB(108,224,145),Special="Blade Rush",SpecialType="DashStrike",Damage=39,Radius=9,Knockback=64,Awakening="Heavenly Arsenal",Domain="No Domain"},
Toji={Id="Toji",SourceName="Toji Fushiguro",DisplayName="Toji",Color=Color3.fromRGB(128,145,161),Special="Phantom Rush",SpecialType="DashStrike",Damage=43,Radius=9,Knockback=70,Awakening="Sorcerer Hunter",Domain="No Domain"},
Mahito={Id="Mahito",SourceName="Mahito",DisplayName="Mahito",Color=Color3.fromRGB(171,112,255),Special="Soul Touch",SpecialType="GuardBreak",Damage=36,Radius=10,Knockback=48,Awakening="Idle Mutation",Domain="Self-Embodiment"},
Todo={Id="Todo",SourceName="Aoi Todo",DisplayName="Todo",Color=Color3.fromRGB(255,191,84),Special="Boogie Swap",SpecialType="Blink",Damage=34,Radius=10,Knockback=52,Awakening="Boogie Overdrive",Domain="No Domain"},
Hakari={Id="Hakari",SourceName="Kinji Hakari",DisplayName="Hakari",Color=Color3.fromRGB(239,126,255),Special="Jackpot",SpecialType="Heal",Damage=25,Radius=10,Knockback=38,Awakening="Private Pure Love",Domain="Idle Death Gamble"},
Choso={Id="Choso",SourceName="Choso",DisplayName="Choso",Color=Color3.fromRGB(211,72,91),Special="Piercing Blood",SpecialType="Line",Damage=44,Radius=16,Knockback=44,Awakening="Blood Edge",Domain="No Domain"},
Kashimo={Id="Kashimo",SourceName="Hajime Kashimo",DisplayName="Kashimo",Color=Color3.fromRGB(112,204,255),Special="Lightning Burst",SpecialType="Burst",Damage=46,Radius=12,Knockback=61,Awakening="Mythical Beast Amber",Domain="No Domain"},
Naoya={Id="Naoya",SourceName="Naoya Zenin",DisplayName="Naoya",Color=Color3.fromRGB(121,247,221),Special="Projection Rush",SpecialType="DashStrike",Damage=37,Radius=11,Knockback=58,Awakening="Time Frame",Domain="Time Cell Moon Palace"},
Kenjaku={Id="Kenjaku",SourceName="Kenjaku",DisplayName="Kenjaku",Color=Color3.fromRGB(203,117,255),Special="Gravity Well",SpecialType="Pull",Damage=39,Radius=14,Knockback=42,Awakening="Cursed Arsenal",Domain="Womb Profusion"},
Jogo={Id="Jogo",SourceName="Jogo",DisplayName="Jogo",Color=Color3.fromRGB(255,118,59),Special="Volcanic Burst",SpecialType="Burst",Damage=45,Radius=14,Knockback=60,Awakening="Meteor Core",Domain="Coffin of the Iron Mountain"},
Dagon={Id="Dagon",SourceName="Dagon",DisplayName="Dagon",Color=Color3.fromRGB(70,166,219),Special="Water Swarm",SpecialType="Cone",Damage=37,Radius=13,Knockback=49,Awakening="Ocean Depth",Domain="Horizon of the Captivating Skandha"},
Hanami={Id="Hanami",SourceName="Hanami",DisplayName="Hanami",Color=Color3.fromRGB(89,195,122),Special="Branch Cannon",SpecialType="Line",Damage=35,Radius=12,Knockback=57,Awakening="Forest Wrath",Domain="No Domain"},
Higuruma={Id="Higuruma",SourceName="Hiromi Higuruma",DisplayName="Higuruma",Color=Color3.fromRGB(240,240,240),Special="Judgeman",SpecialType="GuardBreak",Damage=34,Radius=11,Knockback=40,Awakening="Deadly Sentencing",Domain="Deadly Sentencing"},
Takaba={Id="Takaba",SourceName="Fumihiko Takaba",DisplayName="Takaba",Color=Color3.fromRGB(255,209,99),Special="Comedian",SpecialType="Blink",Damage=32,Radius=12,Knockback=46,Awakening="Reality Joke",Domain="No Domain"},
Uraume={Id="Uraume",SourceName="Uraume",DisplayName="Uraume",Color=Color3.fromRGB(165,229,255),Special="Icefall",SpecialType="Cone",Damage=41,Radius=13,Knockback=54,Awakening="Frozen Verdict",Domain="No Domain"},
Yorozu={Id="Yorozu",SourceName="Yorozu",DisplayName="Yorozu",Color=Color3.fromRGB(255,123,180),Special="Perfect Sphere",SpecialType="Burst",Damage=48,Radius=12,Knockback=65,Awakening="Construction Bloom",Domain="Threefold Affliction"},
Ryu={Id="Ryu",SourceName="Ryu Ishigori",DisplayName="Ryu",Color=Color3.fromRGB(255,145,94),Special="Granite Blast",SpecialType="Line",Damage=47,Radius=17,Knockback=72,Awakening="Maximum Output",Domain="No Domain"},
Uro={Id="Uro",SourceName="Takako Uro",DisplayName="Uro",Color=Color3.fromRGB(145,188,255),Special="Sky Bending",SpecialType="Pull",Damage=35,Radius=12,Knockback=50,Awakening="Thin Ice",Domain="No Domain"},
Kusakabe={Id="Kusakabe",SourceName="Atsuya Kusakabe",DisplayName="Kusakabe",Color=Color3.fromRGB(194,194,194),Special="Simple Domain",SpecialType="GuardBreak",Damage=33,Radius=10,Knockback=45,Awakening="New Shadow",Domain="No Domain"}
}
local M={}
M.Order={"Yuji","Gojo","Sukuna","Megumi","Yuta","Maki","Toji","Mahito","Todo","Hakari","Choso","Kashimo","Naoya","Kenjaku","Jogo","Dagon","Hanami","Higuruma","Takaba","Uraume","Yorozu","Ryu","Uro","Kusakabe"}
function M.Get(id:string):Fighter? return R[id] end
function M.All():{Fighter}
  local out={}
  for _,id in ipairs(M.Order) do table.insert(out,R[id]) end
  return out
end
return M