--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Config = require(ReplicatedStorage.Shared.Config)
local CombatRules = require(ReplicatedStorage.Shared.CombatRules)
local ProgressionRules = require(ReplicatedStorage.Shared.ProgressionRules)

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(runtimeState, playerState, securityService, worldService, enemyService, remotes, pvpService)
    return setmetatable({
        runtimeState = runtimeState,
        playerState = playerState,
        securityService = securityService,
        worldService = worldService,
        enemyService = enemyService,
        remotes = remotes,
        pvpService = pvpService,
        connection = nil,
    }, CombatService)
end

function CombatService:Start()
    self.connection = self.remotes.Combat.OnServerEvent:Connect(function(player, request)
        self:HandleRequest(player, request)
    end)
end

function CombatService:HandleRequest(player: Player, request: any)
    if type(request) ~= "table" then
        self.securityService:RecordStrike(player)
        return
    end

    if request.action == "Attack" then
        self:HandleAttack(player)
    elseif request.action == "Dash" then
        self:HandleDash(player, request.direction)
    else
        self.securityService:RecordStrike(player)
    end
end

function CombatService:GetPowerLevel(player: Player)
    local state = self.playerState:Get(player)
    return state and state.powerLevel or 1
end

function CombatService:CalculateDamage(player: Player, combo: number)
    local damage = 12 + (self:GetPowerLevel(player) - 1) * 3
    damage *= CombatRules.comboMultiplier(combo)
    damage *= ProgressionRules.damageMultiplier(
        self.playerState:GetUpgradeLevel(player, "Damage")
    )

    local critical = math.random() < ProgressionRules.criticalChance(
        self.playerState:GetUpgradeLevel(player, "Critical")
    )

    if critical then
        damage *= 1.5
    end

    return damage, critical
end

function CombatService:AttackPVE(player: Player, root: BasePart, character: Model, damage: number, critical: boolean, combo: number)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.MaxParts = 64

    local hitCFrame = root.CFrame * CFrame.new(
        0,
        0,
        -(Config.Combat.HitboxSize.Z * 0.5 + 1)
    )

    local parts = workspace:GetPartBoundsInBox(
        hitCFrame,
        Config.Combat.HitboxSize,
        params
    )

    local seen = {}

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")

        if model and not seen[model] and model:GetAttribute("CBS_Enemy") == true then
            seen[model] = true

            local valid, humanoid, targetRoot = self.securityService:ValidateAttackTarget(
                player,
                model,
                root
            )

            if valid and humanoid and targetRoot then
                model:SetAttribute("CBS_LastHitUserId", player.UserId)
                humanoid:TakeDamage(damage)

                local direction = targetRoot.Position - root.Position
                if direction.Magnitude > 0.01 then
                    local resistance = tonumber(model:GetAttribute("CBS_KnockbackResistance")) or 0
                    local force = Config.Combat.KnockbackBase * (1 - math.clamp(resistance, 0, 0.9))
                    targetRoot.AssemblyLinearVelocity =
                        direction.Unit * force
                        + Vector3.new(0, Config.Combat.KnockbackVertical, 0)
                end

                self.remotes.FX:FireAllClients("Hit", {
                    position = targetRoot.Position,
                    combo = combo,
                    elite = model:GetAttribute("CBS_Elite") == true,
                    critical = critical,
                })
            end
        end
    end
end

