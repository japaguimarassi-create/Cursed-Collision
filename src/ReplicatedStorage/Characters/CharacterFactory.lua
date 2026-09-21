local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Profiles = require(ReplicatedStorage.Characters.CharacterDefinitions)

local Factory = {}

local function root(ctx, player)
    return ctx.rootPosition(player)
end

local function front(ctx, player, range, width, height)
    return ctx.hitbox:NearestTargetInFront(player, range, width, height)
end

local function area(ctx, player, radius)
    return ctx.hitbox:AreaTargets(player, root(ctx, player), radius)
end

local function hit(ctx, player, target, damage, tag, stun, knockback)
    if not target then
        return false
    end
    return ctx.damage(player, target.humanoid, damage, {
        stun = stun or 0.35,
        knockback = knockback or 0,
        tag = tag
    })
end

local function set(ctx, player, name, value)
    ctx.setAttribute(player, name, value)
end

local function pulse(ctx, player, radius, damage, tag, stun, knockback)
    local success = false
    for _, target in ipairs(area(ctx, player, radius)) do
        if hit(ctx, player, target, damage, tag, stun, knockback) then
            success = true
        end
    end
    return success
end

local function swapPositions(a, b)
    local ar = a.Character and a.Character:FindFirstChild("HumanoidRootPart")
    local br = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
    if not ar or not br then
        return false
    end
    local acf, bcf = ar.CFrame, br.CFrame
    ar.CFrame = bcf
    br.CFrame = acf
    ar.AssemblyLinearVelocity = Vector3.zero
    br.AssemblyLinearVelocity = Vector3.zero
    return true
end

local function randomTarget(ctx, player, radius)
    local targets = area(ctx, player, radius)
    return targets[1]
end

