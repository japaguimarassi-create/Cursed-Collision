local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Profiles = require(ReplicatedStorage.Characters.CharacterDefinitions)
local Moves = require(ReplicatedStorage.Characters.CharacterMoves)
local CustomMovesets = require(ReplicatedStorage.Characters.CustomMovesets)

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

local function announceMove(ctx, player, characterId, action, move, power, target)
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    local data = {
        character = characterId,
        action = action,
        move = move,
        power = power or 1,
        direction = rootPart.CFrame.LookVector,
        target = target
    }

    ctx.fx("CharacterMove", rootPart.Position, data)
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
        elseif action == "Skill" then
            return profile.SkillCooldown
        end
        return 0.6
    end

    function M.Special(player, ctx)
        local state = ctx.getState(player)
        local moveProfile = Moves[id]
        local move = moveProfile and moveProfile.SpecialName or "Special"

        if id == "Gojo" then
            local gojoMoves = {
                Neutral = "Lapse Blue",
                Red = "Reversal Red",
                Purple = "Hollow Purple"
            }
            move = gojoMoves[state.LimitlessState] or move
        elseif id == "Sukuna" then
            move = state.SlashAdaptation == "Fire" and "Fire Arrow" or "Cursed Slash"
        elseif id == "Megumi" then
            move = state.ShikigamiMode or move
        elseif id == "Maki" or id == "Toji" then
            move = (state.WeaponMode or "Katana").." Strike"
        end

        announceMove(ctx, player, id, "Special", move, 1)

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
            local range = state.LimitlessState == "Purple" and 24 or 15
            local target = front(ctx, player, range, 9, 8)
            if state.LimitlessState == "Red" then
                local ok = hit(ctx, player, target, 24, "Red", 0.55, 94)
                if ok then ctx.fx("GojoRed", target.root.Position) end
                return ok
            elseif state.LimitlessState == "Purple" then
                local ok = hit(ctx, player, target, 38, "HollowPurple", 0.9, 118)
                if ok then ctx.fx("GojoPurple", target.root.Position) end
                return ok
            else
                local ok = hit(ctx, player, target, 18, "Blue", 0.45, 50)
                if ok then
                    local delta = root(ctx, player) - target.root.Position
                    if delta.Magnitude > 0.01 then
                        target.root.AssemblyLinearVelocity = delta.Unit * 76 + Vector3.new(0, 12, 0)
                    end
                    ctx.fx("GojoBlue", target.root.Position)
                end
                return ok
            end
        elseif id == "Sukuna" then
            local target = front(ctx, player, 15, 8, 8)
            if not target then return false end
            local distance = (target.root.Position - root(ctx, player)).Magnitude
            local mode = state.SlashAdaptation or "Dismantle"
            local damage = mode == "Cleave" and 22 or mode == "Fire" and 19 or 15
            if distance < 6 then damage += 7 end
            if distance > 11 then damage -= 2 end
            if mode == "Cleave" then
                local success = false
                for _, nearby in ipairs(area(ctx, player, 11)) do
                    if hit(ctx, player, nearby, damage, "Cleave", 0.42, 34) then
                        success = true
                    end
                end
                return success
            end
            return hit(ctx, player, target, damage, mode, 0.45, mode == "Fire" and 54 or 30)
        elseif id == "Megumi" then
            local mode = state.ShikigamiMode or "Divine Dogs"
            if mode == "Mahoraga" then
                state.MahoragaAdaptation.Last = os.clock()
                set(ctx, player, "MahoragaStatus", "Adapting")
                return pulse(ctx, player, 13, 28, "Mahoraga", 0.7, 64)
            end
            local radius = mode == "Rabbit Escape" and 12 or mode == "Nue" and 13 or 9
            local damage = mode == "Nue" and 18 or mode == "Max Elephant" and 24 or mode == "Rabbit Escape" and 6 or 13
            return pulse(ctx, player, radius, damage, mode:gsub(" ", ""), 0.45, 38)
        elseif id == "Yuta" then
            local target = front(ctx, player, 9, 7, 7)
            if not target then return false end
            local damage = state.CopySlot == 1 and 16 or state.CopySlot == 2 and 20 or 24
            local ok = hit(ctx, player, target, damage, "RikaSword", 0.5, 42)
            if ok and state.RikaActive then
                target.root.AssemblyLinearVelocity = (target.root.Position - root(ctx, player)).Unit * 46 + Vector3.new(0, 18, 0)
            end
            return ok
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
            if state.SwapReady and other and swapPositions(player, other.player) then
                set(ctx, player, "SwapReady", false)
                ctx.fx("TodoSwap", root(ctx, player), other.root.Position)
                return true
            end
            return hit(ctx, player, target, 15, "BoogieWoogie", 0.4, 32)
        elseif id == "Hakari" then
            local target = front(ctx, player, 8, 7, 7)
            local damage = state.Jackpot and 24 or 16
            return hit(ctx, player, target, damage, "PrivatePureLove", 0.5, 46)
        elseif id == "Choso" then
            local blood = state.Blood or 0
            if blood < 18 then return false end
            state.Blood = blood - 18
            set(ctx, player, "Blood", state.Blood)
            return hit(ctx, player, front(ctx, player, 18, 5, 6), 25, "PiercingBlood", 0.5, 72)
        elseif id == "Kashimo" then
            local target = front(ctx, player, 9, 7, 7)
            if not target then return false end
            state.ElectricalCharge = math.clamp((state.ElectricalCharge or 0) + 18, 0, 100)
            set(ctx, player, "ElectricalCharge", state.ElectricalCharge)
            return hit(ctx, player, target, 17 + state.ElectricalCharge * 0.08, "Lightning", 0.45, 48)
        elseif id == "Naoya" then
            if (state.FrameSequence or 0) <= 0 then return false end
            state.FrameSequence = math.min(24, state.FrameSequence + 1)
            set(ctx, player, "FrameSequence", state.FrameSequence)
            return hit(ctx, player, front(ctx, player, 10, 7, 7), 11 + state.FrameSequence * 0.7, "ProjectionStrike", 0.35, 42)
        elseif id == "Kenjaku" then
            local target = front(ctx, player, 15, 8, 8)
            if state.TechniqueStock > 0 then
                state.TechniqueStock -= 1
                set(ctx, player, "TechniqueStock", state.TechniqueStock)
            end
            return hit(ctx, player, target, 17 + (state.TechniqueStock or 0) * 3, "CursedSpiritBurst", 0.5, 48)
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
            return hit(ctx, player, front(ctx, player, 8, 7, 7), 16 + state.Evidence * 0.05, "JudgmentStrike", 0.55, 36)
        elseif id == "Takaba" then
            state.ComedyContext = math.clamp((state.ComedyContext or 0) + 25, 0, 100)
            set(ctx, player, "ComedyContext", state.ComedyContext)
            return hit(ctx, player, randomTarget(ctx, player, 9), state.ComedyContext >= 75 and 30 or 12, "Comedian", 0.5, 60)
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
            return hit(ctx, player, target, 17 + state.SkyDistortion * 0.05, "SkyManipulation", 0.5, 52)
        elseif id == "Kusakabe" then
            local mult = state.SimpleDomain and 1.35 or 1
            return hit(ctx, player, front(ctx, player, 9, 7, 7), 18 * mult, "SimpleDomainSlash", 0.42, 46)
        end

        return false
    end

    function M.Skill(player, ctx)
        local state = ctx.getState(player)
        local moveProfile = Moves[id]
        local move = moveProfile and moveProfile.SkillName or "Skill"

        if id == "Gojo" then
            move = "Limitless Shift"
        elseif id == "Sukuna" then
            move = state.SlashAdaptation == "Fire" and "Fire Arrow" or "Shrine Stance"
        elseif id == "Megumi" then
            move = "Ten Shadows • "..tostring(state.ShikigamiMode or "Divine Dogs")
        elseif id == "Maki" or id == "Toji" then
            move = "Arsenal • "..tostring(state.WeaponMode or "Katana")
        end

        announceMove(ctx, player, id, "Skill", move, 1.15)

        if id == "Yuji" then
            if state.BlackFlashWindow and os.clock() <= state.BlackFlashWindow then
                state.BlackFlashWindow = nil
                state.Momentum = math.min(8, (state.Momentum or 0) + 1)
                set(ctx, player, "Momentum", state.Momentum)
                return hit(ctx, player, front(ctx, player, 9, 6, 6), 18 + state.Momentum * 1.5, "BlackFlash", 0.7, 60)
            end
            return hit(ctx, player, front(ctx, player, 8, 6, 6), 10, "BlackFlashSetup", 0.35, 28)
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
            local target = front(ctx, player, 12, 8, 7)
            local damage = state.LimitlessState == "Purple" and 20 or state.LimitlessState == "Red" and 16 or 12
            return hit(ctx, player, target, damage, "GojoShift", 0.38, state.LimitlessState == "Red" and 48 or 30)
        elseif id == "Sukuna" then
            local nextMode = {Dismantle="Cleave", Cleave="Fire", Fire="Dismantle"}
            state.SlashAdaptation = nextMode[state.SlashAdaptation] or "Dismantle"
            set(ctx, player, "SlashState", state.SlashAdaptation)
            if state.SlashAdaptation == "Fire" then
                return pulse(ctx, player, 11, 20, "FireArrow", 0.58, 66)
            end
            return hit(ctx, player, front(ctx, player, 12, 7, 7), 13, "ShrineStance", 0.4, 32)
        elseif id == "Megumi" then
            local modes = {"Divine Dogs","Nue","Toad","Rabbit Escape","Max Elephant","Mahoraga"}
            local current = table.find(modes, state.ShikigamiMode) or 1
            current = current % #modes + 1
            state.ShikigamiMode = modes[current]
            set(ctx, player, "Shikigami", state.ShikigamiMode)
            local damage = state.ShikigamiMode == "Mahoraga" and 22 or state.ShikigamiMode == "Nue" and 14 or state.ShikigamiMode == "Max Elephant" and 18 or 10
            return pulse(ctx, player, state.ShikigamiMode == "Rabbit Escape" and 10 or 9, damage, "TenShadowsSetup", 0.38, 34)
        elseif id == "Yuta" then
            state.CopySlot = state.CopySlot % 3 + 1
            state.RikaActive = not state.RikaActive
            set(ctx, player, "CopySlot", state.CopySlot)
            set(ctx, player, "RikaActive", state.RikaActive)
            return hit(ctx, player, front(ctx, player, 10, 7, 7), state.RikaActive and 15 or 11, "CopyStrike", 0.42, 38)
        elseif id == "Maki" or id == "Toji" then
            local modes = id == "Maki" and {"Katana","Spear","Naginata"} or {"Katana","Chain","Spear"}
            local current = table.find(modes, state.WeaponMode) or 1
            current = current % #modes + 1
            state.WeaponMode = modes[current]
            set(ctx, player, "WeaponMode", state.WeaponMode)
            local damage = state.WeaponMode == "Spear" and 15 or state.WeaponMode == "Chain" and 12 or 10
            return hit(ctx, player, front(ctx, player, id == "Toji" and 11 or 9, 7, 7), damage, "ArsenalStrike", 0.4, 42)
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
            return pulse(ctx, player, 8, 9, "TodoClapShock", 0.35, 28)
        elseif id == "Hakari" then
            state.JackpotRoll = math.random(1,100)
            set(ctx, player, "JackpotRoll", state.JackpotRoll)
            if state.JackpotRoll >= 80 then
                state.Jackpot = true
                state.JackpotUntil = os.clock() + 14
                set(ctx, player, "Jackpot", true)
            end
            return hit(ctx, player, front(ctx, player, 9, 7, 7), state.Jackpot and 18 or 10, "JackpotRoll", 0.38, 34)
        elseif id == "Choso" then
            state.Blood = math.clamp((state.Blood or 0) + 24, 0, 100)
            set(ctx, player, "Blood", state.Blood)
            return pulse(ctx, player, 7, 11, "Supernova", 0.45, 42)
        elseif id == "Kashimo" then
            state.ElectricalCharge = math.clamp((state.ElectricalCharge or 0) + 32, 0, 100)
            set(ctx, player, "ElectricalCharge", state.ElectricalCharge)
            return pulse(ctx, player, 7, 9 + state.ElectricalCharge * 0.05, "ChargeBurst", 0.35, 34)
        elseif id == "Naoya" then
            local t = os.clock()
            if state.FrameWindowUntil < t or state.FrameSequence >= 24 then
                state.FrameSequence = 1
            else
                state.FrameSequence += 1
            end
            state.FrameWindowUntil = t + 0.7
            set(ctx, player, "FrameSequence", state.FrameSequence)
            local damage = 9 + state.FrameSequence * 0.35
            return hit(ctx, player, front(ctx, player, 12, 7, 7), damage, "FrameStep", 0.32, 38)
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
            return hit(ctx, player, front(ctx, player, 9, 7, 7), 12 + state.Evidence * 0.03, "EvidenceGavel", 0.42, 30)
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
            return hit(ctx, player, front(ctx, player, 18, 6, 7), 10 + state.OutputCharge * 0.05, "OutputCharge", 0.35, 46)
        elseif id == "Uro" then
            state.SkyDistortion = math.min(100, (state.SkyDistortion or 0) + 30)
            set(ctx, player, "SkyDistortion", state.SkyDistortion)
            return hit(ctx, player, front(ctx, player, 14, 8, 8), 11 + state.SkyDistortion * 0.05, "SkyDistortion", 0.38, 42)
        elseif id == "Kusakabe" then
            state.SimpleDomain = not state.SimpleDomain
            set(ctx, player, "SimpleDomain", state.SimpleDomain)
            return hit(ctx, player, front(ctx, player, 9, 7, 7), state.SimpleDomain and 15 or 10, "SimpleDomainSlash", 0.38, 38)
        end

        return false
    end

    function M.SkillSlot(player, ctx, slot)
        local move = CustomMovesets.GetMove(id, slot)
        if not move or slot < 3 then
            return false
        end

        local state = ctx.getState(player)
        announceMove(ctx, player, id, "Skill" .. tostring(slot), move.Name, 1.0)

        local function finish(success, radius)
            if success and ctx.environmentImpact and (move.Damage or 0) >= 20 then
                ctx.environmentImpact(root(ctx, player), math.clamp(radius or 6, 4, 12), move.Damage)
            end
            return success
        end

        if move.Type == "Melee" then
            local target = front(ctx, player, move.Range or 9, 8, 8)
            return finish(hit(ctx, player, target, move.Damage, move.Tag, move.Stun, move.Knockback), math.min((move.Range or 9) * 0.5, 8))
        elseif move.Type == "Projectile" then
            local target = front(ctx, player, move.Range or 24, 7, 8)
            local success = hit(ctx, player, target, move.Damage, move.Tag, move.Stun, move.Knockback)
            if success and target and target.root then
                local direction = target.root.Position - root(ctx, player)
                if direction.Magnitude > 0.01 then
                    target.root.AssemblyLinearVelocity = direction.Unit * math.max(18, move.Knockback or 36) + Vector3.new(0, 10, 0)
                end
            end
            return finish(success, math.min((move.Range or 24) * 0.28, 9))
        elseif move.Type == "Area" or move.Type == "Burst" then
            local radius = move.Radius or 12
            local damage = move.Damage
            if id == "Hakari" and state.Jackpot then
                damage += 5
            elseif id == "Choso" then
                damage += math.floor((state.Blood or 0) * 0.04)
            elseif id == "Kashimo" then
                damage += math.floor((state.ElectricalCharge or 0) * 0.05)
            elseif id == "Ryu" then
                damage += math.floor((state.OutputCharge or 0) * 0.08)
            end
            return finish(pulse(ctx, player, radius, damage, move.Tag, move.Stun, move.Knockback), radius * 0.7)
        elseif move.Type == "Control" then
            if id == "Todo" and move.Tag == "ClapSwap" then
                local targets = area(ctx, player, move.Range or 20)
                if #targets > 0 and targets[1].player then
                    state.SwapReady = not state.SwapReady
                    set(ctx, player, "SwapReady", state.SwapReady)
                    ctx.fx("TodoClap", root(ctx, player), state.SwapReady)
                    return true
                end
            end
            local target = move.Radius and randomTarget(ctx, player, move.Radius) or front(ctx, player, move.Range or 14, 9, 8)
            local success = hit(ctx, player, target, move.Damage, move.Tag, move.Stun, move.Knockback)
            if success and move.Pull and target and target.root then
                local delta = root(ctx, player) - target.root.Position
                if delta.Magnitude > 0.01 then
                    target.root.AssemblyLinearVelocity = delta.Unit * move.Pull + Vector3.new(0, 8, 0)
                end
            end
            return finish(success, move.Radius or 7)
        elseif move.Type == "Mobility" then
            local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.AssemblyLinearVelocity = rootPart.CFrame.LookVector * 58 + Vector3.new(0, 8, 0)
            end
            local target = front(ctx, player, move.Range or 11, 8, 8)
            return finish(hit(ctx, player, target, move.Damage, move.Tag, move.Stun, move.Knockback), 7)
        elseif move.Type == "Utility" then
            if move.Tag == "ClapSwap" then
                local targets = area(ctx, player, move.Range or 20)
                local target = targets[1]
                if target and target.player then
                    return swapPositions(player, target.player)
                end
            end
            return finish(hit(ctx, player, front(ctx, player, move.Range or 10, 7, 7), move.Damage, move.Tag, move.Stun, move.Knockback), 6)
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
            state.FrameWindowUntil = os.clock() + 2
            set(ctx, player, "FrameSequence", 24)
        elseif id == "Todo" then
            state.SwapReady = true
            set(ctx, player, "SwapReady", true)
        elseif id == "Kenjaku" then
            state.TechniqueStock = 4
            set(ctx, player, "TechniqueStock", 4)
        elseif id == "Jogo" then
            state.Heat = 100
            set(ctx, player, "Heat", 100)
        elseif id == "Dagon" then
            state.Tide = 100
            set(ctx, player, "Tide", 100)
        elseif id == "Hanami" then
            state.Roots = 100
            set(ctx, player, "Roots", 100)
        elseif id == "Higuruma" then
            state.Evidence = 100
            state.Confiscated = true
            set(ctx, player, "Evidence", 100)
            set(ctx, player, "Confiscated", true)
        elseif id == "Takaba" then
            state.ComedyContext = 100
            set(ctx, player, "ComedyContext", 100)
        elseif id == "Uraume" then
            state.Frost = 100
            set(ctx, player, "Frost", 100)
        elseif id == "Yorozu" then
            state.Construction = 100
            set(ctx, player, "Construction", 100)
        elseif id == "Ryu" then
            state.OutputCharge = 100
            set(ctx, player, "OutputCharge", 100)
        elseif id == "Uro" then
            state.SkyDistortion = 100
            set(ctx, player, "SkyDistortion", 100)
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
        local state = ctx.getState(player)
        local position = root(ctx, player)
        local damage = 44
        local radius = 16
        local knockback = 82
        local stun = 1.15
        if id == "Yuji" then damage, radius, knockback, stun = 50, 10, 104, 1.25
        elseif id == "Gojo" then damage, radius, knockback, stun = 56, 18, 118, 1.1
        elseif id == "Sukuna" then damage, radius, knockback, stun = 58, 20, 126, 1.2
        elseif id == "Megumi" then damage, radius, knockback, stun = 54, 18, 92, 1.25
        elseif id == "Yuta" then damage, radius, knockback, stun = 52, 18, 96, 1.15
        elseif id == "Maki" then damage, radius, knockback, stun = 52, 11, 110, 1.0
        elseif id == "Toji" then damage, radius, knockback, stun = 56, 12, 118, 1.05
        elseif id == "Mahito" then damage, radius, knockback, stun = 48, 16, 76, 1.35
        elseif id == "Todo" then damage, radius, knockback, stun = 46, 14, 88, 1.0
        elseif id == "Hakari" then damage, radius, knockback, stun = 56, 17, 100, 1.2
        elseif id == "Choso" then damage, radius, knockback, stun = 52, 18, 86, 1.15
        elseif id == "Kashimo" then damage, radius, knockback, stun = 58, 18, 122, 1.1
        elseif id == "Naoya" then damage, radius, knockback, stun = 50, 15, 112, 1.05
        elseif id == "Kenjaku" then damage, radius, knockback, stun = 54, 19, 92, 1.2
        elseif id == "Jogo" then damage, radius, knockback, stun = 60, 20, 118, 1.2
        elseif id == "Dagon" then damage, radius, knockback, stun = 54, 20, 96, 1.25
        elseif id == "Hanami" then damage, radius, knockback, stun = 50, 17, 84, 1.3
        elseif id == "Higuruma" then damage, radius, knockback, stun = 50, 15, 92, 1.3
        elseif id == "Takaba" then damage, radius, knockback, stun = 46, 16, 72, 1.15
        elseif id == "Uraume" then damage, radius, knockback, stun = 52, 18, 68, 1.45
        elseif id == "Yorozu" then damage, radius, knockback, stun = 56, 17, 104, 1.2
        elseif id == "Ryu" then damage, radius, knockback, stun = 62, 18, 130, 1.1
        elseif id == "Uro" then damage, radius, knockback, stun = 50, 16, 102, 1.15
        elseif id == "Kusakabe" then damage, radius, knockback, stun = 48, 12, 94, 1.05 end

        local success = false
        for _, target in ipairs(area(ctx, player, radius)) do
            local extra = 0
            if id == "Hakari" and state.Jackpot then extra = 12 end
            if id == "Choso" then extra = math.floor((state.Blood or 0) * 0.12) end
            if id == "Kashimo" then extra = math.floor((state.ElectricalCharge or 0) * 0.15) end
            if id == "Ryu" then extra = math.floor((state.OutputCharge or 0) * 0.18) end
            if hit(ctx, player, target, damage + extra, profile.OneTimeName, stun, knockback) then
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
        return success
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