function CombatService:AttackPVP(player: Player, root: BasePart, character: Model, damage: number, critical: boolean, combo: number)
    if not self.pvpService or not self.pvpService:IsParticipant(player) then
        return
    end

    if not self.pvpService:IsInsideZone(root.Position) then
        return
    end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.MaxParts = 64

    local hitCFrame = root.CFrame * CFrame.new(
        0,
        0,
        -(Config.Combat.HitboxSize.Z * 0.5 + 1)
    )

    local parts = workspace:GetPartBoundsInBox(
        hitCFrame,
        Config.Combat.HitboxSize,
        params
    )

    local seen = {}

    for _, part in ipairs(parts) do
        local targetCharacter = part:FindFirstAncestorOfClass("Model")

        if targetCharacter and not seen[targetCharacter] then
            seen[targetCharacter] = true

            local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)

            if targetPlayer and self.pvpService:IsParticipant(targetPlayer) then
                local valid, humanoid, targetRoot = self.securityService:ValidatePvPTarget(
                    player,
                    targetPlayer,
                    root
                )

                if valid and humanoid and targetRoot and self.pvpService:IsInsideZone(targetRoot.Position) then
                    targetPlayer:SetAttribute("CBS_LastPvPKillerUserId", player.UserId)
                    humanoid:TakeDamage(damage)

                    local direction = targetRoot.Position - root.Position
                    if direction.Magnitude > 0.01 then
                        targetRoot.AssemblyLinearVelocity =
                            direction.Unit * Config.Combat.KnockbackBase
                            + Vector3.new(0, Config.Combat.KnockbackVertical, 0)
                    end

                    self.remotes.FX:FireAllClients("PvPHit", {
                        attackerUserId = player.UserId,
                        targetUserId = targetPlayer.UserId,
                        position = targetRoot.Position,
                        combo = combo,
                        critical = critical,
                    })
                end
            end
        end
    end
end

function CombatService:HandleAttack(player: Player)
    local valid, character, root = self.securityService:IsAliveCharacter(player)
    if not valid or not root or not character then
        return
    end

    local inPvP = player:GetAttribute("CBS_PvP") == true

    if inPvP then
        if not self.pvpService or not self.pvpService:IsParticipant(player) then
            return
        end
    elseif not self.securityService:IsInsideArena(root) then
        return
    end

    local combo = self.playerState:MarkAttack(player, os.clock())
    if not combo then
        return
    end

    local damage, critical = self:CalculateDamage(player, combo)

    if inPvP then
        self:AttackPVP(player, root, character, damage, critical, combo)
    else
        self:AttackPVE(player, root, character, damage, critical, combo)
    end

    self.remotes.FX:FireClient(player, "Attack", {
        combo = combo,
        critical = critical,
        pvp = inPvP,
    })
end

function CombatService:HandleDash(player: Player, requestedDirection: any)
    local valid, character, root = self.securityService:IsAliveCharacter(player)
    if not valid or not root then
        return
    end

    local inPvP = player:GetAttribute("CBS_PvP") == true

    if inPvP then
        if not self.pvpService or not self.pvpService:IsParticipant(player) or not self.pvpService:IsInsideZone(root.Position) then
            return
        end
    elseif not self.securityService:IsInsideArena(root) then
        return
    end

    local direction = self.securityService:NormalizeDashDirection(requestedDirection)
    if not direction then
        self.securityService:RecordStrike(player)
        return
    end

    if not self.playerState:CanDash(player, os.clock()) then
        return
    end

    local centerDistance = inPvP
        and math.abs(root.Position.X)
        or Vector2.new(root.Position.X, root.Position.Z).Magnitude

    local available = inPvP
        and math.max(0, 70 - centerDistance)
        or math.max(0, Constants.ArenaRadius - 6 - centerDistance)

    local distance = math.min(Config.Combat.DashDistance, available)

    if distance <= 0.5 then
        return
    end

    local velocity = direction * (distance / Config.Combat.DashDuration)
    local previousVelocity = root.AssemblyLinearVelocity

    root.AssemblyLinearVelocity = Vector3.new(
        velocity.X,
        math.clamp(previousVelocity.Y, -20, 20),
        velocity.Z
    )

    self.remotes.FX:FireAllClients("Dash", {
        userId = player.UserId,
        position = root.Position,
        direction = direction,
        pvp = inPvP,
    })

    task.delay(Config.Combat.DashDuration, function()
        if root.Parent and character.Parent then
            local current = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(
                current.X * 0.15,
                current.Y,
                current.Z * 0.15
            )
        end
    end)
end

function CombatService:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

return CombatService