function Factory.Build(id)
    local profile = Profiles[id]
    local M = {}

    function M.Init(player, ctx)
        local state = ctx.getState(player)
        state.Momentum = 0
        state.BlackFlashWindow = nil
        state.Infinity = false
        state.InfinityBreakUntil = 0
        state.LimitlessState = "Neutral"
        state.SlashAdaptation = "Dismantle"
        state.ShikigamiMode = "Divine Dogs"
        state.MahoragaAdaptation = {}
        state.RikaActive = false
        state.CopySlot = 1
        state.WeaponMode = "Katana"
        state.SoulIntegrity = 100
        state.SwapReady = true
        state.Jackpot = false
        state.JackpotUntil = 0
        state.JackpotRoll = 0
        state.Blood = 100
        state.ElectricalCharge = 0
        state.FrameSequence = 0
        state.FrameWindowUntil = 0
        state.TechniqueStock = 2
        state.Heat = 0
        state.Tide = 0
        state.Roots = 0
        state.Evidence = 0
        state.Confiscated = false
        state.ComedyContext = 0
        state.Frost = 0
        state.Construction = 0
        state.OutputCharge = 0
        state.SkyDistortion = 0
        state.SimpleDomain = false

        player:SetAttribute("CharacterTitle", profile.Subtitle)
        player:SetAttribute("UniqueState", profile.Unique)
        player:SetAttribute("Momentum", 0)
        player:SetAttribute("Infinity", false)
        player:SetAttribute("LimitlessState", "Neutral")
        player:SetAttribute("SlashState", "Dismantle")
        player:SetAttribute("Shikigami", "Divine Dogs")
        player:SetAttribute("RikaActive", false)
        player:SetAttribute("CopySlot", 1)
        player:SetAttribute("WeaponMode", "Katana")
        player:SetAttribute("SoulIntegrity", 100)
        player:SetAttribute("SwapReady", true)
        player:SetAttribute("Jackpot", false)
        player:SetAttribute("JackpotRoll", 0)
        player:SetAttribute("Blood", 100)
        player:SetAttribute("ElectricalCharge", 0)
        player:SetAttribute("FrameSequence", 0)
        player:SetAttribute("TechniqueStock", 2)
        player:SetAttribute("Heat", 0)
        player:SetAttribute("Tide", 0)
        player:SetAttribute("Roots", 0)
        player:SetAttribute("Evidence", 0)
        player:SetAttribute("Confiscated", false)
        player:SetAttribute("ComedyContext", 0)
        player:SetAttribute("Frost", 0)
        player:SetAttribute("Construction", 0)
        player:SetAttribute("OutputCharge", 0)
        player:SetAttribute("SkyDistortion", 0)
        player:SetAttribute("SimpleDomain", false)

        if id == "Gojo" then
            state.Infinity = true
            player:SetAttribute("Infinity", true)
        elseif id == "Yuta" then
            state.RikaActive = true
            player:SetAttribute("RikaActive", true)
        elseif id == "Hakari" then
            state.JackpotRoll = math.random(1, 100)
            player:SetAttribute("JackpotRoll", state.JackpotRoll)
        elseif id == "Kusakabe" then
            state.SimpleDomain = true
            player:SetAttribute("SimpleDomain", true)
        end
    end

    function M.GetCooldown(action)
        if action == "Special" then
            return profile.SpecialCooldown
        end
        if action == "Skill" then
            return profile.SkillCooldown
        end
        return 0.6
    end

    function M.Special(player, ctx)
        local state = ctx.getState(player)

        if id == "Yuji" then
            local target = front(ctx, player, 8, 6, 6)
            local ok = hit(ctx, player, target, 13 + (state.Momentum or 0) * 1.2, "DivergentFist", 0.42, 26)
            if ok then
                task.delay(0.14, function()
                    if target.humanoid and target.humanoid.Health > 0 then
                        ctx.damage(player, target.humanoid, 7, {stun=0.2, tag="DelayedImpact"})
                    end
                end)
            end
            return ok
        elseif id == "Gojo" then
            local target = front(ctx, player, state.LimitlessState == "Purple" and 24 or 15, 9, 8)
            if state.LimitlessState == "Red" then
                return hit(ctx, player, target, 24, "Red", 0.55, 94) and (ctx.fx("GojoRed", target.root.Position) or true)
            elseif state.LimitlessState == "Purple" then
                return hit(ctx, player, target, 38, "HollowPurple", 0.9, 118) and (ctx.fx("GojoPurple", target.root.Position) or true)
            else
                return hit(ctx, player, target, 18, "Blue", 0.45, 50) and (ctx.fx("GojoBlue", target.root.Position) or true)
            end
        elseif id == "Sukuna" then
            local target = front(ctx, player, 15, 8, 8)
            if not target then return false end
            local distance = (target.root.Position - root(ctx, player)).Magnitude
            local mode = state.SlashAdaptation or "Dismantle"
            local damage = mode == "Cleave" and 22 or mode == "Fire" and 19 or 15
            if distance < 6 then damage += 7 end
            if distance > 11 then damage -= 2 end
            return hit(ctx, player, target, damage, mode, 0.45, mode == "Fire" and 54 or 30)
        elseif id == "Megumi" then
            local mode = state.ShikigamiMode or "Divine Dogs"
            local radius = mode == "Rabbit Escape" and 12 or mode == "Nue" and 13 or 9
            local damage = mode == "Nue" and 18 or mode == "Max Elephant" and 24 or mode == "Rabbit Escape" and 6 or 13
            if mode == "Mahoraga" then
                state.MahoragaAdaptation["Last"] = os.clock()
                set(ctx, player, "MahoragaAdaptation", "Learning")
                ctx.fx("MegumiMahoraga", root(ctx, player))
                return pulse(ctx, player, 13, 28, "Mahoraga", 0.7, 64)
            end
            return pulse(ctx, player, radius, damage, mode:gsub(" ", ""), 0.45, 38)
        elseif id == "Yuta" then
            local target = front(ctx, player, 9, 7, 7)
            if not target then return false end
            if state.RikaActive then
                target.root.AssemblyLinearVelocity = (target.root.Position - root(ctx, player)).Unit * 46 + Vector3.new(0, 18, 0)
            end
            local damage = state.CopySlot == 1 and 16 or state.CopySlot == 2 and 20 or 24
            return hit(ctx, player, target, damage, "RikaSword", 0.5, 42)
        elseif id == "Maki" or id == "Toji" then
            local mode = state.WeaponMode or "Katana"
            local target = front(ctx, player, id == "Toji" and 10 or 8, 7, 7)
            local damage = mode == "Spear" and 20 or mode == "Chain" and 15 or 18
            return hit(ctx, player, target, damage, id .. mode, 0.45, 52)
        elseif id == "Mahito" then
            local target = front(ctx, player, 8, 7, 7)
            if not target then return false end
            local ok = hit(ctx, player, target, 19, "IdleTransfiguration", 0.55, 34)
            if ok then
                state.SoulIntegrity = math.min(100, (state.SoulIntegrity or 100) + 6)
                set(ctx, player, "SoulIntegrity", state.SoulIntegrity)
            end
            return ok
        elseif id == "Todo" then
            local target = front(ctx, player, 14, 10, 10)
            if not target then return false end
            local other = randomTarget(ctx, player, 22)
            if other and swapPositions(player, other.player) then
                ctx.fx("TodoSwap", root(ctx, player), target.root.Position)
                return true
            end
            return hit(ctx, player, target, 15, "BoogieWoogie", 0.4, 32)
        elseif id == "Hakari" then
            local target = front(ctx, player, 8, 7, 7)
            local damage = state.Jackpot and 24 or 16
            local ok = hit(ctx, player, target, damage, "PrivatePureLove", 0.5, 46)
            if state.Jackpot then
                state.JackpotUntil = math.max(state.JackpotUntil or 0, os.clock() + 0.5)
                set(ctx, player, "Jackpot", true)
            end
            return ok
        elseif id == "Choso" then
            local blood = state.Blood or 0
            if blood < 18 then return false end
            state.Blood = blood - 18
            set(ctx, player, "Blood", state.Blood)
            local target = front(ctx, player, 18, 5, 6)
            return hit(ctx, player, target, 25, "PiercingBlood", 0.5, 72)
        elseif id == "Kashimo" then
            local target = front(ctx, player, 9, 7, 7)
            if not target then return false end
            local gain = 18
            state.ElectricalCharge = math.clamp((state.ElectricalCharge or 0) + gain, 0, 100)
            set(ctx, player, "ElectricalCharge", state.ElectricalCharge)
            return hit(ctx, player, target, 17 + state.ElectricalCharge * 0.08, "Lightning", 0.45, 48)
        elseif id == "Naoya" then
            if (state.FrameSequence or 0) <= 0 then return false end
            state.FrameSequence = math.min(24, state.FrameSequence + 1)
            set(ctx, player, "FrameSequence", state.FrameSequence)
            local target = front(ctx, player, 10, 7, 7)
            return hit(ctx, player, target, 11 + state.FrameSequence * 0.7, "ProjectionStrike", 0.35, 42)
        elseif id == "Kenjaku" then
            local target = front(ctx, player, 15, 8, 8)
            local damage = 17 + (state.TechniqueStock or 0) * 3
            if state.TechniqueStock and state.TechniqueStock > 0 then
                state.TechniqueStock -= 1
                set(ctx, player, "TechniqueStock", state.TechniqueStock)
            end
            return hit(ctx, player, target, damage, "CursedSpiritBurst", 0.5, 48)
        elseif id == "Jogo" then
            state.Heat = math.clamp((state.Heat or 0) + 20, 0, 100)
            set(ctx, player, "Heat", state.Heat)
            return pulse(ctx, player, 9, 13 + state.Heat * 0.06, "VolcanicBurst", 0.45, 58)
        elseif id == "Dagon" then
            state.Tide = math.clamp((state.Tide or 0) + 16, 0, 100)
            set(ctx, player, "Tide", state.Tide)
            return pulse(ctx, player, 12, 12 + state.Tide * 0.05, "DeathSwarm", 0.4, 45)
        elseif id == "Hanami" then
            state.Roots = math.clamp((state.Roots or 0) + 15, 0, 100)
            set(ctx, player, "Roots", state.Roots)
            return pulse(ctx, player, 10, 13, "DisasterPlants", 0.5, 38)
        elseif id == "Higuruma" then
            state.Evidence = math.clamp((state.Evidence or 0) + 20, 0, 100)
            set(ctx, player, "Evidence", state.Evidence)
            if state.Evidence >= 100 then
                state.Confiscated = true
                set(ctx, player, "Confiscated", true)
            end
            return hit(ctx, player, front(ctx, player, 8, 7, 7), 16 + (state.Evidence or 0) * 0.05, "JudgmentStrike", 0.55, 36)
        elseif id == "Takaba" then
            state.ComedyContext = math.clamp((state.ComedyContext or 0) + 25, 0, 100)
            set(ctx, player, "ComedyContext", state.ComedyContext)
            local targets = area(ctx, player, 8)
            if #targets == 0 then return false end
            local best = targets[1]
            local damage = state.ComedyContext >= 75 and 30 or 12
            return hit(ctx, player, best, damage, "Comedian", 0.5, 60)
        elseif id == "Uraume" then
            state.Frost = math.clamp((state.Frost or 0) + 18, 0, 100)
            set(ctx, player, "Frost", state.Frost)
            return pulse(ctx, player, 11, 13 + state.Frost * 0.05, "IceFormation", 0.58, 50)
        elseif id == "Yorozu" then
            state.Construction = math.clamp((state.Construction or 0) + 20, 0, 100)
            set(ctx, player, "Construction", state.Construction)
            return pulse(ctx, player, 10, 16 + state.Construction * 0.04, "LiquidMetal", 0.48, 54)
        elseif id == "Ryu" then
            state.OutputCharge = math.clamp((state.OutputCharge or 0) + 24, 0, 100)
            set(ctx, player, "OutputCharge", state.OutputCharge)
            return hit(ctx, player, front(ctx, player, 18, 6, 7), 18 + state.OutputCharge * 0.08, "GraniteShot", 0.45, 74)
        elseif id == "Uro" then
            state.SkyDistortion = math.clamp((state.SkyDistortion or 0) + 20, 0, 100)
            set(ctx, player, "SkyDistortion", state.SkyDistortion)
            local target = front(ctx, player, 13, 9, 8)
            if not target then return false end
            target.root.CFrame = target.root.CFrame * CFrame.Angles(0, math.rad(18), 0)
            return hit(ctx, player, target, 17 + state.SkyDistortion * 0.05, "SkyManipulation", 0.5, 52)
        elseif id == "Kusakabe" then
            local target = front(ctx, player, 9, 7, 7)
            local mult = state.SimpleDomain and 1.35 or 1
            return hit(ctx, player, target, 18 * mult, "SimpleDomainSlash", 0.42, 46)
        end

        return false
    end

    function M.Skill(player, ctx)
        local state = ctx.getState(player)

        if id == "Yuji" then
            if state.BlackFlashWindow and os.clock() <= state.BlackFlashWindow then
                state.BlackFlashWindow = nil
                state.Momentum = math.min(8, (state.Momentum or 0) + 1)
                set(ctx, player, "Momentum", state.Momentum)
                local target = front(ctx, player, 9, 6, 6)
                return hit(ctx, player, target, 18 + state.Momentum * 1.5, "BlackFlash", 0.7, 60)
            end
            local target = front(ctx, player, 8, 6, 6)
            return hit(ctx, player, target, 10, "BlackFlashSetup", 0.35, 28)
        elseif id == "Gojo" then
            local nextState = {Neutral="Red", Red="Purple", Purple="Neutral"}
            state.LimitlessState = nextState[state.LimitlessState] or "Neutral"
            if state.LimitlessState == "Neutral" then
                state.Infinity = not state.Infinity
                if state.Infinity then state.InfinityBreakUntil = 0 end
            end
            set(ctx, player, "LimitlessState", state.LimitlessState)
            set(ctx, player, "Infinity", state.Infinity)
            ctx.fx("GojoState", root(ctx, player), state.LimitlessState, state.Infinity)
            return true
        elseif id == "Sukuna" then
            local nextMode = {Dismantle="Cleave", Cleave="Fire", Fire="Dismantle"}
            state.SlashAdaptation = nextMode[state.SlashAdaptation] or "Dismantle"
            set(ctx, player, "SlashState", state.SlashAdaptation)
            if state.SlashAdaptation == "Fire" then
                return pulse(ctx, player, 11, 20, "FireArrow", 0.58, 66)
            end
            return true
        elseif id == "Megumi" then
            local modes = {"Divine Dogs","Nue","Toad","Rabbit Escape","Max Elephant","Mahoraga"}
            local current = table.find(modes, state.ShikigamiMode) or 1
            current = current % #modes + 1
            state.ShikigamiMode = modes[current]
            set(ctx, player, "Shikigami", state.ShikigamiMode)
            return true
        elseif id == "Yuta" then
            state.CopySlot = state.CopySlot % 3 + 1
            set(ctx, player, "CopySlot", state.CopySlot)
            state.RikaActive = not state.RikaActive
            set(ctx, player, "RikaActive", state.RikaActive)
            return true
        elseif id == "Maki" or id == "Toji" then
            local modes = id == "Maki" and {"Katana","Spear","Naginata"} or {"Katana","Chain","Spear"}
            local current = table.find(modes, state.WeaponMode) or 1
            current = current % #modes + 1
            state.WeaponMode = modes[current]
            set(ctx, player, "WeaponMode", state.WeaponMode)
            return true
        elseif id == "Mahito" then
            state.SoulIntegrity = math.max(0, (state.SoulIntegrity or 100) - 12)
            set(ctx, player, "SoulIntegrity", state.SoulIntegrity)
            if state.SoulIntegrity <= 30 then
                state.SoulIntegrity = 85
                set(ctx, player, "SoulIntegrity", state.SoulIntegrity)
                ctx.fx("MahitoTransfigured", root(ctx, player))
            end
            return pulse(ctx, player, 8, 14, "BodyRepulsion", 0.42, 44)
        elseif id == "Todo" then
            state.SwapReady = not state.SwapReady
            set(ctx, player, "SwapReady", state.SwapReady)
            ctx.fx("TodoClap", root(ctx, player), state.SwapReady)
            return true
        elseif id == "Hakari" then
            state.JackpotRoll = math.random(1,100)
            set(ctx, player, "JackpotRoll", state.JackpotRoll)
            if state.JackpotRoll >= 80 then
                state.Jackpot = true
                state.JackpotUntil = os.clock() + 14
                set(ctx, player, "Jackpot", true)
            end
            return true
        elseif id == "Choso" then
            state.Blood = math.clamp((state.Blood or 0) + 24, 0, 100)
            set(ctx, player, "Blood", state.Blood)
            return pulse(ctx, player, 7, 11, "Supernova", 0.45, 42)
        elseif id == "Kashimo" then
            state.ElectricalCharge = math.clamp((state.ElectricalCharge or 0) + 32, 0, 100)
            set(ctx, player, "ElectricalCharge", state.ElectricalCharge)
            return pulse(ctx, player, 7, 9 + state.ElectricalCharge * 0.05, "ChargeBurst", 0.35, 34)
        elseif id == "Naoya" then
            local now = os.clock()
            if state.FrameWindowUntil < now or state.FrameSequence >= 24 then
                state.FrameSequence = 1
            else
                state.FrameSequence += 1
            end
            state.FrameWindowUntil = now + 0.7
            set(ctx, player, "FrameSequence", state.FrameSequence)
            if state.FrameSequence >= 6 then
                local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.WalkSpeed = 24 end
            end
            return true
        elseif id == "Kenjaku" then
            state.TechniqueStock = math.min(5, (state.TechniqueStock or 0) + 1)
            set(ctx, player, "TechniqueStock", state.TechniqueStock)
            return pulse(ctx, player, 9, 15, "Gravity", 0.48, 50)
        elseif id == "Jogo" then
            state.Heat = math.min(100, (state.Heat or 0) + 30)
            set(ctx, player, "Heat", state.Heat)
            return pulse(ctx, player, 10, 15 + state.Heat * 0.06, "Ember", 0.45, 52)
        elseif id == "Dagon" then
            state.Tide = math.min(100, (state.Tide or 0) + 25)
            set(ctx, player, "Tide", state.Tide)
            return pulse(ctx, player, 13, 13, "WaterShikigami", 0.42, 48)
        elseif id == "Hanami" then
            state.Roots = math.min(100, (state.Roots or 0) + 22)
            set(ctx, player, "Roots", state.Roots)
            return pulse(ctx, player, 11, 15, "RootGrab", 0.6, 25)
        elseif id == "Higuruma" then
            state.Evidence = math.min(100, (state.Evidence or 0) + 30)
            set(ctx, player, "Evidence", state.Evidence)
            if state.Evidence >= 70 then
                state.Confiscated = true
                set(ctx, player, "Confiscated", true)
            end
            return true
        elseif id == "Takaba" then
            state.ComedyContext = math.min(100, (state.ComedyContext or 0) + 35)
            set(ctx, player, "ComedyContext", state.ComedyContext)
            return pulse(ctx, player, 9, state.ComedyContext >= 70 and 26 or 10, "ComedianReality", 0.48, 40)
        elseif id == "Uraume" then
            state.Frost = math.min(100, (state.Frost or 0) + 25)
            set(ctx, player, "Frost", state.Frost)
            return pulse(ctx, player, 12, 12 + state.Frost * 0.04, "FrostCalamity", 0.55, 58)
        elseif id == "Yorozu" then
            state.Construction = math.min(100, (state.Construction or 0) + 25)
            set(ctx, player, "Construction", state.Construction)
            return pulse(ctx, player, 10, 18, "ConstructionArmor", 0.45, 50)
        elseif id == "Ryu" then
            state.OutputCharge = math.min(100, (state.OutputCharge or 0) + 35)
            set(ctx, player, "OutputCharge", state.OutputCharge)
            return true
        elseif id == "Uro" then
            state.SkyDistortion = math.min(100, (state.SkyDistortion or 0) + 30)
            set(ctx, player, "SkyDistortion", state.SkyDistortion)
            return true
        elseif id == "Kusakabe" then
            state.SimpleDomain = not state.SimpleDomain
            set(ctx, player, "SimpleDomain", state.SimpleDomain)
            return true
        end

        return false
    end

    function M.Awaken(player, ctx)
        local state = ctx.getState(player)
        if id == "Yuji" then
            state.Momentum = math.max(2, state.Momentum or 0)
            set(ctx, player, "Momentum", state.Momentum)
        elseif id == "Gojo" then
            state.Infinity = true
            state.LimitlessState = "Purple"
            set(ctx, player, "Infinity", true)
            set(ctx, player, "LimitlessState", "Purple")
        elseif id == "Sukuna" then
            state.SlashAdaptation = "Cleave"
            set(ctx, player, "SlashState", "Cleave")
        elseif id == "Megumi" then
            state.ShikigamiMode = "Mahoraga"
            set(ctx, player, "Shikigami", "Mahoraga")
        elseif id == "Yuta" then
            state.RikaActive = true
            state.CopySlot = 3
            set(ctx, player, "RikaActive", true)
            set(ctx, player, "CopySlot", 3)
        elseif id == "Maki" or id == "Toji" then
            state.WeaponMode = "Spear"
            set(ctx, player, "WeaponMode", "Spear")
        elseif id == "Mahito" then
            state.SoulIntegrity = 100
            set(ctx, player, "SoulIntegrity", 100)
        elseif id == "Hakari" then
            state.Jackpot = true
            state.JackpotUntil = os.clock() + 18
            set(ctx, player, "Jackpot", true)
        elseif id == "Kashimo" then
            state.ElectricalCharge = 100
            set(ctx, player, "ElectricalCharge", 100)
        elseif id == "Choso" then
            state.Blood = 100
            set(ctx, player, "Blood", 100)
        elseif id == "Kusakabe" then
            state.SimpleDomain = true
            set(ctx, player, "SimpleDomain", true)
        elseif id == "Naoya" then
            state.FrameSequence = 24
            set(ctx, player, "FrameSequence", 24)
        else
            ctx.fx(id .. "Awakening", root(ctx, player))
        end
        ctx.fx("CharacterAwakening", root(ctx, player), id, profile.AwakeningName)
    end

    function M.Domain(player, ctx)
        if not profile.Domain then
            return false
        end
        return ctx.domain:start(player, profile.Domain, id, profile.DomainRadius or 34, profile.DomainDuration or 18)
    end

    function M.OneTime(player, ctx)
        local position = root(ctx, player)
        local damage = 44
        local radius = 16
        if id == "Gojo" then damage, radius = 56, 18
        elseif id == "Sukuna" then damage, radius = 58, 20
        elseif id == "Megumi" then damage, radius = 54, 18
        elseif id == "Yuta" then damage, radius = 52, 18
        elseif id == "Jogo" then damage, radius = 60, 20
        elseif id == "Dagon" then damage, radius = 54, 20
        elseif id == "Higuruma" then damage, radius = 50, 15
        elseif id == "Ryu" then damage, radius = 62, 18
        elseif id == "Takaba" then damage, radius = 46, 16
        end

        local success = false
        for _, target in ipairs(area(ctx, player, radius)) do
            local extra = 0
            if id == "Hakari" and state.Jackpot then extra = 12 end
            if id == "Choso" then extra = math.floor((state.Blood or 0) * 0.12) end
            if id == "Kashimo" then extra = math.floor((state.ElectricalCharge or 0) * 0.15) end
            if id == "Ryu" then extra = math.floor((state.OutputCharge or 0) * 0.18) end
            if hit(ctx, player, target, damage + extra, profile.OneTimeName, 1.15, 82) then
                success = true
            end
        end
        if id == "Kashimo" then
            state.ElectricalCharge = 0
            set(ctx, player, "ElectricalCharge", 0)
        elseif id == "Choso" then
            state.Blood = 20
            set(ctx, player, "Blood", 20)
        elseif id == "Ryu" then
            state.OutputCharge = 0
            set(ctx, player, "OutputCharge", 0)
        end
        ctx.fx("CharacterOneTime", position, id, profile.OneTimeName)
        return true
    end

    function M.OnIncomingDamage(player, ctx, amount)
        local state = ctx.getState(player)
        if id == "Gojo" and state.Infinity and state.InfinityBreakUntil <= os.clock() then
            state.Infinity = false
            state.InfinityBreakUntil = os.clock() + 0.55
            set(ctx, player, "Infinity", false)
            ctx.fx("GojoInfinity", root(ctx, player))
            return 0
        elseif id == "Mahito" then
            state.SoulIntegrity = math.max(0, (state.SoulIntegrity or 100) - amount * 0.25)
            set(ctx, player, "SoulIntegrity", state.SoulIntegrity)
            if state.SoulIntegrity <= 0 then
                return amount * 1.2
            end
            return amount * 0.92
        elseif id == "Maki" or id == "Toji" then
            return amount * 0.88
        elseif id == "Kusakabe" and state.SimpleDomain then
            return amount * 0.72
        elseif id == "Hakari" and state.Jackpot and state.JackpotUntil > os.clock() then
            return math.max(0, amount - 4)
        end
        return amount
    end

    return M
end

return Factory