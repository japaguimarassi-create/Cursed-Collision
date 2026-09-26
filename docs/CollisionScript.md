# Collision Script (CBSL)

Collision Script is the embedded mini-language used to author Collision Battlestar.

Example:

local DSL = require(script.Parent.GameDSL)
local game = DSL.game("My Game")

game:world({ Size = 1400 })
game:combat({ M1 = { Cooldown = 0.25, BaseDamage = 20, Range = 8 } })
game:enemy("Fast", { Health = 80, Speed = 18, Damage = 9 })
game:ai("Enemy", { ThinkInterval = 0.1, DirectChaseDistance = 40 })

The runtime validates the declaration and passes the compiled result to the normal Roblox engine systems.
Available blocks: world, combat, waves, enemies, ai, assets, shop, passes, ui, meta.
The engine stays server-authoritative. CBSL does not execute arbitrary source at runtime.